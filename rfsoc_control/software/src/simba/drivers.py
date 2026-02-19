from time import time

import numpy as np
from pynq import DefaultIP


class LockinController(DefaultIP):
    bindto = ["user.org:user:controller_lockin:1.0"]

    def info(self):
        print(f"Frequency     : {self.frequency}")
        print(f"Phase         : {self.phase}")
        print(f"Filter Active : {self.num_tlast}")
        print(f"Dec_factor    : {self.dec_factor}")
        print(f"Data_lost     : {self.data_lost}")
        print(f"Test_reg      : {self.test_reg}")

    @property
    def frequency(self):
        return self.read(0)

    @frequency.setter
    def frequency(self, value):
        self.write(0, value)

    @property
    def phase(self):
        return self.read(4)

    @phase.setter
    def phase(self, value):
        self.write(4, value)

    @property
    def num_tlast(self):
        return self.read(8)

    @num_tlast.setter
    def num_tlast(self, value):
        self.write(8, value)

    @property
    def dec_factor(self):
        return self.read(12)

    @dec_factor.setter
    def dec_factor(self, value):
        self.write(12, value)

    @property
    def data_lost(self):
        return self.read(16)

    @property
    def test_reg(self):
        return self.read(20)


class GlobalController(DefaultIP):
    bindto = ["user.org:user:global_axi_control:1.2"]

    def status(self):
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
        self.write(0, 0)
        sync.write(12, 0)

    def reset(self, sync):
        self.write(0, 1)
        sync.write(12, 0)

    def config(self):
        self.write(0, 2)

    def start(self, sync, wait_for_pps=False):
        delay = 18924 / 122.88e6  # having FIRs at 18750

        self.write(0, 4)
        if wait_for_pps is False:
            t0 = time()
            sync.write(12, 1)
            return t0 - delay

        t0 = time()
        while t0 % 1 < 0.3:
            t0 = time()
        t0 = np.ceil(time())
        n_pps = sync.read(4)
        sync.write(0, n_pps + 1)
        diff = sync.read(4 * 2)
        return t0 + diff - delay
