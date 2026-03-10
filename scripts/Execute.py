from DPO3014 import DPO3014
from VPhi import fitter
import subprocess
import time

INTERVAL = 60      # 10 seconds sleep time
TOTAL_TIME = 8*3600   # 6 hours
dp = r"/home/cmsdaq/TexDPO3014/vphi_vs_time"
start = time.time()

tek = DPO3014()
tek.write("HORizontal:SCAle 1E-2")
tek.RL = 10000
tek.set_average_mode()
tek.write("ACQuire:NUMAVg 512")

while (time.time() - start) < TOTAL_TIME:
    print("Acquiring data...")
    result = tek.acquire(sleep=60)
    print("Fitting data...")
    fitfit = fitter(result["time"], result["CH1"], result["CH2"], dp)
    try:
        fitfit.analyze_vphi(plot=False)
    except:
        print("Something went wrong with Vphi fit...continue")
        pass
    print("zzz...")
    
    time.sleep(INTERVAL)
    
print("Acquisition Ended!")
print("Start time", start)
del tek
