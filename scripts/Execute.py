from DPO3014 import DPO3014
from VPhi import fitter
import subprocess
import time
import h5py
import numpy as np
from datetime import datetime

INTERVAL = 4*60      # 4 minutes sleep time
TOTAL_TIME = 10*3600   # 10 hours
start = time.time()
filename = "Test.hdf5"

tek = DPO3014()
tek.write("HORizontal:SCAle 1E-2")
tek.RL = 10000
tek.set_average_mode()
tek.write("ACQuire:NUMAVg 512")

with h5py.File(filename, "a") as f:
    while (time.time() - start) < TOTAL_TIME:
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        groupname = timestamp
        print("Acquiring data...")
        result = tek.acquire(sleep=60)
        print("Fitting data...")
        fitfit = fitter(result["time"], result["CH1"], result["CH2"])
        try:
            #fitfit.analyze_vphi(plot=False)
            fitfit.analyze_vphi_fix()
            grp = f.create_group(groupname)
            grp.create_dataset("Time", data=np.array(result["time"]), compression="gzip")
            grp.create_dataset("Flux", data=np.array(result["CH1"]), compression="gzip")
            grp.create_dataset("Volt", data=np.array(result["CH2"]), compression="gzip")
            grp.create_dataset("Results", data=np.array(fitfit.results), compression="gzip")
            grp.create_dataset("Plot", data=fitfit.plotter(), compression="gzip")
            grp.create_dataset("Best_pts", data=fitfit.best_pts, compression="gzip")
        except:
            print("Something went wrong with Vphi fit...continue")
            pass
        print("zzz...")
        time.sleep(INTERVAL)
        
print("Acquisition Ended!")
print("Start time", start)
del tek
