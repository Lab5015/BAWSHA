from DPO3014 import DPO3014
from VPhi import fitter
import subprocess
import time

INTERVAL = 10      # 10 seconds sleep time
TOTAL_TIME = 6*3600   # 6 hours
dp = r"/home/cmsdaq/TexDPO3014/vphi_vs_time"
start = time.time()

tek = DPO3014()
while (time.time() - start) < TOTAL_TIME:
    tek.write("HORizontal:SCAle 1E-2")
    tek.RL = 10000
    tek.set_average_mode()
    tek.write("ACQuire:NUMAVg 512")
    print("Acquiring data...")
    while(True):
        try:
            result = tek.acquire()    
            break
        except:
            print("Something went wrong with retrieval...trying again")
            time.sleep(2)
    print("Fitting data...")
    fitfit = fitter(result["time"], result["CH1"], result["CH2"], dp)
    fitfit.analyze_vphi(plot=False)
    print("zzz...")
    
    time.sleep(INTERVAL)
    
print("Acquisition Ended!")
del tek