import numpy as np
import h5py as h5
import matplotlib.pyplot as plt
from scipy.stats import linregress
from scipy.signal import savgol_filter

class Fitter:
    """
    Analysis class for SQUID V-Phi curve characterisation.

    Loads time-domain data (triangular flux drive + SQUID voltage output)
    from an HDF5 file, isolates a single flux period, locates the linear
    working point (zero-crossing of Vout), converts the x-axis to flux
    quanta (Phi_0), and performs a linear fit to extract the transfer
    function slope in V/Phi_0.

    Typical workflow::

        fit = Fitter(data_path="run.h5", date_request="2024-05-10")
        fit.get_acq_from_date()
        fit.find_monitor_crossings()   # detect periods on the drive signal
        fit.select_raise(i1=1, i2=2, i3=3, plot=True)
        fit.find_vout_zero_crossing()
        fit.flux_x_axis_conv()
        fit.linear_fit()

    Attributes:
        file_path (str)        : Path to the HDF5 data file.
        date (str)             : Acquisition date key inside the HDF5 group.
        time (np.ndarray)      : Time axis [s].
        monitor (np.ndarray)   : Triangular flux-drive voltage [V].
        squid (np.ndarray)     : SQUID output voltage [V].
        Vtri_1p (np.ndarray)   : Triangular drive for the isolated half-period.
        Vout_1p (np.ndarray)   : SQUID output for the isolated half-period.
        Vout_pp (float)        : Peak-to-peak amplitude of Vout_1p.
        Phi_ax (np.ndarray)    : Flux axis in units of Phi_0.
        x_zero_exact (float)   : Interpolated voltage at the zero-crossing [V].
        i_start (int)          : Start index of the isolated period in the full arrays.
        i_end (int)            : End index of the isolated period in the full arrays.
        period_samples (int)   : Estimated period length in samples.
        monitor_crossings (np.ndarray): Zero-crossing indices on the monitor signal.
    """

    # ------------------------------------------------------------------ #
    #  Construction                                                        #
    # ------------------------------------------------------------------ #

    def __init__(self, data_path: str):
        """
        Initialise the Fitter with a data source and target acquisition date.

        Args:
            data_path    (str): Absolute or relative path to the HDF5 file.
            date_request (str): Key of the acquisition group inside the file
                                (typically an ISO date string, e.g. "2024-05-10").
        """
        self.file_path = data_path
        #self.date = date_request

        # ---- Raw data arrays (populated by get_acq_from_date) ----
        self.time    = None   # full time axis [s]
        self.monitor = None   # triangular drive voltage [V]
        self.squid   = None   # SQUID output voltage [V]

        # ---- Derived / intermediate quantities ----
        self.Vtri_1p            = None   # triangular drive, isolated period
        self.Vout_1p            = None   # SQUID output, isolated period
        self.Vout_pp            = None   # peak-to-peak of Vout_1p
        self.x_zero_exact       = None   # interpolated voltage at zero-crossing [V]
        self.i_start            = None   # start index of isolated period (full array)
        self.i_end              = None   # end index of isolated period (full array)
        self.period_samples     = None   # estimated period in samples
        self.T_period           = None   # estimated period in drive-voltage units
        self.monitor_crossings  = None   # zero-crossing indices on the monitor signal
        self.N_periods          = None
        self.filtered           = None
        self.conversion         = None     # conversion=2000 VPhi
        self.sigma_conversion   = None     # std err on conversion=2000 VPhi
        self.i_center_crossing  = None
        self.slope              = None
        self.sigma_slope        = None
    # ------------------------------------------------------------------ #
    #  Data loading                                                        #
    # ------------------------------------------------------------------ #

    def get_acq_from_date(self):
        """
        Load time, flux-drive (monitor), and SQUID-output arrays from the HDF5 file.

        Expects the following datasets inside the requested date group:
            * ``Time``  – time axis
            * ``Flux``  – triangular drive voltage (monitor)
            * ``Volt``  – SQUID output voltage

        Raises:
            ValueError: If ``file_path`` has not been set.
            KeyError:   If the requested date group is not found in the file.
        """
        if self.file_path is None:
            raise ValueError("No data path set. Pass a valid file path to the constructor.")

        with h5.File(self.file_path, "r") as f:
            if self.date not in f:
                raise KeyError(f"Date group '{self.date}' not found in {self.file_path}.")

            group = f[self.date]
            print(f"Loading group '{self.date}':")
            for data_name, ds in group.items():
                print(f"    |- {data_name}: shape={ds.shape}, dtype={ds.dtype}")

            self.time    = group["Time"][:]
            self.monitor = group["Flux"][:]
            self.squid   = group["Volt"][:]

    def get_last_acq(self):
        """
        Load time, flux-drive (monitor), and SQUID-output arrays from the last
        group in the HDF5 file.

        Raises:
            ValueError: If ``file_path`` has not been set.
            ValueError: If no groups are found in the file.
        """
        if self.file_path is None:
            raise ValueError("No data path set. Pass a valid file path to the constructor.")

        with h5.File(self.file_path, "r") as f:
            groups = list(f.keys())
            if not groups:
                raise ValueError(f"No groups found in {self.file_path}.")

            last_group = groups[-1]
            group = f[last_group]

            print(f"Loading last group '{last_group}':")
            for data_name, ds in group.items():
                print(f"    |- {data_name}: shape={ds.shape}, dtype={ds.dtype}")

            self.time    = group["Time"][:]
            self.monitor = group["Flux"][:]        ########!!!!!!!
            self.squid   = group["Volt"][:]

    # ------------------------------------------------------------------ #
    #  Period detection on the drive signal                               #
    # ------------------------------------------------------------------ #
    '''
    def find_monitor_crossings(self, min_distance: int = None):
        """
        Detect zero-crossings (rising edges) of the triangular *monitor* signal
        and use them to estimate the drive period.

        This must be called before ``select_raise`` so that period boundaries
        are available.  It operates exclusively on ``self.monitor``.

        Args:
            min_distance (int): Minimum gap in samples between accepted crossings.
                                Defaults to 80 % of the mean inter-crossing distance.

        Sets:
            monitor_crossings, period_samples, T_period, N_periods

        Raises:
            RuntimeError: If ``monitor`` has not been loaded yet.
        """
        if self.monitor is None:
            raise RuntimeError("No data loaded. Call get_acq_from_date() or get_last_acq() first.")

        signs      = np.sign(self.monitor)
  
        rising_idx = np.where(np.diff(signs) < 0)[0]
    
        if len(rising_idx) < 2:
            raise RuntimeError("Fewer than two rising zero-crossings found in monitor signal.")

        if min_distance is None:
            min_distance = int(np.mean(np.diff(rising_idx)) * 0.8)

        filtered = [rising_idx[0]]
        for idx in rising_idx[1:]:
            if idx - filtered[-1] > min_distance:
                filtered.append(idx)

        self.monitor_crossings = np.array(filtered)
        self.N_periods = (len(self.monitor_crossings) - 3) // 2
        
        print(f'Periodi disponibili   : {self.N_periods}')
        print(f'Zero-crossing trovati : {len(filtered)}')'''




    def find_monitor_crossings(self,
                            min_distance: int = None,
                            smooth_window: int = 11,
                            threshold: float = 0.0,
                            hysteresis: float = None):

        """
        Robust rising-edge detection for triangular monitor signals.
        """

        if self.monitor is None:
            raise RuntimeError(
                "No data loaded. Call get_acq_from_date() or get_last_acq() first."
            )

        # ---------------------------------------------------------
        # Smooth signal
        # ---------------------------------------------------------
        monitor = savgol_filter(
            self.monitor,
            window_length=smooth_window,
            polyorder=2
        )

        # ---------------------------------------------------------
        # Automatic hysteresis
        # ---------------------------------------------------------
        if hysteresis is None:
            hysteresis = 0.02 * np.std(monitor)

        low_thr  = threshold - hysteresis
        high_thr = threshold + hysteresis

        # ---------------------------------------------------------
        # Schmitt-trigger style crossing detection
        # ---------------------------------------------------------
        rising_idx = []

        armed = False

        for i in range(len(monitor) - 1):

            # signal sufficiently below threshold
            if monitor[i] < low_thr:
                armed = True

            # detect crossing only after arming
            if armed and monitor[i + 1] >= high_thr:

                rising_idx.append(i)

                armed = False

        rising_idx = np.array(rising_idx)

        if len(rising_idx) < 2:
            raise RuntimeError(
                "Fewer than two rising zero-crossings found."
            )

        # ---------------------------------------------------------
        # Automatic minimum distance
        # ---------------------------------------------------------
        if min_distance is None:

            rough_period = np.median(np.diff(rising_idx))

            min_distance = int(0.5 * rough_period)

        # ---------------------------------------------------------
        # Remove duplicate detections
        # ---------------------------------------------------------
        filtered = [rising_idx[0]]

        for idx in rising_idx[1:]:

            if idx - filtered[-1] > min_distance:
                filtered.append(idx)

        self.monitor_crossings = np.array(filtered)

        # ---------------------------------------------------------
        # Period estimate
        # ---------------------------------------------------------
        periods = np.diff(self.monitor_crossings)

        self.period_samples = int(np.median(periods))

        self.N_periods = len(periods)

        print(f"Available periods     : {self.N_periods}")
        print(f"Crossings found       : {len(filtered)}")
        print(f"Mean period [samples] : {self.period_samples}")
    # ------------------------------------------------------------------ #
    #  Helpers                                                             #
    # ------------------------------------------------------------------ #

    @staticmethod
    def midpoint(a: int, b: int) -> float:
        """Return the midpoint between two sample indices."""
        return (a + b) / 2.0

    def _is_ascending(self, segment: np.ndarray) -> bool:
        """
        Return True if the segment starts on the rising flank of the
        triangular drive (positive slope at the beginning).

        Uses the median derivative of the first quarter of the segment
        to be robust against noise.
        """
        quarter = max(1, len(segment) // 4)
        return np.median(np.diff(segment[:quarter])) > 0

    # ------------------------------------------------------------------ #
    #  Isolate one period                                                  #
    # ------------------------------------------------------------------ #

    def select_raise(self, i1: int = 1, i2: int = 2, i3: int = 3, plot: bool = True, first: bool = False, second: bool = False, third: bool=False):
        """
        Isolate one full period of the triangular flux drive centred on a peak.

        ``find_monitor_crossings()`` must be called before this method so that
        ``monitor_crossings`` is populated.

        Args:
            i1, i2, i3 (int): Indices *into* ``monitor_crossings`` (not raw
                              sample indices) that identify three consecutive
                              zero-crossings.  The period is cut from
                              midpoint(crossings[i1], crossings[i2]) to
                              midpoint(crossings[i2], crossings[i3]).
            plot (bool): If True, show a diagnostic plot. Defaults to True.

        Sets:
            i_start, i_end, Vtri_1p, Vout_1p, Vout_pp

        Raises:
            RuntimeError: If ``find_monitor_crossings()`` has not been called.
        """
        if self.monitor_crossings is None:
            raise RuntimeError(
                "No monitor crossings available. Call find_monitor_crossings() first."
            )

        crossings = self.monitor_crossings
        if first:
            self.i_start = int(np.floor(self.midpoint(crossings[i1], crossings[i2])) - (crossings[i2] - crossings[i1]))
            self.i_end   = int(np.floor(self.midpoint(crossings[i2], crossings[i3])) - (crossings[i2] - crossings[i1]))
        elif second:
            self.i_start = int(np.floor(self.midpoint(crossings[i1], crossings[i2])))
            self.i_end   = int(np.floor(self.midpoint(crossings[i2], crossings[i3])))
        elif third:
            self.i_start = int(np.floor(self.midpoint(crossings[i1], crossings[i2])) + (crossings[i2] - crossings[i1]))
            self.i_end   = int(np.floor(self.midpoint(crossings[i2], crossings[i3])) + (crossings[i2] - crossings[i1]))
        else:
            self.i_start = int(np.floor(self.midpoint(crossings[i1], crossings[i2])))
            self.i_end   = int(np.floor(self.midpoint(crossings[i2], crossings[i3])))

        self.Vtri_1p = self.monitor[self.i_start:self.i_end]
        self.Vout_1p = self.squid[self.i_start:self.i_end]
        self.Time_1p = self.time[self.i_start:self.i_end]
        self.Vout_pp = float(np.ptp(self.Vout_1p)) 

        if plot:
            fig, ax = plt.subplots(figsize=(10, 4))
            ax.plot(self.time, self.monitor, label="Vtri (drive)", alpha=0.6)
            ax.scatter(
                self.time[crossings], self.monitor[crossings],
                color="red", zorder=5, s=20, label="Zero-crossings",
            )
            ax.plot(
                self.time[self.i_start:self.i_end], self.monitor[self.i_start:self.i_end],
                color="green", lw=2, label="Isolated period",
            )
            ax.plot(
                self.time[self.i_start:self.i_end], self.squid[self.i_start:self.i_end],
                color="orange", lw=2, label="SQUID output",
            )
            ax.set_xlabel("Time (s)")
            ax.set_ylabel("Voltage (V)")
            ax.set_title("Triangular drive — period selection")
            ax.legend()
            ax.grid(True, alpha=0.3)
            plt.tight_layout()
            plt.show()

    # ------------------------------------------------------------------ #
    #  Zero-crossing of Vout                                              #
    # ------------------------------------------------------------------ #

    '''def find_squid_crossings(self, min_distance: int = None):
        """
        Detect zero-crossings (rising edges) of the squid output signal
        and use them to estimate the period.

        Args:
            min_distance (int): Minimum gap in samples between accepted crossings.
                                Defaults to 80 % of the mean inter-crossing distance.

        Sets:
            monitor_crossings, period_samples, T_period, N_periods

        Raises:
            RuntimeError: If ``monitor`` has not been loaded yet.
        """
        if self.monitor is None:
            raise RuntimeError("No data loaded. Call get_acq_from_date() or get_last_acq() first.")

        signs      = np.sign(self.squid)
        rising_idx = np.where(np.diff(signs) > 0)[0]

        if len(rising_idx) < 2:
            raise RuntimeError("Fewer than two rising zero-crossings found in monitor signal.")

        if min_distance is None:
            min_distance = int(np.mean(np.diff(rising_idx)) * 0.8)

        self.filtered = [rising_idx[0]]
        for idx in rising_idx[1:]:
            if idx - self.filtered[-1] > min_distance:
                self.filtered.append(idx)

        self.T_period = self.Time_1p[self.filtered[2]] - self.Time_1p[self.filtered[1]]
        self.period_samples = self.filtered[2] - self.filtered[1]'''
    
    '''def find_squid_crossings(self, min_period_ms: float = 8.0, max_period_ms: float = 11.0):
        """
        Estimate the SQUID period anchored on the rising crossing closest to the
        center of the selected window.

        Only crossing pairs whose separation falls within [min_period_ms, max_period_ms]
        are considered valid. Tries forward offsets 1, 2, 3 until a valid and
        consistent pair is found.

        Args:
            min_period_ms (float): Hard lower bound on the period in ms. Default 8.0.
            max_period_ms (float): Hard upper bound on the period in ms. Default 11.0.
        """
        if self.Vout_1p is None:
            raise RuntimeError("No period selected. Call select_raise() first.")

        signs = np.sign(self.Vout_1p)
        signs[signs == 0] = 1
        diffs = np.diff(signs)
        rising = np.where(diffs > 0)[0]

        if len(rising) < 2:
            raise RuntimeError("Fewer than two rising zero-crossings found in Vout_1p.")

        # --- Noise guard --------------------------------------------------
        min_samples = int(0.05 * self.period_samples)
        filtered = [rising[0]]
        for idx in rising[1:]:
            if idx - filtered[-1] > min_samples:
                filtered.append(idx)
        filtered = np.array(filtered)
        self.filtered = filtered

        if len(filtered) < 2:
            raise RuntimeError("Fewer than two rising crossings after noise filtering.")

        min_period_s = min_period_ms * 1e-3
        max_period_s = max_period_ms * 1e-3

        # --- Anchor: crossing closest to center of window -----------------
        center     = len(self.Vout_1p) // 2
        anchor_pos = int(np.argmin(np.abs(filtered - center)))
        i_center   = filtered[anchor_pos]

        # --- Find valid backward period -----------------------------------
        T_backward   = None
        i_prev_used  = None
        for offset in range(1, anchor_pos + 1):
            i_candidate = filtered[anchor_pos - offset]
            T_candidate = self.Time_1p[i_center] - self.Time_1p[i_candidate]
            if min_period_s <= T_candidate <= max_period_s:
                T_backward  = T_candidate
                i_prev_used = i_candidate
                if offset > 1:
                    print(f"NOTE: skipped {offset-1} spurious crossing(s) before anchor, "
                        f"used offset={offset} for backward period.")
                break
            else:
                print(f"Backward offset={offset}: T={T_candidate*1e3:.4f} ms out of "
                    f"[{min_period_ms}, {max_period_ms}] ms, skipping.")

        if T_backward is None:
            raise RuntimeError(
                f"Could not find a valid backward period in "
                f"[{min_period_ms}, {max_period_ms}] ms. Check signal or bounds."
            )

        # --- Find valid forward period ------------------------------------
        T_forward   = None
        i_next_used = None
        for offset in range(1, len(filtered) - anchor_pos):
            i_candidate = filtered[anchor_pos + offset]
            T_candidate = self.Time_1p[i_candidate] - self.Time_1p[i_center]
            if not (min_period_s <= T_candidate <= max_period_s):
                print(f"Forward offset={offset}: T={T_candidate*1e3:.4f} ms out of "
                    f"[{min_period_ms}, {max_period_ms}] ms, skipping.")
                continue
            disc = abs(T_candidate - T_backward) / max(T_candidate, T_backward)
            if disc <= 0.10:
                T_forward   = T_candidate
                i_next_used = i_candidate
                if offset > 1:
                    print(f"NOTE: skipped {offset-1} spurious crossing(s) after anchor, "
                        f"used offset={offset} for forward period.")
                break
            else:
                print(f"Forward offset={offset}: T={T_candidate*1e3:.4f} ms consistent "
                    f"check failed ({disc*100:.1f}% > 10%), skipping.")

        if T_forward is None:
            raise RuntimeError(
                f"Could not find a consistent forward period in "
                f"[{min_period_ms}, {max_period_ms}] ms. "
                f"T_backward = {T_backward*1e3:.4f} ms. Check signal quality."
            )

        # --- Final period -------------------------------------------------
        disc_final = abs(T_forward - T_backward) / max(T_forward, T_backward)
        self.T_period          = (T_forward + T_backward) / 2.0
        self.period_samples    = int(((i_next_used - i_center) + (i_center - i_prev_used)) / 2.0)
        self.i_center_crossing = i_center

        print(f"Anchor crossing       : index {i_center}, t = {self.Time_1p[i_center]:.6f} s")
        print(f"T_backward [ms]       : {T_backward*1e3:.4f}")
        print(f"T_forward  [ms]       : {T_forward*1e3:.4f}")
        print(f"Consistency           : {disc_final*100:.2f}% difference")
        print(f"T_period   [ms]       : {self.T_period*1e3:.4f}")'''
    
    def find_squid_crossings(self, min_period_ms=9.0, max_period_ms=10.0):
        if self.Vout_1p is None:
            raise RuntimeError("Call select_raise() first.")
        y, t = self.Vout_1p, self.Time_1p
        idx = np.where(np.diff(np.signbit(y)))[0]
        if len(idx) < 2:
            raise RuntimeError("Too few SQUID crossings.")
        tcross = t[idx] - y[idx] * (t[idx+1] - t[idx]) / (y[idx+1] - y[idx])
        rising = (y[idx+1] - y[idx]) > 0
        # enforce strictly alternating, anchored to first rising crossing
        first_rising = np.argmax(rising)          # index of first true rising
        idx, tcross, rising = idx[first_rising:], tcross[first_rising:], rising[first_rising:]
        keep = [0]
        for i in range(1, len(idx)):
            if rising[i] != rising[keep[-1]]:
                keep.append(i)
        idx, tcross, rising = idx[keep], tcross[keep], rising[keep]
        idx_rise, tcross_rise = idx[rising], tcross[rising]
        if len(idx_rise) < 2:
            raise RuntimeError("Too few rising crossings.")
        T_all = np.diff(tcross_rise)
        med = np.median(T_all)
        mad = np.median(np.abs(T_all - med))
        T = T_all[np.abs(T_all - med) < 3 * mad]
        T = T[(T > min_period_ms*1e-3) & (T < max_period_ms*1e-3)]
        if len(T) == 0:
            raise RuntimeError("No valid SQUID period found.")
        m = self.monitor_crossings[
            (self.monitor_crossings >= self.i_start) &
            (self.monitor_crossings < self.i_end)
        ] - self.i_start
        i_mon = m[np.argmin(np.abs(m - len(y) // 2))]
        i_anchor = np.argmin(np.abs(idx_rise - i_mon))
        self.i_center_crossing = idx_rise[i_anchor]
        self.filtered = idx_rise
        self.T_period = np.median(T)
        self.period_samples = int(round(self.T_period / np.median(np.diff(t))))
        print(f"Anchor crossing : {t[self.i_center_crossing]*1e3:.3f} ms")
        print(f"SQUID period    : {self.T_period*1e3:.3f} ms")
            
    def plot_period(self, show_period: bool = True):
        if self.Vout_1p is None or self.Vtri_1p is None:
            raise RuntimeError("No period selected. Call select_raise() first.")

        fig, ax = plt.subplots(figsize=(12, 5))
        ax.plot(self.Time_1p, self.Vtri_1p, label="Vtri (drive)", alpha=0.7)
        ax.plot(self.Time_1p, self.Vout_1p, label="Vout (SQUID)", alpha=0.7)

        # --- Zero-crossing from find_vout_zero_crossing -------------------
        if self.x_zero_exact is not None:
            ax.axvline(self.x_zero_exact, color="orange", lw=1.2, ls=":",
                    label=f"Vout zero-crossing ({self.x_zero_exact*1e3:.3f} ms)")

        # --- Detected SQUID crossings with time labels --------------------
        if self.filtered is not None:
            crossing_times = self.Time_1p[self.filtered]
            crossing_vals  = self.Vout_1p[self.filtered]
            ax.scatter(crossing_times, crossing_vals,
                    color="red", zorder=5, s=30, label="SQUID crossings")

            for t_c, v_c in zip(crossing_times, crossing_vals):
                ax.annotate(f"{t_c*1e3:.3f} ms",
                            xy=(t_c, v_c),
                            xytext=(4, 6),
                            textcoords="offset points",
                            fontsize=7,
                            color="red",
                            rotation=45)

        # --- Anchor crossing (center) highlighted separately --------------
        if self.i_center_crossing is not None:
            t_anchor = self.Time_1p[self.i_center_crossing]
            v_anchor = self.Vout_1p[self.i_center_crossing]
            ax.scatter([t_anchor], [v_anchor],
                    color="blue", zorder=6, s=60, marker="D",
                    label=f"Anchor ({t_anchor*1e3:.3f} ms)")

        # --- Period tick lines anchored to center crossing ----------------
        if show_period and self.T_period is not None and self.i_center_crossing is not None:
            t_start  = self.Time_1p[0]
            t_end    = self.Time_1p[-1]
            t_anchor = self.Time_1p[self.i_center_crossing]

            ticks = []
            t = t_anchor
            while t <= t_end:
                ticks.append(t)
                t += self.T_period
            t = t_anchor - self.T_period
            while t >= t_start:
                ticks.append(t)
                t -= self.T_period

            for i, t in enumerate(sorted(ticks)):
                ax.axvline(t, color="green", lw=1.0, ls="--",
                        label=f"T_period = {self.T_period*1e3:.3f} ms" if i == 0 else None)

        ax.axhline(0, color="k", lw=0.8, ls="--")
        ax.set_xlabel("Time (s)")
        ax.set_ylabel("Voltage (V)")
        ax.set_title("Isolated period")
        ax.legend(fontsize=8)
        ax.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.show()

    def find_vout_zero_crossing(self, verbose=0):
        """
        Find the zero-crossing of Vout (SQUID output) within the selected period
        and compute the exact crossing voltage on the Vtri axis via linear
        interpolation.

        Raises:
            RuntimeError: If ``select_raise()`` has not been called first.
            RuntimeError: If no zero-crossing is found in Vout_1p.

        Sets:
            x_zero_exact
        """
        if self.Vout_1p is None:
            raise RuntimeError("No period selected. Call select_raise() first.")

        sign_changes = np.where(np.diff(np.sign(self.Vout_1p)))[0]
        if len(sign_changes) == 0:
            raise RuntimeError("No zero-crossing found in Vout_1p.")

        idx = sign_changes[0]
        x0, x1            = self.Time_1p[idx], self.Time_1p[idx + 1]
        y0, y1            = self.Vout_1p[idx], self.Vout_1p[idx + 1]
        self.x_zero_exact = x0 - y0 * (x1 - x0) / (y1 - y0)

        if verbose==1:
            print(f"Vout zero-crossing at Vtri = {self.x_zero_exact:.6f} V")

    # ------------------------------------------------------------------ #
    #  Linear fit and final plot                                           #
    # ------------------------------------------------------------------ #

    def linear_fit(self, n_pts: int = None, diagnostic_plot: bool = True, verbose=0):
        """
        Fit a line to Vout vs Phi_0 in a symmetric window around the zero-crossing.

        The fit window spans ±n_pts samples around the zero-crossing index.
        If n_pts is None, defaults to ~2.5 % of the period (minimum 3 samples).
        Symmetry is enforced so that the fit is not biased toward either flank.

        Args:
            n_pts (int): Half-width of the fit window in samples. If None,
                         estimated automatically from the period.
            diagnostic_plot (bool): If True, produce a two-panel figure.

        Prints a summary of the fit results.

        Raises:
            RuntimeError: If ``flux_x_axis_conv()`` has not been called first.

        Sets:
            slope, intercept, r_squared, std_err
        """

        # -- Locate the zero-crossing index in Vtri_1p --------------------
        i_zero = int(np.argmin(np.abs(self.Time_1p - self.x_zero_exact)))
        mask = (self.monitor_crossings >= self.i_start) & (self.monitor_crossings < self.i_end)
        crossings_in_period = self.monitor_crossings[mask]
        if len(crossings_in_period) == 1:
            i_zero = int(crossings_in_period[0] - self.i_start)
            print("Crossing index", i_zero)
        if len(crossings_in_period) > 1:
            print("Mistake with evaluation of zero crossing index")
        # -- Symmetric fit window -----------------------------------------
        if n_pts is None:
            n_pts = max(3, int(self.period_samples) // 40)

        n_left  = min(n_pts, i_zero)
        n_right = min(n_pts, len(self.Vout_1p) - 1 - i_zero)
        N_sym   = min(n_left, n_right)
        print("Nsym ", N_sym)
        i_lo = i_zero - N_sym
        i_hi = i_zero + N_sym

        x_fit = self.Time_1p[i_lo : i_hi + 1]
        y_fit = self.Vout_1p[i_lo : i_hi + 1]

        if verbose==1:
            print(f"Fit window: ±{N_sym} samples around time {self.time[i_zero]:.1f} "
              f"(total {2 * N_sym + 1} pts out of {int(self.period_samples)})")

        # -- Linear regression --------------------------------------------
        '''slope, intercept, r_value, _, std_err = linregress(x_fit, y_fit)
        self.slope     = slope * self.T_period
        self.intercept = intercept
        self.r_squared = r_value ** 2
        self.std_err   = std_err'''
        
        p, cov = np.polyfit(x_fit, y_fit, 1, cov=True)
        # Estrazione dei parametri
        slope = p[0]
        intercept = p[1]

        # Calcolo degli errori standard (radice quadrata della diagonale)
        slope_uncertainty = np.sqrt(cov[0, 0])
        intercept_uncertainty = np.sqrt(cov[1, 1])

        self.slope = slope
        self.sigma_slope = slope_uncertainty
        self.conversion = slope * self.T_period
        self.sigma_conversion = slope_uncertainty * self.T_period
        self.intercept = intercept
        self.sigma_slope = slope_uncertainty

        if verbose ==1 :

            print("\n── Fit results ──────────────────────────────────────────")
            print(f"  Points used   : {len(x_fit)}  (indices {i_lo}:{i_hi})")
            print(f"  Intercept     : {intercept:.6f} V")
            #print(f"  R²            : {self.r_squared:.6f}")
            #print(f"  Std err slope : {self.sigma_slope:.4f} V/Phi_0")
            print(f"  Period [s]    : {self.T_period:.4f} ")
            print(f"  2000 Vphi      : {self.conversion} V / Phi0 ± {self.sigma_conversion}")
        if diagnostic_plot: 
            fig, axes = plt.subplots(1, 2, figsize=(13, 5))

            # Left: full time-series
            ax = axes[0]
            ax.plot(self.time, self.monitor, label="Vtri (drive)", alpha=0.7)
            ax.plot(self.time, self.squid,   label="Vout SQUID",   alpha=0.7)
            ax.scatter(self.time[self.monitor_crossings], self.squid[self.monitor_crossings], c='r', marker='.', label='Working point' )
            ax.axvspan(
                self.time[self.i_start], self.time[self.i_end],
                color="yellow", alpha=0.3, label="Isolated period",
            )
            ax.set_xlabel("Time (s)")
            ax.set_ylabel("Voltage (V)")
            ax.set_title("Full time-series")
            ax.legend(fontsize=8)
            ax.grid(True, alpha=0.3)

            # Right: V-Phi with fit
            ax = axes[1]
            #ax.scatter(self.Time_1p, self.Vout_1p, marker=".", color="navy", label="V-Phi (1 period)")
            ax.scatter(self.Time_1p, self.monitor[self.i_start:self.i_end], marker='.', color='blue', label="monitor [V]" )

            ax.axhline(0, color="k",      lw=0.8, ls="--")
            ax.axvline(self.x_zero_exact, color="orange", lw=1.2, ls=":", label="Zero-crossing")
            ax.plot(x_fit, y_fit, color="orange", ms=6, lw=2,
                    label=f"Fit window (±{N_sym} pts)")

            x_line = np.linspace(x_fit[0], x_fit[-1], 300)
            ax.plot(x_line, slope * x_line + intercept, "k-", lw=1, alpha=0.5,
                    label=f"Fit: {slope * self.T_period:.3f} ± {slope_uncertainty*self.T_period:.4f} V/Phi_0  ")
            ax.set_xlabel("time [s]")
            ax.set_ylabel("SQUID output (V)")
            ax.set_title("V-Phi curve — linear fit at zero-crossing")
            ax.legend(fontsize=8)
            ax.grid(True, alpha=0.3)
            ax.set_xlim(x_fit[0], x_fit[-1])

            plt.tight_layout()
            plt.show()

    # --------------------------------
    # MULTI-PERIOD FIT    
    # --------------------------------
    
    def plot_fit_results(self, slopes, intercepts, r_squared, std_errs):
        """
        Plot estimated slopes and intercepts with error bars over periods.

        Args:
            slopes     (np.ndarray): Slope of each fit [V/Phi_0].
            intercepts (np.ndarray): Intercept of each fit [V].
            r_squared  (np.ndarray): R² of each fit.
            std_errs   (np.ndarray): Standard error on each slope.
        """
        periods = np.arange(1, len(slopes) + 1)

        weights    = 1.0 / std_errs**2
        mean_slope = np.sum(weights * slopes) / np.sum(weights)
        std_slope  = 1.0 / np.sqrt(np.sum(weights))

        fig, axes = plt.subplots(1, 2, figsize=(16, 5))

        # -- Slope vs period ----------------------------------------------
        ax = axes[0]
        ax.errorbar(periods, slopes, yerr=std_errs,
                    fmt='o', color='steelblue', markersize=4,
                    capsize=3, elinewidth=0.8, alpha=0.8,
                    label='Slope per period')
        ax.axhline(mean_slope, color='red', lw=2,
                label=f'Weighted mean = {mean_slope:.4f} V/Phi_0')
        ax.fill_between(periods,
                        mean_slope - std_slope,
                        mean_slope + std_slope,
                        color='red', alpha=0.15,
                        label=f'±1σ = {std_slope:.4f} V/Phi_0')
        ax.set_xlabel('Period number')
        ax.set_ylabel('Slope (V/Phi_0)')
        ax.set_title('Slope vs period')
        ax.legend(fontsize=8)
        ax.grid(True, alpha=0.3)

        # -- R² vs period -------------------------------------------------
        ax = axes[1]
        ax.plot(periods, r_squared, 'o-', color='seagreen',
                markersize=4, lw=0.8, label='R² per period')
        ax.axhline(np.mean(r_squared), color='red', lw=2,
                label=f'Mean R² = {np.mean(r_squared):.4f}')
        ax.set_ylim(0, 1.05)
        ax.set_xlabel('Period number')
        ax.set_ylabel('R²')
        ax.set_title('Goodness of fit vs period')
        ax.legend(fontsize=8)
        ax.grid(True, alpha=0.3)

        plt.suptitle(
            f'Multi-period fit summary — {len(slopes)} periods  |  '
            f'Weighted mean slope: {mean_slope:.4f} ± {std_slope:.4f} V/Phi_0',
            fontsize=11, y=1.02
        )
        plt.tight_layout()
        plt.show()

        print(f"\n── Weighted fit summary ─────────────────────────────────")
        print(f"  Periods fitted       : {len(slopes)}")
        print(f"  Weighted mean slope  : {mean_slope:.4f} V/Phi_0")
        print(f"  Weighted std slope   : {std_slope:.4f} V/Phi_0")
    