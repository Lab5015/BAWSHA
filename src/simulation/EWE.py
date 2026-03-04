import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

Rout = 12 #outer radius in mm
cl  = 6.7*1e6 #longitudinal wave speed in mm/s
ct  = 5.4*1e6 #transverse wave speed in mm/s
density = 2.6*1e-3 #g/mm^3
m = 0

#-------------------------------------------
# Crystals Profiles
#-------------------------------------------

def step(r, L0, h, Rin, eps):
    """
    Step profile of the crystal height.

    The thickness transitions smoothly from L0 to L0 - h 
    around radius Rin using a hyperbolic tangent with 
    smoothing parameter eps.

    Parameters
    ----------
    r : array_like
        Radial coordinate [mm].
    L0 : float
        Central thickness of the crystal [mm].
    h : float
        Step height (depth of the outer region) [mm].
    Rin : float
        Step transition radius [mm].
    eps : float
        Smoothing length of the step [mm].

    Returns
    -------
    array_like
        Crystal thickness profile evaluated at r [mm].
    """
    return L0 - h * 0.5 * (1 + np.tanh((r - Rin)/eps))

def pc(r, L0, h):
    """
    Plano-convex (parabolic) crystal profile.

    The thickness decreases quadratically with radius.

    Parameters
    ----------
    r : array_like
        Radial coordinate [mm].
    L0 : float
        Central thickness [mm].
    h : float
        Maximum height reduction at the edge [mm].

    Returns
    -------
    array_like
        Crystal thickness profile [mm].
    """
    return L0-h*(r/Rout)**2

def multistep(r, L0, h, eps):
    """
    Multi-step smooth crystal profile.

    Generates multiple radial steps using a sum of 
    hyperbolic tangent transitions.

    Parameters
    ----------
    r : array_like
        Radial coordinate [mm].
    L0 : float
        Central thickness [mm].
    h : float
        Total height reduction [mm].
    eps : float
        Smoothing parameter for step transitions [mm].

    Returns
    -------
    array_like
        Multi-step thickness profile [mm].
    """
    G = 3
    beta = 0
    alpha = 0
    temp = 0
    for i in np.linspace(1,G-1,G-1):
        alpha += i**2 * np.tanh(-i*Rout/(G*eps)) 
        beta += i**2 * np.tanh((Rout*(1 - (i/G)))/eps)
    A =  L0 - h + beta * h / (beta - alpha)
    B = h * G / (beta - alpha)
    for i in np.linspace(1,G-1,G-1):
        temp += i**2 * np.tanh((r - Rout*(i/G))/eps)
    return A - B/G*temp

#-------------------------------------------
# X axis discretization
#-------------------------------------------

Nr = 1000
rho = np.linspace(1e-4, 2, Nr)
mask = rho < 1.0      
drho = rho[1] - rho[0]

#-------------------------------------------
# Laplacian Operator
#-------------------------------------------

def Laplacian():
    """
    Construct the radial Laplacian operator in cylindrical coordinates.
    Implements the finite-difference discretization of:

        (1/r) d/dr (r d/dr)

    with Neumann boundary conditions at rho=0 and rho=max.
    
    Returns
    -------
    scipy.sparse.csr_matrix
        Sparse matrix representation of the Laplacian.
    """

    rp = rho + drho/2
    rm = rho - drho/2

    main = (rp + rm)/(rho*drho**2)
    upper = -rp/(rho*drho**2)
    lower = -rm/(rho*drho**2)

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
    
    return D


#-------------------------------------------
# Confinment Ratio, Loss and HWHM
#-------------------------------------------

def Confinement_ratio(psi, rho, rho_in):
    """
    Compute the confinement ratio of a mode.

    Defined as the fraction of the mode energy contained
    within rho < rho_in, where rho_in will be the ratio between the electrode x 
    coordinate and the radius of the crystal.

    Parameters
    ----------
    psi : array_like
        Eigenmode radial profile.
    rho : array_like
        Dimensionless radial coordinate.
    rho_in : float
        Inner confinement radius (dimensionless).

    Returns
    -------
    float
        Confinement ratio (between 0 and 1).
    """
    mask = rho < 1.0     
    rho_cut = rho[mask]
    psi_cut = psi[mask]
    density = np.abs(psi_cut)**2 * rho_cut
    I_tot = np.trapezoid(density, rho_cut)
    I_in  = np.trapezoid(density[rho_cut < rho_in],rho_cut[rho_cut < rho_in])
    return I_in / I_tot

def Loss(psi, rho):
    """
    Compute the loss fraction outside the resonator (rho > 1).

    Parameters
    ----------
    psi : array_like
        Eigenmode radial profile.
    rho : array_like
        Dimensionless radial coordinate.

    Returns
    -------
    float
        Fraction of mode energy outside rho > 1.
    """
    density = np.abs(psi)**2 * rho
    I_tot = np.trapezoid(density, rho)
    I_out  = np.trapezoid(density[rho > 1], rho[rho > 1])
    return I_out / I_tot

def HWHM(psi, rho):
    """
    Compute the Half Width at Half Maximum (HWHM).

    Determines the radial distance at which |psi| falls
    to half its central value.

    Parameters
    ----------
    psi : array_like
        Eigenmode radial profile.
    rho : array_like
        Dimensionless radial coordinate.

    Returns
    -------
    float
        Half-width at half-maximum [mm].
    """
    mask = rho < 1.0      
    rho_cut = rho[mask]
    psi_cut = psi[mask]
    psi = np.abs(np.asarray(psi))
    psi0 = psi[0]
    half = 0.5 * psi0

    idx = np.where(psi <= half)[0]

    if len(idx) == 0:
        raise ValueError("Half maximum non raggiunto nel dominio.")

    i = idx[0] - 1

    rho1, rho2 = rho[i], rho[i+1]
    psi1, psi2 = psi[i], psi[i+1]

    rho_half = rho1 + (half - psi1) * (rho2 - rho1) / (psi2 - psi1)

    return rho_half * Rout


#-------------------------------------------
# Solve PDE
#-------------------------------------------

def solve_PDE(profile, D, L0, h, Rin, eps):
    """
    Solve the radial eigenvalue problem for a given crystal profile.

    The operator solved is:
        A = D + V(rho)

    where D is the Laplacian and V includes geometric 
    and longitudinal mode contributions.

    Parameters
    ----------
    profile : str
        Profile type ('MS', 'SP', 'PC').
    D : scipy.sparse matrix
        Radial Laplacian operator.
    L0 : float
        Central thickness [mm].
    h : float
        Height reduction parameter [mm].
    Rin : float
        Inner step radius [mm].
    eps : float
        Smoothing parameter [mm].

    Returns
    -------
    dict
        Dictionary containing:
        - eigenvalues
        - eigenvectors
        - frequencies
        - confinement ratios
        - loss fractions
        - HWHM values
    """
    
    #-------------------------------------------
    # Define Data structure
    #-------------------------------------------
    results = {
    "N": [1,3,5,7,9,11,13],
    "eigvecs": [],
    "eigvals": [],
    "omegas" : [],
    "CR" : [],
    "Loss" : [],
    "HWHM" : []
    }
    
    if profile=='MS':
    
        def ell(rho):
            r = Rout*rho
            return multistep(r, L0, h, eps)/Rout
    elif profile=='SP':
        def ell(rho):
            r = Rout*rho
            return step(r, L0, h, Rin, eps)/Rout
        
    elif profile=='PC':
        def ell(rho):
            r = Rout*rho
            return pc(r, L0, h)/Rout
        
    for n in results["N"]:

        try:
            V = m**2/rho**2 + (cl/ct)**2*(n*np.pi/ell(rho))**2
        except:
            pass
        
        A = D + sp.diags(V, 0)

        eigvals, eigvecs = spla.eigs(
            A,
            k=2,
            which="SM"
        )

        eigvals = np.real(eigvals)
        idx = np.argsort(eigvals)

        results["eigvals"].append(eigvals[idx])
        results["eigvecs"].append(eigvecs[:, idx])
        results["omegas"].append(np.sqrt(np.real(eigvals)))
        results["CR"].append(Confinement_ratio(eigvecs[:, 0], rho, Rin/Rout))
        results["Loss"].append(Loss(eigvecs[:, 0], rho))
        results["HWHM"].append(HWHM(eigvecs[:, 0], rho))
        
    return results

#-------------------------------------------
# Normilize to crystal height
#-------------------------------------------

def normalize_cyl(psi, rho):
    """
    Normalize a radial mode in cylindrical coordinates.

    Ensures:
        ∫ |psi|^2 rho drho = 1

    Parameters
    ----------
    psi : array_like
        Radial mode profile.
    rho : array_like
        Radial coordinate.

    Returns
    -------
    array_like
        Normalized mode profile.
    """
    norm = np.trapezoid(psi**2 * rho, rho)
    return psi / np.sqrt(norm)

#-------------------------------------------
# Plot Modes
#-------------------------------------------

def plot_modes(results_pc, results_step, results_ms, L0, Rin, h, eps, save_plot = False, save_path='', plot=False):
    """
    Plot radial eigenmodes for different crystal profiles.

    Parameters
    ----------
    results_pc : dict
        Results for plano-convex profile.
    results_step : dict
        Results for step profile.
    results_ms : dict
        Results for multi-step profile.
    L0 : float
        Central thickness [mm].
    Rin : float
        Step radius [mm].
    h : float
        Height reduction [mm].
    eps : float
        Smoothing parameter [mm].
    save_plot : bool, optional
        If True, saves the figure.
    save_path : str, optional
        Output file path (without extension).
    plot : bool, optional
        If True, displays the plot.
    """
    fig, axs = plt.subplots(1, 3, figsize=(15,5), sharey=True)
    rho_c = rho[mask] * Rout

    for i, n in enumerate([1,3,5,7]):

        psi_pc = normalize_cyl(results_pc["eigvecs"][i][:,0][mask], rho_c)
        psi_pc *= pc(0, L0, h) / psi_pc[0]
        axs[0].plot(rho_c, np.abs(psi_pc), lw=2, color='b',
                    alpha=1/(i+1), label=f'N={n}')

        psi_step = normalize_cyl(results_step["eigvecs"][i][:,0][mask], rho_c)
        psi_step *= step(0, L0, h, Rin, eps) / psi_step[0]
        axs[1].plot(rho_c, np.abs(psi_step), lw=2, color='r',
                    alpha=1/(i+1), label=f'N={n}')

        psi_ms = normalize_cyl(results_ms["eigvecs"][i][:,0][mask], rho_c)
        psi_ms *= multistep(0, L0, h, eps) / psi_ms[0]
        axs[2].plot(rho_c, np.abs(psi_ms), lw=2, color='r',
                    alpha=1/(i+1), label=f'N={n}')

    if save_plot:
        axs[0].plot(rho[mask]*Rout, pc(rho[mask]*Rout, L0, h), color='k', lw=2)
        axs[1].plot(rho[mask]*Rout, step(rho[mask]*Rout, L0, h, Rin, eps), color='k', lw=2)
        axs[2].plot(rho[mask]*Rout, multistep(rho[mask]*Rout, L0, h, eps), color='k', lw=2)
        axs[0].set_title('Plano Convex Profile', fontsize=14)
        axs[1].set_title('Step Profile', fontsize=14)
        axs[2].set_title('Multi-Step Profile', fontsize=14)

        for i in range(3):
            axs[i].axvline(0, 0.05, 0.95, color='k', lw=2, ls='-')
            axs[i].axhline(0, 0.05, 0.95, color='k', lw=2)
            axs[i].axvline(Rout, 0.05, (L0-h)/L0, color='k', lw=2, ls='-')
            axs[i].set_xlabel('Radius [mm]', fontsize=14)
            axs[i].set_ylabel(r"Height [mm]", fontsize=14)
            axs[i].legend(loc='lower left')
            axs[i].grid()

        fig.suptitle(f'Radial Profiles, h={h}, L={L0}, R_in={Rin}', fontsize=16)
        plt.tight_layout()
        if plot:
            plt.show()
        plt.savefig(save_path+".png")
    
#-------------------------------------------
# Fit results
#-------------------------------------------

def CR_fitter(x,a,b,c,d):
    """
    Logistic fit function for confinement ratio.

    Returns
    -------
    array_like
        Fitted CR values.
    """
    return a/(np.exp(-c*(x-b))+1) + d

def Loss_fitter(x,b,c,d):
    """
    Exponential decay fit function for loss/HWHM.

    Returns
    -------
    array_like
        Fitted values.
    """
    return np.exp(-b*(x-c))+d

def resonant_mass(hwhm, L0):
    """
    Estimate resonant mass from HWHM.

    Assumes cylindrical effective mass:
        M ~ pi * HWHM^2 * L0 * density

    Parameters
    ----------
    hwhm : array_like
        Half-width at half-maximum [mm].
    L0 : float
        Crystal thickness [mm].

    Returns
    -------
    array_like
        Resonant mass [g].
    """
    return np.array(hwhm)**2 * L0 * np.pi * density

def fit_CR(results_pc, results_step, results_ms, save_plot=False, plot=False, save_path=''):
    """
    Fit confinement ratios for different profiles.

    Returns
    -------
    tuple
        Optimized parameters for PC, Step, and MS profiles.
    """
    try:
        popt_pc, _   = curve_fit(CR_fitter, results_pc["N"], results_pc["CR"], maxfev=10000) 
    except:
        print('CR Plano Convex Fit did not work')
        pass
    try:
        popt_step, _ = curve_fit(CR_fitter, results_step["N"], results_step["CR"], maxfev=10000) 
    except:
        print('CR Step Fit did not work')
        pass
    try:
        popt_ms, _   = curve_fit(CR_fitter, results_ms["N"], results_ms["CR"], maxfev=10000) 
    except:
        print('CR MultiStep Fit did not work')
        pass
        
    if save_plot:
        fig, axs = plt.subplots(1, 3, figsize=(15,5), sharey=True)
        N_plot = np.linspace(1,13,100)

        axs[0].scatter(results_pc["N"], results_pc["CR"],marker='o', color='b', alpha=0.5)
        axs[0].plot(N_plot, CR_fitter(N_plot, *popt_pc), color='k', label='fit')
        axs[0].set_title('Plano Convex Profile', fontsize=14)

        axs[1].scatter(results_step["N"], results_step["CR"], marker='o', color='r', alpha=0.5)
        axs[1].plot(N_plot, CR_fitter(N_plot, *popt_step), color='k', label='fit')
        axs[1].set_title('Step Profile', fontsize=14)

        axs[2].scatter(results_ms["N"], results_ms["CR"], marker='o', color='g', alpha=0.5)
        axs[2].plot(N_plot, CR_fitter(N_plot, *popt_ms), color='k', label='fit')
        axs[2].set_title('Multi-step Profile', fontsize=14)

        for i in range(3):
            axs[i].set_xlabel('N', fontsize=14)
            axs[i].set_xticks(results_pc["N"])
            axs[i].set_ylabel(r"CR", fontsize=14)
            axs[i].grid()

        fig.suptitle('Confinment Ratios', fontsize=16)
        plt.tight_layout()
        if plot:
            plt.show()
        plt.savefig(save_path+".png")
        
    return popt_pc, popt_step, popt_step
        

def fit_RM(results_pc, results_step, results_ms, L0, save_plot=False, plot=False, save_path=''):
    """
    Fit resonant mass trends derived from HWHM.

    Returns
    -------
    tuple
        Optimized parameters for PC, Step, and MS profiles.
    """
    try:
        popt_hwhm_pc, _   = curve_fit(Loss_fitter, results_pc["N"], results_pc["HWHM"], maxfev=10000) 
    except:
        print('HWHM Plano Convex Fit did not work')
        pass
    try:
        popt_hwhm_step, _ = curve_fit(Loss_fitter, results_step["N"], results_step["HWHM"], maxfev=10000) 
    except:
        print('HWHM Step Fit did not work')
        pass
    try:
       popt_hwhm_ms, _   = curve_fit(Loss_fitter, results_ms["N"], results_ms["HWHM"], maxfev=10000) 
    except:
        print('HWHM MultiStep Fit did not work')
        pass
        
    if save_plot:
        N_plot = np.linspace(1,13,100)
        fig, axs = plt.subplots(1, 3, figsize=(15,5), sharey=True)
        axs[0].scatter(results_pc["N"], resonant_mass(results_pc["HWHM"], L0), marker='o', color='b', alpha=0.5)
        axs[0].plot(N_plot, resonant_mass(Loss_fitter(N_plot, *popt_hwhm_pc), L0), color='k', label='fit')

        axs[1].scatter(results_step["N"], resonant_mass(results_step["HWHM"], L0), marker='o', color='r', alpha=0.5)
        axs[1].plot(N_plot, resonant_mass(Loss_fitter(N_plot, *popt_hwhm_step), L0), color='k', label='fit')

        axs[2].scatter(results_ms["N"], resonant_mass(results_ms["HWHM"], L0), marker='o', color='r', alpha=0.5)
        axs[2].plot(N_plot, resonant_mass(Loss_fitter(N_plot, *popt_hwhm_ms), L0), color='k', label='fit')

        for i in range(3):
            axs[i].set_xlabel('N', fontsize=14)
            axs[i].set_xticks(results_pc["N"])
            axs[i].set_ylabel(r"Resonant mass [g]", fontsize=14)
            axs[i].grid()

        axs[0].set_title('Plano Convex Profile', fontsize=14)
        axs[1].set_title('Step Profile', fontsize=14)
        axs[2].set_title('Multi-step Profile', fontsize=14)
        fig.suptitle('Resonant Mass', fontsize=16)
        plt.tight_layout()
        if plot:
            plt.show()
        plt.savefig(save_path+".png")
        
    return popt_hwhm_pc, popt_hwhm_step, popt_hwhm_ms

def arr_to_str(arr):
    """
    Convert a numeric array to a comma-separated string 
    in scientific notation.

    Returns
    -------
    str
    """
    return ",".join(f"{x:.8e}" for x in np.atleast_1d(arr))

def check_under_profile(profile, mode):
    """
    Check if a mode lies entirely under the crystal profile.

    Parameters
    ----------
    profile : array_like
        Crystal height profile.
    mode : array_like
        Mode amplitude profile.

    Returns
    -------
    bool
        True if mode is fully below profile.
    """
    if np.all(mode < profile) == np.True_:
        return True
    else:
        return False