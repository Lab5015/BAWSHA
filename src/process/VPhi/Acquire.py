import sys
sys.path.insert(0, "/home/bausciadaq/BAWSHA/src/instruments/")
from TBS2000B import TBS2000B  # now Python can find it
import time
import h5py
import numpy as np
from datetime import datetime
path = "/home/bausciadaq/Run8/squids/calibration/"
filename = path + "CH1_cali_600mK_preliminary.h5"

scope = TBS2000B()
desired_rate = int(1e6)
record_length = int(2e5)
navg=32
with h5py.File(filename, "a") as f:
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    groupname = timestamp
    print(scope.query("HOR:RECO?"))
    print(scope.query("WFMOutpre:NR_Pt?"))
    print("Acquiring data...")
    scope.set_vertical_scale(1, 0.2)
    scope.set_vertical_scale(2, 0.05)

    result = scope.acquire_averaged_curve(navg, desired_rate, record_length)
    try:
        grp = f.create_group(groupname)
        grp.create_dataset("Time", data=np.array(result["time"]))
        grp.create_dataset("Flux", data=np.array(result["CH1"]))
        grp.create_dataset("Volt", data=np.array(result["CH2"]))
    except:
        print("Something went wrong with Vphi fit...continue")
        pass
    
print("Acquisition Ended!")
del scope
