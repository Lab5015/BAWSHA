import sys
sys.path.insert(0, "/home/bausciadaq/BAWSHA/src/instruments/")
from TBS2000B import TBS2000B  # now Python can find it
import time
import h5py
import numpy as np
from datetime import datetime

ch = 3
path = "/home/bausciadaq/Run7/MisuradiM/definitive/"
filename = path + "MisuradiM_10Vpp_1Hz.h5"

if (ch != 3) and (ch != 4):
    scope = TBS2000B()
    desired_rate = int(125e6)
    record_length = int(2e5)
    navg=512
    with h5py.File(filename, "a") as f:
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        groupname = "CH" + str(ch)
        print(scope.query("HOR:RECO?"))
        #print(scope.query("WFMOutpre:NR_Pt?"))
        print("Acquiring data...")
        if ch==1:
            scale=0.05
        if ch==2:
            scale=0.02
        scope.set_vertical_scale(ch, scale)

        result = scope.acquire_averaged_curve_singlechan(navg, desired_rate, record_length, ch=ch, triggerch=ch, triggervalue=0.02)
        try:
            grp = f.create_group(groupname)
            grp.create_dataset("Time", data=np.array(result["time"]))
            grp.create_dataset("Vout", data=np.array(result["CH" + str(ch) + "_wide"]))
        except:
            print("Something went wrong with Vphi fit...continue")
            pass
        
    print("Acquisition Ended!")
    del scope
else:
    scope = TBS2000B()
    desired_rate = int(125e3)
    record_length = int(2e5)
    navg=32  
    scope.set_vertical_scale(ch, 0.001)
    if ch == 4:
        navg = 64
        scope.set_vertical_scale(ch, 0.1)
    with h5py.File(filename, "a") as f:
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        groupname = "CH" + str(ch)  + "_wide"
        print(scope.query("HOR:RECO?"))
        #print(scope.query("WFMOutpre:NR_Pt?"))


        result = scope.acquire_averaged_curve_singlechan(navg, desired_rate, record_length, ch=ch, triggerch=4, triggervalue=0.02)
        try:
            grp = f.create_group(groupname)
            grp.create_dataset("Time", data=np.array(result["time"]))
            grp.create_dataset("Vout", data=np.array(result["CH" + str(ch)]))
        except:
            print("Something went wrong with Vphi fit...continue")
            pass
        
    print("Acquisition Ended!")
    del scope