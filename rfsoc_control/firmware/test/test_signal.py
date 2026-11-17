import matplotlib.pyplot as plt
import numpy as np
from scipy.signal import lfilter


def filter_sig(signal):

    def apply_sig_dec(signal, coeffs, dec):
        signal = lfilter(coeffs, [1], signal)
        signal = np.array(signal).astype(int)[::dec]
        return signal

    coeff_2 = np.loadtxt("coeffs/coeff_filter_x2.txt")
    coeff_2 = coeff_2 / (2 ** np.log2(max(coeff_2)))
    coeff_3 = np.loadtxt("coeffs/coeff_filter_x3.txt")
    coeff_3 = coeff_3 / (2 ** np.log2(max(coeff_3)))
    coeff_5 = np.loadtxt("coeffs/coeff_filter_x5.txt")
    coeff_5 = coeff_5 / (2 ** np.log2(max(coeff_5)))
    # coeff_100 = np.loadtxt("coeff_filter_x100.txt")
    # coeff_100 = coeff_100 / (2**np.log2(max(coeff_100)))

    signal = apply_sig_dec(signal, coeff_2, 2)
    signal = apply_sig_dec(signal, coeff_3, 3)
    signal = apply_sig_dec(signal, coeff_5, 5)
    signal = apply_sig_dec(signal, coeff_5, 5)
    signal = apply_sig_dec(signal, coeff_5, 5)
    signal = apply_sig_dec(signal, coeff_5, 5)
    signal = apply_sig_dec(signal, coeff_5, 5)

    return signal


f_signal = 5.167e6
phi_sig = 0  # np.pi/3
shift = 80
error = 22
f_lockin = f_signal + shift + error
total_time = 1
final_dec = 10

video_decimation = 1

times = np.arange(0, 1, 1 / 1e8)[1:]
signal = np.cos(2 * np.pi * times * f_signal + phi_sig)
# signal = np.sin(2 * np.pi * times * f_signal) / (2 * np.pi * times)

# times = np.loadtxt("times.txt")
# signal = np.loadtxt("time_trace.txt")
# breakpoint()

i_trace = signal * np.cos(2 * np.pi * times * f_lockin)
q_trace = signal * np.sin(2 * np.pi * times * f_lockin)

total_decimation = 2 * 3 * 5 * 5 * 5 * 5 * 5 * final_dec
# total_decimation = 2 * 3 * 5
i_trace_filtered = filter_sig(i_trace)
i_trace_filtered = i_trace_filtered[::final_dec]

q_trace_filtered = filter_sig(q_trace)
q_trace_filtered = q_trace_filtered[::final_dec]

print(f"Generated {len(times)} samples")
print(f"Obtained  {len(i_trace_filtered)} samples")

_, axes = plt.subplots(2, 2, figsize=(10, 10))
axes[0][0].plot(
    times[::total_decimation][::video_decimation], i_trace_filtered[::video_decimation]
)
axes[0][0].set_title("I trace")
axes[1][0].plot(
    times[::total_decimation][::video_decimation], i_trace_filtered[::video_decimation]
)
axes[1][0].set_title("Q trace")


N = len(i_trace_filtered)
half_N = N // 2
out_fs = 1e8 / total_decimation
frequencies = np.fft.fftfreq(N, d=1 / out_fs)
frequencies = frequencies[:half_N][1:]

fft_values = np.fft.fft(i_trace_filtered)
magnitude_i = np.abs(fft_values[:half_N])[1:]

fft_values = np.fft.fft(q_trace_filtered)
magnitude_q = np.abs(fft_values[:half_N])[1:]

axes[0][1].plot(frequencies[1:], magnitude_i[1:])
axes[0][1].set_title("I fft")
axes[1][1].plot(frequencies[1:], magnitude_q[1:])
axes[1][1].set_title("Q fft")

axes[0][1].axvline(shift, linestyle="--", color="red")
axes[1][1].axvline(shift, linestyle="--", color="red")

x = 37.5 - shift
x = abs(x)
axes[0][1].axvline(x, linestyle="--", color="green")
axes[1][1].axvline(x, linestyle="--", color="green")

x = 80.5 + shift
x = abs(x)
if x > out_fs / 2:
    x = out_fs / 2 - (x - out_fs / 2)
axes[0][1].axvline(x, linestyle="--", color="green")
axes[1][1].axvline(x, linestyle="--", color="green")

# axes[0][1].set_xlim(1, 340)
# axes[1][1].set_xlim(1, 340)


magnitudes = magnitude_i[1:]
frequencies = frequencies[1:]

top_10_indices = np.argsort(magnitudes)[-10:]
top_10_frequencies = frequencies[top_10_indices]
top_10_magnitudes = magnitudes[top_10_indices]
sorted_indices = np.argsort(top_10_magnitudes)[::-1]
top_10_frequencies = top_10_frequencies[sorted_indices]
top_10_magnitudes = top_10_magnitudes[sorted_indices]
for f, m in zip(top_10_frequencies, top_10_magnitudes):
    print(f"Frequency: {f:.2f} Hz, Magnitude: {m:.2f}")

plt.show()
