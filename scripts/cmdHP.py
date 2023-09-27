#!/usr/bin/env python

import IPython
from instruments import hp8753e
import matplotlib.pyplot as plt
import numpy as np

def main():
    VNA = hp8753e.HP8753E()
    #VNA = hp8753e.VNAHandler()

    print("VNA object created!")

    VNA.set_power(-30)
    VNA.set_center(5174189)
#    VNA.set_center(5167987)
    VNA.set_span(200)
    VNA.set_IFBW(30)
    VNA.set_point(1601)
    VNA.set_mode('S11')

    IPython.embed()
    return
    

if __name__ == "__main__":
    main()
