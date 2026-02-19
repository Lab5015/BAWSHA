import matplotlib.pyplot as plt
import numpy as np
from scipy.signal import freqz

coeff_2 = np.loadtxt("coeffs/coeff_filter_x2.txt")
coeff_3 = np.loadtxt("coeffs/coeff_filter_x3.txt")
coeff_5 = np.loadtxt("coeffs/coeff_filter_x5.txt")
coeff_25 = np.loadtxt("coeffs/coeff_filter_x25.txt")
coeff_100 = np.loadtxt("coeffs/coeff_filter_x100.txt")
coeff_5_strict = np.loadtxt("coeffs/coeff_filter_x5_strict.txt")

fs = 122.88e6

x, y = freqz(coeff_2, fs=fs, worN=2048)
db_y = 20 * np.log10(np.abs(y))
db_y -= max(db_y)
plt.plot(x, db_y, label="Filter 1")
fs /= 2

x1, y1 = freqz(coeff_3, fs=fs, worN=2048)
y = np.abs(y) * np.abs(y1)
db_y = 20 * np.log10(np.abs(y))
db_y -= max(db_y)
plt.plot(x1, db_y, label="Filter 2")
fs /= 3

x1, y1 = freqz(coeff_5, fs=fs, worN=2048)
y = np.abs(y) * np.abs(y1)
db_y = 20 * np.log10(np.abs(y))
db_y -= max(db_y)
plt.plot(x1, db_y, label="Filter 3")
fs /= 5

x1, y1 = freqz(coeff_5, fs=fs, worN=2048)
y = np.abs(y) * np.abs(y1)
db_y = 20 * np.log10(np.abs(y))
db_y -= max(db_y)
plt.plot(x1, db_y, label="Filter 4")
fs /= 5

x1, y1 = freqz(coeff_5, fs=fs, worN=2048)
y = np.abs(y) * np.abs(y1)
db_y = 20 * np.log10(np.abs(y))
db_y -= max(db_y)
plt.plot(x1, db_y, label="Filter 5")
fs /= 5

x1, y1 = freqz(coeff_5, fs=fs, worN=2048)
y = np.abs(y) * np.abs(y1)
db_y = 20 * np.log10(np.abs(y))
db_y -= max(db_y)
plt.plot(x1, db_y, label="Filter 6")
fs /= 5

x1, y1 = freqz(coeff_5, fs=fs, worN=2048)
y = np.abs(y) * np.abs(y1)
db_y = 20 * np.log10(np.abs(y))
db_y -= max(db_y)
plt.plot(x1, db_y, label="Filter 7")
fs /= 5

x1, y1 = freqz(coeff_5_strict, fs=fs, worN=2048)
y = np.abs(y) * np.abs(y1)
db_y = 20 * np.log10(np.abs(y))
db_y -= max(db_y)
plt.plot(x1, db_y, label="Filter 8")
fs /= 5

x1, y1 = freqz(coeff_5_strict, fs=fs, worN=2048)
y = np.abs(y) * np.abs(y1)
db_y = 20 * np.log10(np.abs(y))
db_y -= max(db_y)
plt.plot(x1, db_y, label="Filter 9")
fs /= 5

fs /= 1
print(f"\nOutput sampling: {fs} SPS")

# plt.axhline(-3, linestyle="--", color="red", label="-3 dB")

plt.grid()
plt.xscale("log")
plt.xlabel("Frequency [Hz]")
plt.ylabel("Response [dB]")
plt.title("Filtering after downconversion")

plt.legend()

# plt.xlim(0, 256)
# plt.ylim(-12, 2)

plt.axvline(30, color="black", linestyle="--")
plt.axvline(130, color="red", linestyle="--")

plt.axhline(-3, color="green", linestyle="--")
plt.axhline(-12, color="orange", linestyle="--")

plt.savefig("filters_response.pdf")
#plt.show()
