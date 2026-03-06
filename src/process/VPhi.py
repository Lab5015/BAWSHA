import sys
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

def fit(x, a, b):
    return a*x + b

if len(sys.argv)<2:
    raise SystemError("Insert data file path")

#----------------------------------------------
# LOAD DATA
#----------------------------------------------

data_path = sys.argv[1]
raw_data = np.genfromtxt(data_path, delimiter=',', skip_header=21).T
time = raw_data[0]
CH1 = raw_data[1]
CH2 = raw_data[2]

#----------------------------------------------
# SELECT ONE MONITOR PERIOD
#----------------------------------------------

mask = (time > time[np.argmax(CH1)]) & (time < time[np.argmin(CH1)]) 
minimum = CH1[mask][np.argmin(CH2[mask])]
maximum = CH1[mask][np.argmax(CH2[mask])]

minimum2 = CH2[mask][np.argmin(CH2[mask])]
maximum2 = CH2[mask][np.argmax(CH2[mask])]

#----------------------------------------------
# SELECT ONE VPHI PERIOD
#----------------------------------------------

V_period_pts =np.abs(np.where(CH1[mask]==maximum)[0]+np.where(CH1[mask]==minimum)[0])[0]
period_min = CH1[mask][np.argmin(CH2[mask])-V_period_pts]
period_max = CH1[mask][np.argmin(CH2[mask])]

if period_max < period_min:
    temp = period_min
    period_min = period_max
    period_max = temp

#----------------------------------------------
# CONVERT VOLTS IN FLUX QUANTA
#----------------------------------------------

mask_flux = (CH1[mask] > period_min) & (CH1[mask] < period_max) 
V = CH2[mask][mask_flux][::-1]
F = np.linspace(0,2,len(CH1[mask][mask_flux])) 

#----------------------------------------------
# LINEAR FIT RESULTS vs NUMBER OF POINTS
#----------------------------------------------

m1 = np.where((F>1) & (V>0))[0][0]
V0 = V[m1]
V0_idx = np.where(V == V0)[0][0]

results = {
    "pts" : [],
    "As" : [],
    "Bs" : [],
    "A_errs" : [],
    "B_errs" : []
}

max_pts = 100
for i in np.arange(1,max_pts,1):
    temp1 = F[V0_idx-i:V0_idx+i]
    temp2 = V[V0_idx-i:V0_idx+i]
    popt, pcov = curve_fit(fit, temp1, temp2)
    results["pts"].append(i)
    results["As"].append(popt[0])
    results["Bs"].append(popt[1])
    results["A_errs"].append(np.sqrt(np.diag(pcov))[0])
    results["B_errs"].append(np.sqrt(np.diag(pcov))[1])

#----------------------------------------------
# SELECT BEST NUM OF POINTS FROM VPHI GRADIENT
#----------------------------------------------

th = 1e-5
grad = np.gradient(results["As"], results["pts"])
best_pts = None
max_th = 1e-1  # valore massimo di th per evitare loop infinito

while best_pts is None and th <= max_th:
    grad_mask = (grad > -th) & (grad < th)
    if np.any(grad_mask):
        best_pts = np.array(results["pts"])[grad_mask][0]
    else:
        th *= 2  # aumento progressivo della soglia

if best_pts is None:
    raise ValueError("Non è stato possibile trovare best_pts nemmeno aumentando th!")

best_A = results["As"][best_pts]
best_B = results["Bs"][best_pts]
best_A_err = results["A_errs"][best_pts]
best_B_err = results["B_errs"][best_pts]

#----------------------------------------------
# PRINT AND PLOT
#----------------------------------------------

print(f"A = {best_A:.4} +/- {best_A_err:.4}")
print(f"B = {best_B:.4} +/- {best_B_err:.4}")

x_plot = np.linspace(min(F[V0_idx-best_pts:V0_idx+best_pts]),max(F[V0_idx-best_pts:V0_idx+best_pts]), 1000)
plt.scatter(F, V, marker='.', s=0.1, color='k', label='data')
plt.plot(x_plot, fit(x_plot, best_A, best_B),color='magenta', lw=2, label='linear fit')

textstr = '\n'.join((
    rf"$A = {best_A:.3g}$ $\pm$ ${best_A_err:.3g}$"+r" $\frac{V}{\Phi_0}$",
    rf"$B = {best_B:.3g}$ $\pm$ ${best_B_err:.3g}$"+r" V"
))

plt.text(0.05, 0.95, textstr,
         transform=plt.gca().transAxes,
         fontsize=11,
         verticalalignment='top',
         bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))

plt.legend()
plt.ylabel('CH2 [V]')
plt.xlabel(r'CH1 [$\Phi_{0}$]')
plt.grid()
plt.tight_layout()
plt.show()