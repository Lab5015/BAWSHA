import numpy as np
import matplotlib.pyplot as plt

# Fundamental constants
hbar = 1.0545718e-34  # Reduced Planck constant [J*s]
kB = 1.380649e-23     # Boltzmann constant [J/K]
phi0 = 2.068e-15      # Flux quantum [Wb]

def chi(omega0, T):
    """
    Compute the Callen–Welton factor χ for a mode with resonance angular frequency omega0 at temperature T.
    
    χ = (ħ ω0/(kB T)) [1/(exp(ħω0/(kB T))-1) + 1/2]
    
    Parameters:
      omega0 : Resonance angular frequency (rad/s)
      T      : Temperature (K)
    
    Returns:
      χ (dimensionless)
    """
    x = hbar * omega0 / (kB * T)
    return x * (1.0/np.expm1(x) + 0.5)

def noise_flux_nyq(omega, T, R, Q, omega0, LS):
    """
    Calculate the flux noise PSD due to the intrinsic (Nyquist) noise of the mechanical mode.
    For ω ≠ 0:
      S_φ^Nyq(ω) = [4 kB T χ R/(ω LS)^2] * [ ( (ω₀/Q * ω)² / ((ω₀² - ω²)² + (ω₀/Q * ω)²) ]
    
    For ω = 0, we use the analytic limit:
      S_φ^Nyq(0) = (4 kB T χ R/(LS^2 ω₀^4))*(ω₀/Q)^2.
    
    Parameters:
      omega  : Angular frequency (rad/s); scalar or numpy array.
      T      : Temperature (K)
      R      : Motional resistance (Ohm)
      Q      : Quality factor
      omega0 : Resonance angular frequency (rad/s)
      LS     : SQUID input inductance (H)
    
    Returns:
      S_phi_nyq : Flux noise PSD in Wb²/Hz.
    """
    tau_inv = omega0 / Q  # mode bandwidth
    # Define Z_S = omega * LS, but avoid division by zero:
    if np.isscalar(omega):
        if omega == 0:
            return (4 * kB * T * chi(omega0, T) * R * (tau_inv**2)) / (LS**2 * omega0**4)
        else:
            ZS = omega * LS
            denom = (omega0**2 - omega**2)**2 + (tau_inv * omega)**2
            return (4 * kB * T * chi(omega0, T) * R / (ZS**2)) * ((tau_inv * omega)**2 / denom)
    else:
        # For arrays, avoid dividing by very small omega:
        eps = 1e-12
        ZS = omega * LS
        # Compute the expression for nonzero frequencies:
        denom = (omega0**2 - omega**2)**2 + (tau_inv * omega)**2
        S = (4 * kB * T * chi(omega0, T) * R / (ZS**2)) * ((tau_inv * omega)**2 / denom)
        # Compute the analytic limit:
        limit_val = (4 * kB * T * chi(omega0, T) * R * (tau_inv**2)) / (LS**2 * omega0**4)
        # Replace values where |omega| is too small:
        return np.where(np.abs(omega) < eps, limit_val, S)

def noise_flux_backaction(omega, omega0, LS, kappa, R, S_i, m_eff, Q):
    """
    Calculate the flux noise PSD due to SQUID backaction.
    
    Starting with the backaction force noise:
      S_f^BA = κ^2 * R^2 * S_i   (assuming |Z_BA| ≈ R at resonance)
      
    Convert force noise to displacement noise via the mechanical susceptibility:
      |χ_m(ω)|^2 = 1/[m_eff^2 ((ω₀²-ω²)² + (ω ω₀/Q)^2)]
      
    Then convert displacement noise into flux noise using:
      S_phi^BA(ω) = κ^2 |Z_S(ω)|^2 S_x^BA(ω)
    
    Combining these, we have:
      S_phi^BA(ω) = κ^4 R^2 S_i |Z_S(ω)|^2 / [m_eff^2 ((ω₀²-ω²)² + (ω ω₀/Q)^2)]
    
    Parameters:
      omega  : Angular frequency (rad/s), scalar or array.
      omega0 : Resonance angular frequency (rad/s)
      LS     : SQUID input inductance (H)
      kappa  : Electromechanical coupling coefficient (sqrt(κ²)), SI units.
      R      : Motional resistance (Ohm)
      S_i    : SQUID current noise spectral density (A^2/Hz)
      m_eff  : Effective mass of the mechanical mode (kg)
      Q      : Quality factor
      
    Returns:
      S_phi_BA : Backaction flux noise PSD in Wb^2/Hz.
    """
    ZS = omega * LS
    chi_m_sq = 1.0 / (m_eff**2 * ((omega0**2 - omega**2)**2 + (omega * omega0 / Q)**2))
    S_phi_BA = (kappa**4) * (R**2) * S_i * (ZS**2) * chi_m_sq
    return S_phi_BA

def noise_flux_total(omega, T, R, Q, omega0, LS, kappa, S_i, m_eff, S_phi_add):
    """
    Sum all flux noise contributions:
      S_phi_total(ω) = S_phi^Nyq(ω) + S_phi^BA(ω) + S_phi^add
      
    Parameters:
      omega      : Angular frequency (rad/s)
      T          : Temperature (K)
      R          : Motional resistance (Ohm)
      Q          : Quality factor
      omega0     : Resonance angular frequency (rad/s)
      LS         : SQUID input inductance (H)
      kappa      : Electromechanical coupling coefficient
      S_i        : SQUID current noise PSD (A^2/Hz) for backaction
      m_eff      : Effective mass (kg)
      S_phi_add  : SQUID additive flux noise PSD (Wb^2/Hz)
    
    Returns:
      S_phi_total : Total flux noise PSD (Wb^2/Hz)
    """
    
    S_phi_nyq = noise_flux_nyq(omega, T, R, Q, omega0, LS)
    # S_phi_BA = noise_flux_backaction(omega, omega0, LS, kappa, R, S_i, m_eff, Q)
    return S_phi_nyq + S_phi_add # + S_phi_BA

def displacement_noise_total(omega, S_phi_total, LS, kappa):
    """
    Convert the total flux noise PSD into an overall displacement noise PSD.
    
    From the relation:
      S_x(ω) = S_phi(ω) / (κ^2 |Z_S(ω)|^2)
    with Z_S(ω)=ω*LS.
    
    Parameters:
      omega         : Angular frequency (rad/s)
      S_phi_total   : Total flux noise PSD (Wb^2/Hz)
      LS            : SQUID input inductance (H)
      kappa         : Electromechanical coupling coefficient
      
    Returns:
      S_x_total : Displacement noise PSD (m^2/Hz)
    """
    ZS = omega * LS
    return S_phi_total / (kappa**2 * ZS**2)

def flux2voltage_noise(S_phi, V_phi):
    """
    Convert the flux noise PSD into voltage noise amplitude (V/√Hz)
    using the SQUID flux-to-voltage transfer coefficient V_phi (V/Wb):
    
      V_noise(ω) = V_phi(ω) * sqrt(S_phi_total(ω))
    
    Parameters:
      S_phi_total   : Total flux noise PSD (Wb^2/Hz)
      V_phi         : SQUID flux-to-voltage transfer coefficient (V/Wb) [can be frequency dependent]
    
    Returns:
      Voltage noise amplitude spectral density (V/√Hz)
    """
    return V_phi * np.sqrt(S_phi)

def generate_noise(psd_func, deltaT, fs, seed=None):
    """
    Generate a real time series representing noise with a given power spectral density (PSD).

    The PSD function, psd_func(f), must return the noise power spectral density in units of 
    (signal units)²/Hz. For example, if your time series x(t) is measured in volts (V), then 
    psd_func should return values in V²/Hz.

    Parameters:
    -----------
    psd_func : function
        Function that takes a frequency (in Hz) and returns the PSD at that frequency in 
        (signal units)²/Hz. The function is assumed to be defined for nonnegative frequencies.
    fs : float
        Sampling frequency in Hz.
    deltaT : int
        Time duration of the time trace.
    seed : int, optional
        Seed for the random number generator for reproducibility.

    Returns:
    --------
    t : numpy.ndarray
        Time array in seconds.
    x : numpy.ndarray
        Real time series noise, with units matching the signal (e.g., volts), such that the 
        ensemble-averaged PSD approximates psd_func.

    Method:
    -------
    1. The frequency resolution is computed as df = 1/(N * dt).
    2. For each positive frequency (except DC and, if applicable, Nyquist), the Fourier 
       coefficients are set as:
           X[k] = sqrt(0.5 * psd_func(|f|) * df) * (a + i b)
       where a and b are independent standard normal random numbers.
    3. The factor of 0.5 ensures that, when combined with the corresponding negative frequency 
       (via Hermitian symmetry), the total power in that bin is psd_func(|f|)*df.
    4. The DC (0 Hz) and (if applicable) Nyquist frequency components are treated separately 
       as real-valued.
    5. The inverse FFT produces the real noise time series.
    """
    if seed is not None:
        np.random.seed(seed)
    # Total number of time samples
    N = int(deltaT * fs)

    dt = deltaT/N

    df = 1.0 / deltaT  # Frequency resolution in Hz
    freqs = np.fft.fftfreq(N, dt)  # Frequency bins in Hz
    
    # Initialize Fourier coefficient array
    X = np.zeros(N, dtype=complex)
    
    # DC component (0 Hz) must be real-valued
    X[0] = np.sqrt(psd_func(0) * df) * np.random.normal()
    
    # Handle even and odd N separately
    if N % 2 == 0:
        # Even N: indices 1 to N//2-1 for positive frequencies
        for k in range(1, N//2):
            f = freqs[k]
            amplitude = np.sqrt(0.5 * psd_func(np.abs(f)) * df)
            X[k] = amplitude * (np.random.normal() + 1j * np.random.normal())
            # Enforce Hermitian symmetry for a real time series
            X[-k] = np.conj(X[k])
        # Nyquist frequency (f = 1/(2*dt)) must be real-valued
        X[N//2] = np.sqrt(psd_func(np.abs(freqs[N//2])) * df) * np.random.normal()
    else:
        # Odd N: indices 1 to (N+1)//2 - 1 for positive frequencies
        for k in range(1, (N+1)//2):
            f = freqs[k]
            amplitude = np.sqrt(0.5 * psd_func(np.abs(f)) * df)
            X[k] = amplitude * (np.random.normal() + 1j * np.random.normal())
            X[-k] = np.conj(X[k])
    
    # Inverse FFT to obtain time series; take the real part to discard negligible imaginary values
    x = np.fft.ifft(X)
    x = np.real(x)
    t = np.arange(N) * dt
    
    return t, x, freqs

def generate_noise_vectorized(psd_func, deltaT, fs, seed=None):
    """
    Generate a real time series representing noise with a given power spectral density (PSD).
    
    Parameters:
    -----------
    psd_func : function
        Function that takes a frequency (or an array of frequencies) and returns the PSD 
        in (signal units)²/Hz.
    deltaT : float
        Total time duration of the time trace (in seconds).
    fs : float
        Sampling frequency in Hz.
    seed : int, optional
        Seed for the random number generator for reproducibility.
    
    Returns:
    --------
    t : numpy.ndarray
        Time array in seconds.
    x : numpy.ndarray
        Real time series noise such that its ensemble-averaged PSD approximates psd_func.
    
    Method:
    -------
    1. Define the number of samples N and the time step dt = deltaT/N.
    2. The frequency resolution is df = 1/deltaT.
    3. Compute the frequency bins with np.fft.fftfreq.
    4. The DC component is generated separately as a real number.
    5. For positive frequency bins (excluding DC and Nyquist if N is even), compute
       the amplitude for each bin using the formula:
           amplitude = sqrt(0.5 * psd_func(|f|) * df)
       and generate a complex random number (with independent normal real and imaginary parts).
    6. Assign these values to the positive frequency bins and enforce Hermitian symmetry.
    7. For even N, the Nyquist frequency (f = fs/2) is treated as a real number.
    8. Apply the inverse FFT to produce a real time series.
    """
    # Seed the random number generator, if provided
    if seed is not None:
        np.random.seed(seed)
        
    # Total number of time samples and time resolution
    N = int(deltaT * fs)
    dt = deltaT / N
    df = 1.0 / deltaT  # Frequency resolution in Hz
    
    # Frequency bins (both positive and negative)
    freqs = np.fft.fftfreq(N, dt)
    
    # Initialize Fourier coefficient array
    X = np.zeros(N, dtype=complex)
    
    # DC component (0 Hz) must be real-valued:
    X[0] = np.sqrt(psd_func(0) * df) * np.random.normal()
    
    # Determine the indices corresponding to positive frequencies.
    # For even N, the Nyquist frequency will be handled separately.
    if N % 2 == 0:
        pos_ind = np.arange(1, N//2)
        nyquist_ind = N//2
    else:
        pos_ind = np.arange(1, (N+1)//2)
    
    # Compute amplitudes for the positive frequency bins:
    # For each positive frequency, we have:
    #   amplitude = sqrt(0.5 * psd_func(|f|) * df)
    # where the factor 0.5 accounts for the distribution of power between positive and negative frequencies.
    amplitude = np.sqrt(0.5 * psd_func(np.abs(freqs[pos_ind])) * df)
    
    # Generate complex Gaussian random numbers for the positive frequencies:
    rand_complex = np.random.normal(size=pos_ind.size) + 1j * np.random.normal(size=pos_ind.size)
    
    # Assign the Fourier coefficients for the positive frequencies:
    X[pos_ind] = amplitude * rand_complex
    # Enforce Hermitian symmetry to ensure the time series is real:
    X[-pos_ind] = np.conj(X[pos_ind])
    
    # For even N, treat the Nyquist frequency separately as a real number:
    if N % 2 == 0:
        X[nyquist_ind] = np.sqrt(psd_func(np.abs(freqs[nyquist_ind])) * df) * np.random.normal()
    
    # Inverse FFT to obtain the time series, and take the real part
    x = np.fft.ifft(X).real
    # Construct the time array
    t = np.arange(N) * dt
    
    return t, x, freqs[freqs>0]

def add_noise_to_signal(signal, noise):
    """
    Superimpose a deterministic signal onto a noise time series.

    Both signal and noise must be numpy arrays of the same shape and in the same units 
    (e.g., volts). This function returns the composite time series, facilitating signal/noise analysis.

    Parameters:
    -----------
    signal : numpy.ndarray
        The deterministic signal with a user-defined shape.
    noise : numpy.ndarray
        The noise time series generated from generate_noise_time_series.

    Returns:
    --------
    composite : numpy.ndarray
        The resulting time series obtained as the sum: signal + noise.
    """
    if signal.shape != noise.shape:
        raise ValueError("Signal and noise must have the same shape.")
    
    return signal + noise

