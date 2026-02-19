import matplotlib.pyplot as plt
import numpy as np
from scipy.signal import lfilter
from tb_dds import to_b

FS = 122.88e6
PAC_WIDTH = 32
AXI_WIDTH = 32

F0 = 10e6

DEC_FACTOR = 1
NUM_SAMPLES = 52_000
# NUM_SAMPLES =40000000
FREQ = 1e6
PHASE = 0

PATH = "/home/rodolfo/Venv/bauscia/SimBa/firmware/lockin/lockin.sim/sim_1/behav/xsim/"

np.random.seed(0)

from utils_new import generate_example_signal


def main():
    num_results = NUM_SAMPLES // (2 * 3 * 5 * 5 * 5 * 5 * 5)
    print(f"\nGenerics for .vhd:")
    print(f"\tnum_inputs: {NUM_SAMPLES}")
    print(f"\tnum_results: {num_results}")

    save_gen_inputs(PATH + "stimuli.txt", FREQ, PHASE, DEC_FACTOR, 256)

    print("Generate example signal")
    duration = NUM_SAMPLES / FS
    print("Duration: ", duration)
    total, signal = generate_example_signal(voltage=1e-4, Tduration=duration, t0=0.2)
    total = total * 2**16
    signal = signal * 2**16

    total = np.trunc(save_input(PATH + "stimuli.txt", NUM_SAMPLES, F0))
    # total = np.loadtxt("test_acq.txt")

    print("Downconvert signal")
    times = np.arange(len(total)) / FS
    I_vals = np.round(np.cos(2 * np.pi * times * FREQ + PHASE))
    Q_vals = np.round(np.cos(2 * np.pi * times * FREQ + PHASE + np.pi / 2))
    down_I = (total * I_vals).astype(int)
    down_Q = (total * Q_vals).astype(int)

    # execute downconversion and filtering
    print("Filter signal")
    out_I = filter_sig(down_I, DEC_FACTOR)
    out_Q = filter_sig(down_Q, DEC_FACTOR)

    # res = np.loadtxt(PATH + "effective_results.txt")
    # res_I = res[:num_results]
    # res_Q = res[num_results:]
    #
    # check_equality(res, np.concatenate((out_I, out_Q)))

    # plot
    _, axes = plt.subplots(5, 1, figsize=(8, 10))

    axes[0].set_title("Input signal")

    video_dec = DEC_FACTOR
    # video_dec = 10_000
    axes[0].plot(times[::video_dec], total[::video_dec], label="noise+signal")
    axes[0].plot(times[::video_dec], signal[::video_dec], color="red", label="signal")
    axes[0].legend()
    # axes[0].plot(times, total)

    axes[1].set_title("Output IQmultiplier")
    axes[1].plot(down_I[::video_dec], label="I component")
    axes[1].plot(down_Q[::video_dec], label="Q component")
    axes[1].legend()

    axes[2].set_title("Output")
    axes[2].plot(out_I, label=f"Expected I")
    axes[2].plot(out_Q, label=f"Expected Q")
    # axes[2].plot(res_I, label=f"Effective I")
    # axes[2].plot(res_Q, label=f"Effective Q")
    axes[2].legend()

    axes[3].set_title("Output Magnitude")
    exp_magnitude = np.sqrt(out_I**2 + out_Q**2)
    # eff_magnitude = np.sqrt(res_I**2 + res_Q**2)
    axes[3].plot(exp_magnitude, label=f"Expected")
    # axes[3].plot(eff_magnitude, label=f"Effective")
    axes[3].legend()

    axes[4].set_title("Differences / 1e8")
    # axes[4].plot(np.abs(out_I - res_I) / 1e8, label="Diff I")
    # axes[4].plot(np.abs(out_Q - res_Q) / 1e8, label="Diff Q")
    # axes[4].legend()

    plt.tight_layout()
    plt.show()

    # compare_results


def save_input(filename, num_samples, f0):
    noise = np.random.rand(num_samples)
    times = (
        np.concatenate(
            (
                np.zeros(25_000),
                np.arange(num_samples - 45_000),
                np.zeros(20_000),
            )
        )
        / FS
    )

    signal = np.sin(2 * np.pi * times * f0)

    total = (signal / 10 + noise) * (2**14)

    with open(filename, "a") as file:
        for el in total:
            file.write(f"{to_b(el, 16)}\n")

    return total


def save_gen_inputs(filename, freq, phase, dec_factor, num_tlast):
    with open(filename, "w") as file:
        i_freq = int(round(2**PAC_WIDTH * freq / FS))
        b_freq = to_b(i_freq, AXI_WIDTH)
        i_phase = int(round(2**PAC_WIDTH * phase / (2 * np.pi)))
        b_phase = to_b(i_phase, AXI_WIDTH)
        b_tlast = to_b(num_tlast, AXI_WIDTH)
        b_dec = to_b(dec_factor, AXI_WIDTH)

        b_parameters = f"{b_freq} {b_phase}  {b_tlast} {b_dec}\n"
        file.write(b_parameters)


def filter_sig(signal, dec_factor):

    coeffs = np.loadtxt("../coeffs/coeff_filter_x2.txt")
    coeffs = coeffs / (2 ** np.log2(max(coeffs)))
    signal = lfilter(coeffs, [1], signal)
    signal = np.array(signal).astype(int)[::2]

    coeffs = np.loadtxt("../coeffs/coeff_filter_x3.txt")
    coeffs = coeffs / (2 ** np.log2(max(coeffs)))
    signal = lfilter(coeffs, [1], signal)
    signal = np.array(signal).astype(int)[::3]

    coeffs = np.loadtxt("../coeffs/coeff_filter_x5.txt")
    coeffs = coeffs / (2 ** np.log2(max(coeffs)))
    for _ in range(5):
        signal = lfilter(coeffs, [1], signal)
        signal = np.array(signal).astype(int)[::5]

    coeffs = np.loadtxt("../coeffs/coeff_filter_x25.txt")
    coeffs = coeffs / (2 ** np.log2(max(coeffs)))
    signal = lfilter(coeffs, [1], signal)
    # signal = np.array(signal).astype(int)[::25]

    return signal[::dec_factor]


if __name__ == "__main__":
    main()
