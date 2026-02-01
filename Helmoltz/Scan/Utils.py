import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla

# ============================================================
# Geometry
# ============================================================

def step_profile(L0, h, Rin, eps):
    """
    Create a smooth step profile for the BAR height.

    Parameters
    ----------
    L0 : float
        Central height of the resonator (r = 0).
    h : float
        Step height.
    Rin : float
        Radius at which the step occurs.
    eps : float
        Smoothing parameter of the tanh transition.

    Returns
    -------
    L : callable
        Function L(r) giving the local height at radius r.
    """
    def L(r):
        return L0 - h * 0.5 * (1 + np.tanh((r - Rin) / eps))
    return L


def ell_function(L, Rout):
    """
    Define the dimensionless thickness function ell(rho).

    Parameters
    ----------
    L : callable
        Height profile L(r).
    Rout : float
        Outer radius of the resonator.

    Returns
    -------
    ell : callable
        Function ell(rho) = L(Rout * rho) / Rout.
    """
    def ell(rho):
        return L(Rout * rho) / Rout
    return ell


# ============================================================
# Grid
# ============================================================

def radial_grid(Nr):
    """
    Create a uniform radial grid in the dimensionless coordinate rho.

    Parameters
    ----------
    Nr : int
        Number of radial grid points.

    Returns
    -------
    rho : ndarray
        Radial grid points in (0, 1).
    drho : float
        Grid spacing.
    """
    rho = (np.arange(Nr) + 0.5) / Nr
    drho = rho[1] - rho[0]
    return rho, drho


# ============================================================
# Laplacian operator
# ============================================================

def laplacian_cylindrical(rho, drho):
    """
    Construct the radial Laplacian operator in cylindrical coordinates
    with Neumann boundary conditions.

    The operator corresponds to:
        (1/rho) d/drho (rho d/drho)

    Parameters
    ----------
    rho : ndarray
        Radial grid.
    drho : float
        Grid spacing.

    Returns
    -------
    D : scipy.sparse.csr_matrix
        Sparse Laplacian matrix.
    """
    rp = rho + drho / 2
    rm = rho - drho / 2

    main = (rp + rm) / (rho * drho**2)
    upper = -rp / (rho * drho**2)
    lower = -rm / (rho * drho**2)

    # Neumann BC at rho = 0
    main[0] = 2 / drho**2
    upper[0] = -2 / drho**2
    lower[0] = 0

    # Neumann BC at rho = 1
    main[-1] = 2 / drho**2
    lower[-1] = -2 / drho**2
    upper[-1] = 0

    D = sp.diags(
        diagonals=[lower[1:], main, upper[:-1]],
        offsets=[-1, 0, 1],
        format="csr"
    )

    return D


# ============================================================
# Observables
# ============================================================

def normalize_cyl(psi, rho):
    """
    Normalize a radial wavefunction in cylindrical coordinates.

    The normalization condition is:
        ∫ |psi|^2 rho d rho = 1

    Parameters
    ----------
    psi : ndarray
        Radial wavefunction.
    rho : ndarray
        Radial grid.

    Returns
    -------
    psi_norm : ndarray
        Normalized wavefunction.
    """
    norm = np.trapezoid(psi**2 * rho, rho)
    return psi / np.sqrt(norm)


def Confinement_ratio(psi, rho, rho_in):
    """
    Compute the confinement ratio inside rho < rho_in.

    Parameters
    ----------
    psi : ndarray
        Radial wavefunction.
    rho : ndarray
        Radial grid.
    rho_in : float
        Inner radius (dimensionless).

    Returns
    -------
    CR : float
        Confinement ratio I_in / I_tot.
    """
    density = np.abs(psi)**2 * rho
    I_tot = np.trapezoid(density, rho)
    I_in = np.trapezoid(density[rho < rho_in], rho[rho < rho_in])
    return I_in / I_tot


def Loss(psi, rho):
    """
    Estimate the leakage outside rho > rho_in.

    Parameters
    ----------
    psi : ndarray
        Radial wavefunction.
    rho_in : float
        Inner radius (dimensionless).

    Returns
    -------
    loss : float
        Fraction of norm outside rho_in.
    """
    density = np.abs(psi)**2 * rho
    I_tot = np.trapezoid(density, rho)
    I_out  = np.trapezoid(density[rho > 1], rho[rho > 1])
    return I_out / I_tot


def HWHM(psi, rho, Rout):
    """
    Compute the half width at half maximum (HWHM) of the ground mode.

    Assumes psi[0] is the maximum.

    Parameters
    ----------
    psi : ndarray
        Radial wavefunction.
    rho : ndarray
        Radial grid.
    Rout : float
        Outer radius of the resonator.

    Returns
    -------
    hwhm : float
        HWHM in physical units.
    """
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


# ============================================================
# Eigenvalue problem
# ============================================================

def solve_radial_modes(
    D, rho, ell, N_list,
    cl, ct, m, k=10
):
    """
    Solve the radial eigenvalue problem for multiple longitudinal indices n.

    Parameters
    ----------
    D : scipy.sparse.csr_matrix
        Radial Laplacian operator.
    rho : ndarray
        Radial grid.
    ell : callable
        Dimensionless thickness function ell(rho).
    N_list : array-like
        List of longitudinal mode indices n.
    cl : float
        Longitudinal sound speed.
    ct : float
        Transverse sound speed.
    m : int
        Azimuthal quantum number.
    k : int, optional
        Number of eigenvalues to compute.

    Returns
    -------
    results : dict
        Dictionary containing eigenvalues, eigenvectors,
        frequencies and effective potentials.
    """
    results = {
        "N": N_list,
        "eigvals": [],
        "eigvecs": [],
        "omegas": [],
        "V": []
    }

    for n in N_list:
        V = m**2 / rho**2 + (cl / ct)**2 * (n * np.pi / ell(rho))**2
        A = D + sp.diags(V, 0)

        eigvals, eigvecs = spla.eigs(A, k=k, which="SM")
        eigvals = np.real(eigvals)
        idx = np.argsort(eigvals)

        results["V"].append(V)
        results["eigvals"].append(eigvals[idx])
        results["eigvecs"].append(eigvecs[:, idx])
        results["omegas"].append(np.sqrt(eigvals[idx]))

    return results