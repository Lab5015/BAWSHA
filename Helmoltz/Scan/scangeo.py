import sys
import h5py
import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

#------------------------------
# Geometrical constants
#------------------------------
L0 = float(sys.argv[1]) # total height in mm
Rout = 12.0 #outer radius in mm
cl  = 6.7*1e6 #longitudinal wave speed in mm/s
ct  = 5.4*1e6 #transverse wave speed in mm/s
eps = 1e-6
m = 0
#--------------------------------------
# Variable geometrical constants grid
#--------------------------------------
Rins =  (1-np.array([1/7, 1/6, 1/5, 1/4, 1/3]))*Rout    #inner radius in mm
hs = np.array([1/7, 1/6, 1/5, 1/4, 1/3])*L0  #step height in mm

geometries = {
    "Rin" : Rins,
    "hs" : hs,
    "results_dic": []
}

for Rin in Rins:
    for h in hs:
        print(f'Rin = {Rin}, h = {h}')
        def L(r):
            return L0 - h * 0.5 * (1 + np.tanh((r - Rin)/eps))

        R0 = Rout

        def ell(rho):
            r = R0*rho
            return L(r)/R0


        #--------------------------------------
        # Create grid
        #--------------------------------------
        Nr = 1000
        rho = (np.arange(Nr) + 0.5)/Nr
        drho = rho[1] - rho[0]

        #--------------------------------------
        # Create Laplacian operator matrix
        #--------------------------------------

        rp = rho + drho/2
        rm = rho - drho/2

        main = (rp + rm)/(rho*drho**2)
        upper = -rp/(rho*drho**2)
        lower = -rm/(rho*drho**2)

        # correggi i bordi per Neumann
        main[0] = 2/drho**2
        upper[0] = -2/drho**2
        lower[0] = 0

        main[-1] = 2/drho**2
        lower[-1] = -2/drho**2
        upper[-1] = 0

        D = sp.diags(
            diagonals=[lower[1:], main, upper[:-1]],
            offsets=[-1, 0, 1],
            format="csr"
        )

        #--------------------------------------
        # Results storage
        #--------------------------------------
        results = {
            "N": np.linspace(1,10,10,dtype=int),
            "eigvecs": [],
            "eigvals": [],
            "omegas":[],
            "V": [],
            "CR" : [],
            "Loss" : [],
            "FWHM" : []
        }

        #--------------------------------------
        # Solve eigenvalue problem
        #--------------------------------------

        def normalize_cyl(psi, rho):
            norm = np.trapezoid(psi**2 * rho, rho)
            return psi / np.sqrt(norm)

        def Confinement_ratio(psi, rho, rho_in):
            density = np.abs(psi)**2 * rho

            I_tot = np.trapezoid(density, rho)
            I_in  = np.trapezoid(density[rho < rho_in], rho[rho < rho_in])

            return I_in / I_tot

        def FWHM(psi, rho):
            rho = np.asarray(rho)
            psi = np.abs(np.asarray(psi))

            psi0 = psi[0]
            half = 0.5 * psi0

            # trova primo punto sotto metà
            idx = np.where(psi <= half)[0]

            if len(idx) == 0:
                raise ValueError("Half maximum non raggiunto nel dominio.")

            i = idx[0] - 1

            # interpolazione lineare
            rho1, rho2 = rho[i], rho[i+1]
            psi1, psi2 = psi[i], psi[i+1]

            rho_half = rho1 + (half - psi1) * (rho2 - rho1) / (psi2 - psi1)

            return rho_half * Rout

        def Loss(psi, rho_in):
            rho_total = np.linspace(0,2,len(psi))
            density = np.abs(psi)**2 * rho_total
            I_tot = np.trapezoid(density, rho_total)
            I_in  = np.trapezoid(density[rho_total > rho_in], rho[rho_total > rho_in])
            return I_in / I_tot

        for n in results["N"]:
            V = m**2/rho**2 + (cl/ct)**2*(n*np.pi/ell(rho))**2
            results["V"].append(V)
            A = D + sp.diags(V, 0)

            eigvals, eigvecs = spla.eigs(
                A,
                k=10,
                which="SM"
            )

            eigvals = np.real(eigvals)
            idx = np.argsort(eigvals)

            results["eigvals"].append(eigvals[idx])
            results["eigvecs"].append(eigvecs[:, idx])
            results["omegas"].append(np.sqrt(np.real(eigvals)))

        rho_in = Rin / Rout

        for i, n in enumerate(results["N"]):
            psi0 = results["eigvecs"][i][:, 0]   # ground radial mode
            CR = Confinement_ratio(psi0, rho, rho_in)
            loss = Loss(psi0, rho_in)
            try:
                fwhm = FWHM(psi0, rho)
                results["FWHM"].append(fwhm)
            except:
                continue
            results["CR"].append(CR)
            results["Loss"].append(loss)
            
        geometries["results_dic"].append(results)

#--------------------------------------
# Save results
#--------------------------------------
with h5py.File(f"geometry_scan_{L0}.h5", "w") as f:

    f.create_dataset("Rins", data=Rins)
    f.create_dataset("hs", data=hs)

    for i, results in enumerate(geometries["results_dic"]):

        Rin_val = float(Rins[i // len(hs)])
        h_val   = float(hs[i % len(hs)])

        grp = f.create_group(f"Rin_{Rin_val:.3f}_h_{h_val:.3f}")


        # salva parametri geometrici
        grp.attrs["Rin"] = float(
            Rins[i // len(hs)]
        )
        grp.attrs["h"] = float(
            hs[i % len(hs)]
        )

        # salva array semplici
        for key in ["N", "CR", "Loss", "FWHM"]:
            if len(results[key]) > 0:
                grp.create_dataset(key, data=np.array(results[key]))

        # liste di array → impacchettiamo in array 2D/3D
        grp.create_dataset("omegas", data=np.array(results["omegas"]))
        grp.create_dataset("eigvals", data=np.array(results["eigvals"]))
        grp.create_dataset("eigvecs", data=np.array(results["eigvecs"]))

'''
To read files

import h5py

with h5py.File("geometry_scan.h5", "r") as f:
    print(list(f.keys()))

    g = f["geometry_003"]
    print(g.attrs["Rin"], g.attrs["h"])

    CR = g["CR"][:]
    omegas = g["omegas"][:]


'''