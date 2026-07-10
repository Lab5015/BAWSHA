"""
Utilities for interacting with RFSoC firmware components.

This module wraps low level interactions with the FPGA overlay,
clock generators and lock-in IP blocks.
"""

import re
import logging

import numpy as np
import xrfclk
import xrfdc
from pynq import Overlay
from drivers import *

FS = 122.88e6


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
