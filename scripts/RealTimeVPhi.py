"""
This script uses
    - instruments/DPO3014.py to talk with the oscilloscope and retrieve data
    - VPhi.py to compute VPhi and print fit results
"""

import sys
import re
import numpy as np
sys.path.append(r"../src/instruments/DPO3014")
from DPO3014 import DPO3014
from VPhi import analyze_vphi

#-------------------------------------------------
# Initialize oscilloscope
#-------------------------------------------------

mytek = DPO3014()
mytek.HS = 0.004
mytek.RL = 2e4
mytek.set_average_mode()
mytek.AVG = 512

#-------------------------------------------------
# Retrieve Transformed Data
#-------------------------------------------------

time, CH1, CH2 = mytek.acquire()

#-------------------------------------------------
# Run VPhi analysis
#-------------------------------------------------

A, A_err, B, B_err = analyze_vphi(time, CH1, CH2, plot=True)

print("\nFit results")
print(f"A = {A:.4} ± {A_err:.4}")
print(f"B = {B:.4} ± {B_err:.4}")