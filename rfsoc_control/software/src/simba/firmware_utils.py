"""
Utilities for interacting with RFSoC firmware components.

This module wraps low level interactions with the FPGA overlay,
clock generators and lock-in IP blocks.
"""

import re
import logging
from time import monotonic, sleep

import numpy as np
import xrfclk
import xrfdc
from pynq import Overlay, allocate
from drivers import *

FS = 122.88e6

CLOCK_SETTLE_S = 2.0  # wait after programming LMK/LMX before loading the bitstream
TILE_STARTUP_TIMEOUT_S = 10.0
SELF_TEST_TIMEOUT_S = 10.0  # one 256-sample transfer lasts about 1 s
RETRY_PAUSE_S = 5.0
TILE_STATE_UP = 15
PLL_LOCKED = 1


class HardwareStartupError(RuntimeError):
    """The firmware could not be brought to a working state."""


def load_overlay(verbose=False):
    """
    Load the FPGA overlay and retrieve references to hardware blocks.

    Returns
    -------
    tuple
        overlay : pynq.Overlay
        controller : GlobalController
        lockins : list
            Flat list of LockinController (axi_control) drivers, ordered by
            traversal (adc, group, lockin_in_group), each numerically sorted.
            Position in this list encodes the physical (adc, group) location
            and must stay stable for lo_config/client/analysis compatibility.
        sync : hardware synchronization block
        dma_groups : list
            List of S2MM recvchannel DMA objects, one per group of lock-ins.
            dma_groups[i] serves lockins[group_size*i : group_size*(i+1)].
    """
    ov = Overlay("/home/xilinx/firmware/lockin.bit", download=True)

    adc_names = sorted(
        (attr for attr in dir(ov) if re.fullmatch(r"adc_\d+_\d+", attr)),
        key=lambda s: tuple(int(x) for x in s.split("_")[1:]),
    )

    lockins = []
    dma_groups = []
    for adc_name in adc_names:
        adc = getattr(ov, adc_name)
        group_names = sorted(
            (attr for attr in dir(adc) if re.fullmatch(r"group_\d+", attr)),
            key=lambda s: int(s.rsplit("_", 1)[1]),
        )
        for group_name in group_names:
            group = getattr(adc, group_name)
            dma_groups.append(group.dma.recvchannel)

            axi_names = sorted(
                (attr for attr in dir(group) if re.fullmatch(r"axi_control_\d+", attr)),
                key=lambda s: int(s.rsplit("_", 1)[1]),
            )
            for axi_name in axi_names:
                lockins.append(getattr(group, axi_name))

    if verbose:
        group_size = len(lockins) // len(dma_groups) if dma_groups else 0
        logging.info(
            f"[HW] Loaded firmware with {len(lockins)} lockins "
            f"in {len(dma_groups)} groups of {group_size}"
        )

    controller = ov.global_axi_control
    sync = ov.sync_start
    return ov, controller, lockins, sync, dma_groups


def start_clocks(lmk_freq=245.76, lmx_freq=491.52, ext_clk=False):
    """
    Configure RFSoC clock generators.

    Parameters
    ----------
    lmk_freq : float
        LMK reference frequency in MHz.
    lmx_freq : float
        LMX PLL frequency in MHz.
    ext_clk : bool
        If True, use external reference clock.
    """

    xrfclk.xrfclk._find_devices()
    xrfclk.xrfclk._read_tics_output()

    if ext_clk:
        xrfclk.xrfclk._Config["lmk04828"][lmk_freq][80] = 0x01470A

    xrfclk.set_ref_clks(lmk_freq=lmk_freq, lmx_freq=lmx_freq)


def rfdc_problems(ov):
    """
    Check that every enabled ADC tile is powered up with its PLL locked.

    Returns
    -------
    list of str
        One line per problem, empty if all tiles are fine. If the status
        cannot be read with this xrfdc version the check is skipped (with a
        warning) and the DMA self test remains the only verification.
    """
    try:
        tiles = ov.rfdc.IPStatus["ADCTileStatus"]
        problems = []
        for idx, tile in enumerate(tiles):
            if not tile["IsEnabled"]:
                continue
            if tile["TileState"] != TILE_STATE_UP or tile["PLLState"] != PLL_LOCKED:
                problems.append(
                    f"ADC tile {idx}: state {tile['TileState']} "
                    f"(want {TILE_STATE_UP}), PLL {tile['PLLState']} (want {PLL_LOCKED})"
                )
        return problems
    except Exception as e:
        logging.warning(f"[HW] RFDC status not readable, check skipped: {e}")
        return []


def wait_dma(dmas, timeout):
    """
    Wait for all DMA transfers, raising instead of blocking forever.

    pynq's dma.wait() never returns if no data arrives (dead clock, stopped
    stream). Poll first, then call dma.wait() which returns at once and does
    the error decoding and the cache invalidation of the buffer.
    """
    deadline = monotonic() + timeout
    for idx, dma in enumerate(dmas):
        while not (dma.idle or dma.error):
            if monotonic() > deadline:
                raise TimeoutError(f"DMA of group {idx}: no data within {timeout} s")
            sleep(0.002)
        dma.wait()


def self_test(controller, lockins, sync, dma_groups):
    """
    Run one short acquisition on every group and check that data arrives.

    This exercises the whole chain (ADC clock, MMCM, lock-ins, FIFOs, DMA),
    which is what actually fails when the board comes up badly.
    """
    group_size = len(lockins) // len(dma_groups)
    for lockin in lockins:
        configure_lockin(lockin, frequency=1e6, phase=0, dec_factor=1, fir_dec=468750)

    bufs = [allocate(256 * group_size, np.uint64) for _ in dma_groups]
    try:
        controller.reset(sync)
        controller.config()
        controller.start(sync, wait_for_pps=False)
        for dma, buf in zip(dma_groups, bufs):
            dma.transfer(buf)
        wait_dma(dma_groups, SELF_TEST_TIMEOUT_S)
        for idx, buf in enumerate(bufs):
            if not np.any(buf):
                logging.warning(f"[HW] self test: group {idx} delivered only zeros")
    finally:
        try:
            controller.reset(sync)
        except Exception as e:
            logging.warning(f"[HW] self test: controller reset failed: {e}")
        for buf in bufs:
            buf.freebuffer()


def bring_up(ext_clk=False, max_attempts=5, verbose=False):
    """
    Program the clocks, load the bitstream and verify that the firmware works.

    The 122.88 MHz fabric clock is derived from the ADC tile clock, so the
    LMK/LMX references must be running before the bitstream is loaded. Each
    attempt does: clocks -> bitstream -> RFDC tile check -> DMA self test.
    A failed attempt is repeated from the start.

    Returns
    -------
    tuple
        Same as load_overlay().

    Raises
    ------
    HardwareStartupError
        If no attempt succeeds.
    """
    last_error = None
    for attempt in range(1, max_attempts + 1):
        try:
            start_clocks(ext_clk=ext_clk)
            sleep(CLOCK_SETTLE_S)

            hw = load_overlay(verbose=verbose)
            ov, controller, lockins, sync, dma_groups = hw

            deadline = monotonic() + TILE_STARTUP_TIMEOUT_S
            problems = rfdc_problems(ov)
            while problems and monotonic() < deadline:
                sleep(0.5)
                problems = rfdc_problems(ov)
            if problems:
                raise HardwareStartupError("; ".join(problems))

            self_test(controller, lockins, sync, dma_groups)
            logging.info(f"[HW] Bring-up OK at attempt {attempt}/{max_attempts}")
            return hw
        except Exception as e:
            last_error = e
            logging.error(f"[HW] Bring-up attempt {attempt}/{max_attempts} failed: {e}")
            sleep(RETRY_PAUSE_S)

    hint = " (is the external reference clock connected?)" if ext_clk else ""
    raise HardwareStartupError(
        f"firmware not working after {max_attempts} attempts{hint}: {last_error}"
    )


def configure_lockin(lockin, frequency, phase, dec_factor, fir_dec):
    """
    Configure a single lock-in firmware block.

    Parameters
    ----------
    lockin : LockinController
        Hardware lock-in instance.
    frequency : float
        Local oscillator frequency in Hz.
    phase : float
        Phase offset in radians.
    dec_factor : int
        CIC decimation factor.
    fir_dec : int
        FIR decimation factor.
    """

    if not (1e3 < frequency < 100e6):
        raise ValueError("Frequency out of range")

    if not (0 < dec_factor < 16777216):
        raise ValueError("DecFactor out of range")

    fir_mappings = {
        18750: 2**7 - 1,
        468750: 2**8 - 1,
    }

    if fir_dec not in fir_mappings:
        raise ValueError("FIR decimation not supported")

    lockin.frequency = int(frequency * (2**32 - 1) / FS)
    lockin.phase = int(phase * (2**32 - 1) / (2 * np.pi))
    lockin.dec_factor = int(dec_factor)
    lockin.num_tlast = int(fir_mappings[fir_dec])


def read_counters(overlay):
    """
    Read hardware packet counters from the FPGA.

    Parameters
    ----------
    overlay : pynq.Overlay

    Returns
    -------
    numpy.ndarray
        Array of 64-bit counters for each acquisition channel.
    """

    counters_ip = overlay.counters

    n_chan = 32
    counters = np.zeros(n_chan, dtype=np.uint64)

    for i in range(n_chan):

        base = i * 8

        reg_h = base
        reg_l = base + 4

        low = int(counters_ip.read(reg_l))
        high = int(counters_ip.read(reg_h))

        counters[i] = np.uint64((high << 32) | low)

    return counters
