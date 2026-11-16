import sys
import matplotlib
#matplotlib.use("TkAgg")
import matplotlib.pyplot as plt

from instruments import TBS2000B
from scipy.signal import find_peaks

import time
import h5py
import numpy as np
from datetime import datetime
import argparse

#path = "/home/bausciadaq/data/runs/Run10/squids/calibration/"
#filename = path + "CH2_cali_100mK.h5"

def find_vphi(time,volt,ramp,thr1=50,npt=15,plot=True):
    # select only the data on ONE rising edge
    pmax = np.argmax(ramp)
    ii = np.where(ramp>= 0.8*ramp[pmax])[0]
    if (np.diff(ii) <= thr1).all() == True:
        pmin = np.argmin(ramp)
    else:
        pcut = ii[np.where(np.diff(ii)>=thr1)[0][-1]]+1
        pmin = pcut+np.argmin(ramp[pcut:pmax])
    time = time[pmin:pmax]
    volt = volt[pmin:pmax]
    
    #calibrate, i.e. time --> flux
    peaks, _ = find_peaks(volt,height=np.max(volt)*0.9,distance=int(len(volt)*0.10))

    m = (1-0)/(time[peaks][1]-time[peaks][0])
    q = 0-m*time[peaks][0]
    flux = time*m+q

    #fit around the intersection with zero on the rising edge
    m = (1-0)/(time[peaks][1]-time[peaks][0])
    q = 0-m*time[peaks][0]
    flux = time*m+q
    pstart = np.where((flux>=0.5)&(volt>=0))[0][0]
    npt_u = npt
    npt_d = npt
    xfit = flux[pstart-npt_d:pstart+npt_u]
    yfit = volt[pstart-npt_d:pstart+npt_u]
    par = np.polyfit(x=xfit,y=yfit,deg=1)
    xx = np.linspace(flux[pstart-npt_d-5],flux[pstart+npt_u+5],100)
    yy = np.poly1d(par)(xx)
    VPHI = np.round(par[0],2) 
    if plot == True:
        plt.plot(flux,volt,"o",ms=1,c="k")
        plt.plot(xfit,yfit,"o",ms=2,c="magenta")    
        plt.axhline(0,ls="--",color="grey",alpha=0.6)
        plt.plot(xx,yy,c="r",ls="--",lw=2,label=r"$V_{\Phi} \sim $"+str(VPHI) +" (V/$\Phi_0$)")
        plt.legend()
        plt.xlabel("$\Phi$ ($\Phi_0$)")
        plt.ylabel("V")
        plt.tight_layout()
        plt.show()
    return VPHI
    
def main():
    usage='\n acquireVphi.py -fpath /path/to/save/the/file/ -name file_name.h5 \n' \
          ' acquireVphi.py -fpath /path/of/the/file/ -name file_name.h5 -evaluate 1 [-npt 15] \n'
    parser = argparse.ArgumentParser(description='Acquire a V-Phi snapshot from the TBS2000B oscilloscope (CH1: flux ramp, CH2: SQUID voltage) and save it in a .h5 file. With -evaluate 1, read the file and evaluate VPhi instead', usage=usage)
    
    parser.add_argument("-fpath", "--fpath"   , dest="fpath"   , type=str , help="path to save the file. e.g /home/bausciadaq/data/runs/Run10/squids/calibration/", default = "", required = True)    
    parser.add_argument("-name", "--name"   , dest="name"   , type=str , help="file name. e.g. CH2_cali_100mK.h5", default = None, required = True)    
    parser.add_argument("-evaluate", "--evaluate"   , dest="eval"   , type=int , help="if 1, evaluate VPhi from the file instead of acquiring a new snapshot", default = 0, required = False)    
    parser.add_argument("-npt", "--npt"   , dest="npt"   , type=int , help="number of points on each side of the zero crossing used for the VPhi linear fit", default = 15, required = False)
    
    args = parser.parse_args()    

    path = args.fpath
    if path.endswith("/") == False:
        path += "/"
    filename = path + args.name
    
    if args.eval == 1:
        with h5py.File(filename, "r") as f:
            k0 = list(f.keys())[0]
            time = np.array(f[k0+"/Time"])
            volt = np.array(f[k0+"/Volt"])
            ramp = np.array(f[k0+"/Flux"])
        VPHI = find_vphi(time,volt,ramp,thr1=50,npt=args.npt,plot=True)
        print("VPhi = ",VPHI)
        return 
    
    scope = TBS2000B.TBS2000B()
    with h5py.File(filename, "a") as f:
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        groupname = timestamp
        print("Acquiring snapshot...")
        result = scope.capture_screen()

        try:
            grp = f.create_group(groupname)
            grp.create_dataset("Time", data=np.array(result["time"]))
            grp.create_dataset("Flux", data=np.array(result["CH1"]))
            grp.create_dataset("Volt", data=np.array(result["CH2"]))
        except:
            print("Something went wrong with Vphi fit...continue")
            pass



    print("Acquisition Ended!")
    plt.title("Acquired snapshot")
    plt.plot(result["time"],result["CH1"],label="CH1")
    plt.plot(result["time"],result["CH2"],label="CH2")
    plt.xlabel("Time")
    plt.ylabel("V")
    plt.legend()
    plt.tight_layout()
    plt.show()
    del scope
    return

if __name__ == "__main__":
    main()
