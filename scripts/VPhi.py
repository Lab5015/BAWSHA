import os
import json
from datetime import datetime
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

class fitter:
    def __init__(self,time,CH1,CH2,data_folder_path):
        self.time = time
        self.CH1 = CH1
        self.CH2 = CH2
        self.results = None
        self.data_folder_path = data_folder_path

    def analyze_vphi(self, plot=True):
        
        def fit(x, a, b):
            return a*x + b
        
        time = self.time
        CH1  = self.CH1
        CH2  = self.CH2

        #----------------------------------------------
        # SELECT ONE MONITOR PERIOD
        #----------------------------------------------

        t1 = np.argmin(CH1)
        t2 = np.argmin(CH1) + (np.argmax(CH1) - np.argmin(CH1))
        pp = abs(t2 - t1)
        if t1 < t2:
            mask = (time > time[t1]) & (time < time[t2]) 
        else: 
            mask = (time > time[t1]) & (time < time[t1+pp]) 

        #----------------------------------------------
        # SELECT ONE VPHI PERIOD
        #----------------------------------------------
        
        CH1 = CH1[mask]
        CH2 = CH2[mask]

        if np.argmin(CH2) < np.argmax(CH2):
            V2 = np.argmax(CH2)
            V1 = np.argmin(CH2)
        else:
            V2 = np.argmin(CH2)
            V1 = np.argmax(CH2)
        Vpp = min(V1,V2) + V2 - V1

        #----------------------------------------------
        # CONVERT VOLTS IN FLUX QUANTA
        #----------------------------------------------

        F00 = np.linspace(0,2,len(CH1))
        F0 = F00[V1+int(1.5*Vpp):V1+int(3*Vpp)]
        V0 = CH2[V1+int(1.5*Vpp):V1+int(3*Vpp)]

        F = F0[np.argmin(V0):np.argmax(V0)]
        V = V0[np.argmin(V0):np.argmax(V0)]
        #----------------------------------------------
        # LINEAR FIT RESULTS vs NUMBER OF POINTS
        #----------------------------------------------

        m1 = np.where((F>1) & (V>0))[0][0]
        V0 = V[m1]
        V0_idx = np.where(V == V0)[0][0]

        results = {"pts": [], "As": [], "Bs": [], "A_errs": [], "B_errs": []}

        max_pts = 100
        for i in np.arange(10,max_pts,1):

            temp1 = F[V0_idx-i:V0_idx+i]
            temp2 = V[V0_idx-i:V0_idx+i]

            popt, pcov = curve_fit(fit, temp1, temp2)
            results["pts"].append(i)
            results["As"].append(popt[0])
            results["Bs"].append(popt[1])
            results["A_errs"].append(np.sqrt(np.diag(pcov))[0])
            results["B_errs"].append(np.sqrt(np.diag(pcov))[1])

        #----------------------------------------------
        # SELECT BEST NUM OF POINTS
        #----------------------------------------------

        th = 1e-5
        grad = np.gradient(results["As"], results["pts"])
        best_pts = None
        max_th = 1e-1

        while best_pts is None and th <= max_th:

            grad_mask = (grad > -th) & (grad < th)

            if np.any(grad_mask):
                best_pts = np.array(results["pts"])[grad_mask][0]
            else:
                th *= 2

        if best_pts is None:
            raise ValueError("Could not determine best_pts")

        best_A = results["As"][best_pts]
        best_B = results["Bs"][best_pts]
        best_A_err = results["A_errs"][best_pts]
        best_B_err = results["B_errs"][best_pts]
        if plot:

            x_plot = np.linspace(min(F[V0_idx-best_pts:V0_idx+best_pts]),
                     max(F[V0_idx-best_pts:V0_idx+best_pts]), 1000)

            plt.scatter(F, V, marker='o', s=2, color='k')
            plt.plot(x_plot, fit(x_plot, best_A, best_B), color='magenta')

            plt.ylabel('CH2 [V]')
            plt.xlabel(r'CH1 [$\Phi_{0}$]')
            plt.grid()
            plt.tight_layout()
            plt.show()
        self.results = [best_A, best_A_err, best_B, best_B_err]
        
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        filename = self.data_folder_path + f"/vphit_{timestamp}.json"
        
        with open(filename, "w") as f:
            json.dump(self.results, f, indent=4)
        print("File correctly created")
