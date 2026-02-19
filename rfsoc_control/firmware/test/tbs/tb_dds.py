import os
import sys

import matplotlib.pyplot as plt
import numpy as np

# run path of thew simulation, used for all files
PATH = "/home/rodolfo/Venv/bauscia/SimBa/firmware/lockin/lockin.sim/sim_1/behav/xsim/"

# generics and FS, not to change usually
COS_TABLE_LEN = 10
DAC_WIDTH = 18
PAC_WIDTH = 32
AMP_MAX = 65520
INTERP_NBITS = 18

# FS = 100.00e6
FS = 153.6e6

# hardcoded parameters, to change for testing!
NUM_SAMPLES = 10_000
INIT_FREQ = 10e6
INIT_PHASE = 0


def main():
    print(f"\nGenerics for .vhd:")
    print(f"\tnum_samples: {NUM_SAMPLES}\n")

    os.makedirs(os.path.dirname(PATH), exist_ok=True)

    generate_stimuli(
        stimul_file=PATH + "stimuli.txt",
        results_file=PATH + "results.txt",
        init_freq=INIT_FREQ,
        init_phase=INIT_PHASE,
    )

    expected_results = np.loadtxt(PATH + "results.txt")
    try:
        effective_results = np.loadtxt(PATH + "effective_results.txt")
    except FileNotFoundError:
        print(f"Result file not found")
        return
    check_equality(expected_results, effective_results)

    plt.plot(
        1e6 * np.arange(len(expected_results)) / FS,
        expected_results,
        label="expected results",
    )
    plt.plot(
        1e6 * np.arange(len(effective_results)) / FS,
        effective_results,
        label="effective_results",
    )
    plt.xlabel("Time [us]")
    plt.legend()
    plt.show()


def to_b(num, length):
    num = int(np.floor(num % (2**length)))
    if num >= 0:
        return_val = f"{num:0{length}b}"
        if len(return_val) == length:
            return return_val

    return_val = f"{(1 << length) + num:0{length}b}"
    if return_val[0] == "-":
        raise Exception(f"Coldn't convert {num} in {length} bits")
    if len(return_val) == length:
        return return_val
    raise Exception("Negative number to large")


def interpolate_cos(phase, phi_0=0):
    """Given a list of phases, returns a list of cos samples."""

    phases_64 = np.linspace(0, 2 * np.pi, 2**COS_TABLE_LEN, False)
    cos_table = np.array(np.round(AMP_MAX * np.cos(phases_64)), dtype=np.int64)

    phase = (phase + phi_0) & (2**PAC_WIDTH - 1)
    index = phase >> (PAC_WIDTH - COS_TABLE_LEN)

    val_a = cos_table[index]
    val_b = cos_table[(index + 1) % (2**COS_TABLE_LEN)]

    mask = (2**INTERP_NBITS - 1) << (PAC_WIDTH - INTERP_NBITS - COS_TABLE_LEN)
    diff_phase = phase & mask

    diff_y = val_b - val_a
    diff_x = 1 << (PAC_WIDTH - COS_TABLE_LEN)

    values = val_a + diff_y / diff_x * diff_phase
    values = np.array(np.round(values), dtype=np.int64)

    return values


def int_cos(
    times,
    f0: float,
    sampling_rate: float,
    phi_0=0.0,
):
    """Returns a linear frequency chirp in integers with PAC_WIDTH."""
    freq = int(np.round(2**PAC_WIDTH * f0 / sampling_rate))
    new_phi_0 = int(np.round(2**PAC_WIDTH * phi_0 / (2 * np.pi)))

    phases = np.arange(len(times), dtype=np.int64) * freq
    vals = interpolate_cos(phases, new_phi_0)

    return vals


def generate_stimuli(stimul_file, results_file, init_freq, init_phase):
    with open(stimul_file, "w") as file:

        b_init_freq = to_b(int(round(2**PAC_WIDTH * init_freq / FS)), PAC_WIDTH)
        b_init_phase = to_b(
            int(round(2**PAC_WIDTH * init_phase / (2 * np.pi))), PAC_WIDTH
        )
        b_parameters = f"{b_init_freq}  {b_init_phase}"
        file.write(b_parameters)

    times = np.arange(NUM_SAMPLES) / FS
    values = np.int64(int_cos(times, init_freq, FS, init_phase))
    np.savetxt(results_file, values, fmt="%i")


def check_equality(expected, effective_results):
    expected = np.array(expected)
    effective_results = np.array(effective_results)
    if len(effective_results) != len(expected):
        print("Result arrays have different lengths")
        print(f"\tEffective: {len(effective_results)}")
        print(f"\tExpected: {len(expected)}")
        sys.exit(1)
    if np.all(effective_results == expected):
        print("Files are equal!")
        return
    if np.allclose(effective_results, expected, 0, 1):
        print("Files are equal but +- 1")
        return
    if np.allclose(
        effective_results,
        expected,
        rtol=5e-2,
        atol=1e-3 * max(abs(effective_results)),
    ):
        return
    if np.allclose(
        effective_results / max(abs(effective_results)),
        expected / max(abs(expected)),
        rtol=5e-2,
    ):
        print("Files are close within 5% if normalized")
        return
    print("Files are different!")


if __name__ == "__main__":
    main()
    sys.exit(0)
