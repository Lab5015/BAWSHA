import sys

import numpy as np

sys.path.append("../../../emulators/")
from utils import add_noise_to_signal  # pyright: ignore
from utils import flux2voltage_noise  # pyright: ignore
from utils import generate_noise_vectorized  # pyright: ignore
from utils import noise_flux_total  # pyright: ignore

hbar = 1.0545718e-34  # Reduced Planck constant [J*s]
kB = 1.380649e-23  # Boltzmann constant [J/K]
phi0 = 2.068e-15  # Flux quantum [Wb]

# Example parameters (adjust these as appropriate for your system)
T = 20e-3  # Temperature: 20 mK
R = 5.0  # Motional resistance [Ohm]
Q = 1e9  # Quality factor
f0 = 1e6  # Resonance frequency [Hz] (e.g., 1 MHz)
omega0 = 2 * np.pi * f0  # Resonance angular frequency [rad/s]
LS = 400e-9  # SQUID input inductance [H] (400 nH)
kappa = 1e-2  # Electromechanical coupling coefficient (√(κ²) ~ √(1e-4))

# Additional parameters for backaction and additive noise:
S_i = 1e-24  # SQUID current noise PSD (A^2/Hz); example value
m_eff = 0.1e-3  # Effective mass of the mechanical mode (kg) ~ 1 gram
S_phi_add = 2.1e-21**2  # SQUID additive flux noise PSD (Wb^2/Hz)

# SQUID flux-to-voltage conversion factor, for example:
# If the SQUID provides ~10 µV per flux quantum, then:
V_phi = 10e-6 / phi0  # [V/Wb]


fs = 122.88e6


def generate_example_signal(voltage=1e-3, Tduration=200e-3, t0=50e-3):
    psd = lambda f: flux2voltage_noise(
        np.sqrt(
            noise_flux_total(
                2 * np.pi * f, T, R, Q, omega0, LS, kappa, S_i, m_eff, S_phi_add
            )
        ),
        V_phi,
    )

    t, noise, _ = generate_noise_vectorized(psd, Tduration, fs, seed=42)

    f_signal = f0
    signal = (
        voltage
        * np.sin(2 * np.pi * f_signal * t + 0)
        * (np.heaviside(t - t0, 1) * np.exp(-(t - t0) / 50e-3))
    )
    x = add_noise_to_signal(signal, noise)
    return x, signal
