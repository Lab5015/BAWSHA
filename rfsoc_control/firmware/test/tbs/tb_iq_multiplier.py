import matplotlib.pyplot as plt
import numpy as np
from tb_dds import PATH, check_equality, int_cos, to_b

SINGLE_IN_DATA_WIDTH = 16
OUT_DATA_WIDTH = 32
DEC_COUNT_WIDTH = 32
FIR_WIDTH = 16
AMP_MAX = 2**15 - 1
COS_TABLE_LEN = 10
PAC_WIDTH = 32

FS = 2e8

# hardcoded parameters, to change for testing!
NUM_SAMPLES = 10_000
INIT_FREQ = 12e6
INIT_PHASE = np.pi / 2

SIGFREQ = 12e6


def main():
    print(f"\nGenerics for .vhd:")
    print(f"\tnum_samples: {NUM_SAMPLES}")

    values = generate_stimuli(
        PATH + "stimuli.txt",
        PATH + "results.txt",
        init_freq=INIT_FREQ,
        init_phase=INIT_PHASE,
    )

    expected_results = np.loadtxt(PATH + "results.txt")
    effective_results = np.loadtxt(PATH + "effective_results.txt")

    check_equality(expected_results, effective_results)
    plot(values, effective_results)


def plot(values, effective_results):

    _, axes = plt.subplots(4, 1, figsize=(15, 8))

    adc_output = values[0]
    values_i = values[1]
    values_q = values[2]

    times = 1e6 * np.arange(len(adc_output)) / FS

    axes[0].plot(times, adc_output)
    axes[0].set_title("Input signal")
    axes[0].set_xlabel("Time [us]")

    i_len = int(NUM_SAMPLES)
    i_vals = effective_results[:i_len]
    q_vals = effective_results[i_len:]

    axes[1].plot(times, values_i, label="Expected")
    axes[1].plot(times, i_vals, label="Effective")
    axes[1].legend()
    axes[1].set_title("I component")
    axes[1].set_xlabel("Time [us]")

    axes[2].plot(times, values_q, label="Expected")
    axes[2].plot(times, q_vals, label="Effective")
    axes[2].legend()
    axes[2].set_title("Q component")
    axes[2].set_xlabel("Time [us]")

    axes[3].plot(times, np.abs(values_i - i_vals), label="I")
    axes[3].plot(times, np.abs(values_q - q_vals), label="Q")
    axes[3].legend()
    axes[3].set_title("Differences")
    # axes[3].set_ylim((-0.5, 2))
    axes[3].set_xlabel("Time [us]")

    plt.tight_layout()
    plt.show()


def generate_stimuli(
    stimul_file,
    out_filename,
    init_freq,
    init_phase,
):

    with open(stimul_file, "w") as file:

        b_init_freq = to_b(int(round(2**PAC_WIDTH * init_freq / FS)), PAC_WIDTH)
        b_init_phase = to_b(
            int(round(2**PAC_WIDTH * init_phase / (2 * np.pi))), PAC_WIDTH
        )
        b_parameters = f"{b_init_freq} {b_init_phase}\n"
        file.write(b_parameters)

    times = np.arange(NUM_SAMPLES) / FS

    i_values = int_cos(times, init_freq, FS, init_phase)
    q_values = int_cos(times, init_freq, FS, init_phase + np.pi / 2)

    signal = generate_signal()

    values_i = np.round(signal * i_values / 2**18).astype(np.int64)
    values_q = np.round(signal * q_values / 2**18).astype(np.int64)

    with open(stimul_file, "a") as file:
        for val in signal:
            file.write(to_b(int(val), SINGLE_IN_DATA_WIDTH))
            file.write("\n")

    with open(out_filename, "w") as file:

        for val in values_i:
            file.write(str(int(val)))
            file.write("\n")

        for val in values_q:
            file.write(str(int(val)))
            file.write("\n")

    return (
        signal,
        values_i,
        values_q,
    )


def generate_signal():
    zeros = np.zeros(100)
    times = np.arange(NUM_SAMPLES - 100) / FS
    signal = int_cos(times, SIGFREQ, FS) // 8
    return np.concatenate((signal, zeros))


if __name__ == "__main__":
    main()
