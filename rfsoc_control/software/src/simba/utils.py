import re
import time

import numpy as np
import xrfclk
import xrfdc
from pynq import Overlay, allocate
from simba.drivers import *

FS = 122.88e6


def load_overlay():
    ov = Overlay("/home/xilinx/firmware/lockin.bit")
    lockins = [
        getattr(ov, attr)
        for attr in dir(ov)
        if re.fullmatch(r"lockin_instance_\d+", attr)
    ]
    controller = ov.global_axi_control
    sync = ov.sync_start
    return ov, controller, lockins, sync


def start_clocks(lmk_freq=245.76, lmx_freq=491.52, ext_clk=False):
    xrfclk.xrfclk._find_devices()
    xrfclk.xrfclk._read_tics_output()
    if ext_clk:
        xrfclk.xrfclk._Config["lmk04828"][lmk_freq][
            80
        ] = 0x01470A  # select external ref for LMK
    xrfclk.set_ref_clks(lmk_freq=lmk_freq, lmx_freq=lmx_freq)


def configure_lockin(lockin, frequency, phase, dec_factor, fir_dec):
    if not (1e3 < frequency < 100e6):
        raise ValueError("Frequency out of range")
    if not (0 < dec_factor < 16777216):
        raise ValueError("DecFactor out of range")
    fir_mappings = {
        2: 2**1 - 1,
        6: 2**2 - 1,
        30: 2**3 - 1,
        150: 2**4 - 1,
        750: 2**5 - 1,
        3750: 2**6 - 1,
        18750: 2**7 - 1,
        468750: 2**8 - 1,
    }
    if fir_dec not in fir_mappings:
        raise ValueError("Fir decimation not natively supported")

    lockin.axi_control.frequency = int(frequency * (2**32 - 1) / FS)
    lockin.axi_control.phase = int(phase * (2**32 - 1) / (2 * np.pi))
    lockin.axi_control.dec_factor = int(dec_factor)
    # this is not the tlast, but the filter active
    lockin.axi_control.num_tlast = int(fir_mappings[fir_dec])


def acquire(controller, lockin, num_packets):
    tot_i = []
    tot_q = []

    i_buffer = allocate(shape=(256,), dtype=np.int32)
    q_buffer = allocate(shape=(256,), dtype=np.int32)

    times = []

    controller.start()
    start_time = time.time()

    for count in range(num_packets):
        t0 = time.time()

        dma_i = lockin.dma_I.recvchannel
        dma_q = lockin.dma_Q.recvchannel

        dma_i.transfer(i_buffer)
        dma_q.transfer(q_buffer)

        dma_i.wait()
        dma_q.wait()

        times.append(time.time() - t0)

        tot_i += list(i_buffer)
        tot_q += list(q_buffer)

    del i_buffer
    del q_buffer

    controller.stop()
    controller.reset()
    time.sleep(1)
    controller.stop()

    print(f"Mean detected out rate: {256 / np.mean(times)} SPS")
    print(f"Acquired for {time.time() - start_time} seconds")

    return tot_i, tot_q
