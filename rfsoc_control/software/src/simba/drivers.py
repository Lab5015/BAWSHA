"""PYNQ drivers."""

from time import sleep, time

import logging
import numpy as np
from pynq import DefaultIP


class LockinController(DefaultIP):
    """Lockin_wrapper controller driver."""

    bindto = ["user.org:user:controller_lockin:1.0"]

    def info(self):
        """Log info read from lockin AXI registers."""
        logging.info(f"Frequency     : {self.frequency}")
        logging.info(f"Phase         : {self.phase}")
        logging.info(f"Filter Active : {self.num_tlast}")
        logging.info(f"Dec_factor    : {self.dec_factor}")
        logging.info(f"Data_lost     : {self.data_lost}")
        logging.info(f"Test_reg      : {self.test_reg}")

    @property
    def frequency(self):
        """Frequency of the lockin downconversion (in integer)."""
        return self.read(0)

    @frequency.setter
    def frequency(self, value):
        self.write(0, value)

    @property
    def phase(self):
        """Phase of the lockin downconversion (in integer)."""
        return self.read(4)

    @phase.setter
    def phase(self, value):
        self.write(4, value)

    @property
    def num_tlast(self):
        """Activation indexes to change active filters. Currently not really supported."""
        return self.read(8)

    @num_tlast.setter
    def num_tlast(self, value):
        self.write(8, value)

    @property
    def dec_factor(self):
        """Final decimation factor post filtering."""
        return self.read(12)

    @dec_factor.setter
    def dec_factor(self, value):
        self.write(12, value)

    @property
    def data_lost(self):
        """Number of lost samples. Currently hard-fixed at zero."""
        return self.read(16)

    @property
    def test_reg(self):
        """Test register, connected to output_I lockin (32 bit)."""
        return self.read(20)


class GlobalController(DefaultIP):
    """Global axi controller driver (run-config-reset)."""

    bindto = ["user.org:user:global_axi_control:1.2"]

    def status(self):
        """Read status."""
        val = self.read(0)

        if val == 0:
            return "Idle"
        if val == 1:
            return "Reset"
        if val == 2:
            return "Config"
        if val == 4:
            return "Start"

        return f"Status: {val}"

    def stop(self, sync):
        """Output resetn."""
        self.write(0, 0)
        sync.write(12, 0)
        sleep(0.2)

    def reset(self, sync):
        """Output reset."""
        self.write(0, 1)
        sync.write(12, 0)
        sleep(0.2)

    def config(self):
        """Output config."""
        self.write(0, 2)
        sleep(0.2)

    def start(self, sync, wait_for_pps=False):
        """Output run, synced to exteral pps rising edge."""
        delay = 375024 / 122.88e6

        self.write(0, 4)
        if wait_for_pps is False:
            t0 = time()
            sync.write(12, 1)
            return t0 - delay

        while True:
            t0 = time()
            logging.info(f"[HW] Time is {t0}")
            while t0 % 1 > 0.3:
                t0 = time()
                logging.info(f"[HW] While time is {t0}")
                sleep(0.05)
            t0 = np.ceil(time())
            n_pps = sync.read(4)
            logging.info(f"[HW] Read npps {n_pps}")
            sync.write(0, n_pps + 1)
            diff = sync.read(4 * 2)
            logging.info(f"[HW] Read diff {diff}")

            if np.ceil(time() - t0) == 0:
                break
            logging.info("[HW] A second passed, restarting")
            self.reset(sync)
            self.config()

        return t0 + diff - delay
