import sys
import h5py
import numpy as np

from Utils import (
    step_profile, ell_function,
    radial_grid, laplacian_cylindrical,
    solve_radial_modes,
    Confinement_ratio, Loss, HWHM
)

# -------------------------
# Constants
# -------------------------

L0 = float(sys.argv[1])
Rout = 12.0 # This is fixed
cl = 6.7e6
ct = 5.4e6
eps = 1e-6
m = 0

# -------------------------
# Geometry scan
# -------------------------

Rins = (1 - np.array([1/7, 1/6, 1/5, 1/4, 1/3])) * Rout
hs = np.array([1/7, 1/6, 1/5, 1/4, 1/3]) * L0

Nr = 1000
rho, drho = radial_grid(Nr)
D = laplacian_cylindrical(rho, drho)

N_list = [1, 3, 5, 7, 9, 11, 13]

results_all = []

for Rin in Rins:
    for h in hs:
        print(f"Rin={Rin:.3f}, h={h:.3f}")

        L = step_profile(L0, h, Rin, eps)
        ell = ell_function(L, Rout)

        res = solve_radial_modes(
            D, rho, ell, N_list,
            cl, ct, m
        )

        rho_in = Rin / Rout
        CR, Loss, FWHM = [], [], []

        for i in range(len(N_list)):
            psi0 = res["eigvecs"][i][:, 0]
            CR.append(Confinement_ratio(psi0, rho, rho_in))
            Loss.append(Loss(psi0, rho_in))
            try:
                FWHM.append(HWHM(psi0, rho, Rout))
            except:
                FWHM.append(np.nan)

        res["CR"] = CR
        res["Loss"] = Loss
        res["FWHM"] = FWHM
        res["Rin"] = Rin
        res["h"] = h

        results_all.append(res)

# -------------------------
# Save HDF5
# -------------------------

with h5py.File(f"geometry_scan_{L0}.h5", "w") as f:
    f.create_dataset("Rins", data=Rins)
    f.create_dataset("hs", data=hs)

    for i, res in enumerate(results_all):
        grp = f.create_group(f"Rin_{res['Rin']:.3f}_h_{res['h']:.3f}")
        grp.attrs["Rin"] = res["Rin"]
        grp.attrs["h"] = res["h"]

        for key in ["N", "CR", "Loss", "FWHM"]:
            grp.create_dataset(key, data=np.array(res[key]))

        grp.create_dataset("omegas", data=np.array(res["omegas"]))
        grp.create_dataset("eigvals", data=np.array(res["eigvals"]))
        grp.create_dataset("eigvecs", data=np.array(res["eigvecs"]))