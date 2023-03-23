import IPython
import agilent4395A
import numpy as np
import matplotlib.pyplot as plt

VNA = agilent4395A.Agilent4395A()
print("VNA object created!")


# test
#VNA.set_save_path('test')
#VNA.routine(center_start=5.17e6, center_stop=5.19e6, span_large=10e3, IFBW_large=300, power=-30, npt=801, span_zoom=200, IFBW_zoom=30, savePlot=True)

# wide scan
VNA.set_save_path('/home/cmsdaq/Desktop/ImpedenceAnalyzer/BAW_27/Scan_28_02_2023/')
VNA.routine(center_start=1.5e6, center_stop=14e6, span_large=10e3, IFBW_large=300, power=-20, npt=801, span_zoom=100, IFBW_zoom=30, thr_freq=1000, n_std=5, savePlot=True)


IPython.embed()
