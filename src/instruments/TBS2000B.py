import time
import numpy as np
import pyvisa


class TBS2000B:
    """
    Instrument driver for the Tektronix TBS2000B oscilloscope.

    Connects via TCP/IP socket (LAN interface) using pyvisa-py as the backend.
    Provides methods to configure acquisition parameters, set vertical/horizontal
    scales, and read waveform data from CH1 and CH2.

    Connection defaults:
        IP   : 100.100.100.2
        Port : 4000
        Proto: SOCKET (raw TCP)

    Example:
        >>> scope = TBS2000B()
        >>> result = scope.acquire_single_curve(desired_rate=20000, record_length=2000)
        >>> scope.close()
    """

    # ------------------------------------------------------------------ #
    #  Construction / teardown                                            #
    # ------------------------------------------------------------------ #

    def __init__(self):
        """Open the VISA resource and configure default communication settings."""
        rm = pyvisa.ResourceManager('@py')
        self.instr = rm.open_resource('TCPIP::100.100.100.3::4000::SOCKET')

        # Newline terminators are required by the TBS2000B socket interface
        self.instr.read_termination  = '\n'
        self.instr.write_termination = '\n'

        print(self.instr.query("*IDN?"), "connected")

        # Request ASCII-encoded waveform output (human-readable, easier to parse)
        self.instr.write("WFMOutpre:ENCdg ASCii")

        # ---- Internal state ------------------------------------------ #
        self._AVG = 0           # Number of averages (0 = averaging disabled)
        self._SR  = int(1e3)    # Sample rate  [S/s]
        self._HS  = 1e-3        # Horizontal time scale  [s/div]
        self._RL  = int(1e4)    # Record length  [samples]
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        return False  # non sopprime le eccezioni
        
    def clear(self):
        """Clear all buffered data"""
        self.instr.clear()

    def close(self):
        """Release the VISA resource."""
        self.instr.close()

    # ------------------------------------------------------------------ #
    #  Low-level wrappers                                                 #
    # ------------------------------------------------------------------ #

    def query(self, command: str) -> str:
        """Send *command* and return the instrument's response as a string."""
        return self.instr.query(command)

    def write(self, command: str):
        """Send *command* without waiting for a response."""
        return self.instr.write(command)

    # ------------------------------------------------------------------ #
    #  Vertical scale helpers                                             #
    # ------------------------------------------------------------------ #

    def set_vertical_scale(self, channel: int, scale: float, offset: float = 0.0):
        """
        Set the vertical scale and offset for a single channel.

        Args:
            channel (int): Channel number (1 or 2).
            scale   (float): Vertical scale in V/div.
            offset  (float): Vertical offset in V. Defaults to 0.
        """
        ch = f"CH{channel}"
        self.instr.write(f"{ch}:SCALE {scale:.6f}")
        self.instr.write(f"{ch}:OFFSET {offset:.6f}")

    def reset_vertical_scale(self, sources: list = None):
        """
        Reset vertical scale and offset to safe defaults (1 V/div, 0 V offset).

        Args:
            sources (list): List of channel strings, e.g. ["CH1", "CH2"].
                            Defaults to both channels.
        """
        if sources is None:
            sources = ["CH1", "CH2"]
        for source in sources:
            self.instr.write(f"{source}:SCALE 1.0")
            self.instr.write(f"{source}:OFFSET 0.0")
            print(f"{source}: scale reset to 1.0 V/div, offset reset to 0.0 V")

    def autoscale_vertical(self, sources: list = None, margin: float = 1.2):
        """
        Auto-scale the vertical axis based on a previously acquired waveform.

        Reads the current raw curve from each channel, computes the actual
        voltage range, and adjusts SCALE and OFFSET so the signal fits on
        screen with *margin* headroom.

        Args:
            sources (list) : Channels to rescale. Defaults to ["CH1", "CH2"].
            margin  (float): Multiplicative headroom factor (e.g. 1.2 = 20 %).

        Note:
            If the waveform is already clipping, the rescaling will be
            inaccurate. Start with a wide scale before calling this method.
        """
        if sources is None:
            sources = ["CH1", "CH2"]

        for source in sources:
            self.instr.write(f"DATA:SOURCE {source}")

            raw  = self.instr.query("CURVe?")
            data = np.array([float(x) for x in raw.split(",")])

            yzero = float(self.instr.query("WFMOutpre:YZERo?"))
            ymult = float(self.instr.query("WFMOutpre:YMUlt?"))
            yoff  = float(self.instr.query("WFMOutpre:YOFf?"))
            volts = (data - yoff) * ymult + yzero

            vmax   = np.max(volts)
            vmin   = np.min(volts)
            vmid   = (vmax + vmin) / 2.0
            vrange = (vmax - vmin) * margin

            # TBS2000B has 8 vertical divisions
            new_scale = vrange / 8.0

            self.instr.write(f"{source}:OFFSET {-vmid:.4f}")
            self.instr.write(f"{source}:SCALE  {new_scale:.4f}")

            print(
                f"{source}: min={vmin:.3f} V  max={vmax:.3f} V  "
                f"-> scale={new_scale:.4f} V/div  offset={-vmid:.4f} V"
            )

    # ------------------------------------------------------------------ #
    #  Acquisition helpers                                                #
    # ------------------------------------------------------------------ #

    def set_average_mode(self, n_avg: int = 16):
        """
        Switch to average acquisition mode.

        Args:
            n_avg (int): Number of waveforms to average. Defaults to 16.
        """
        self.instr.write("ACQuire:MODe AVERage")
        self.AVG = n_avg

    def set_source(self, ch: int):
        """
        Set the active data source channel.

        Args:
            ch (int): Channel number (1 or 2).
        """
        self.instr.write(f"DATa:SOUrce CH{ch}")

    def get_wf(self) -> str:
        """
        Request the current waveform curve from the active source.

        Returns:
            str: Raw comma-separated ASCII values from the instrument.
        """
        return self.instr.query("CURV?")

    # ------------------------------------------------------------------ #
    #  Core acquisition methods  (DO NOT MODIFY)                         #
    # ------------------------------------------------------------------ #

    def set_samplerate(self, desired_rate: float, record_length: int, div: int = 16):
        """
        Set the oscilloscope's record length and horizontal scale to target a sample rate.
        Returns the actual achievable sample rate.

        Parameters:
            desired_rate  (float): Target sample rate in S/s.
            record_length (int)  : Number of points in the record.
            div           (int)  : Number of horizontal divisions (TBS2000B default: 15).

        Returns:
            tuple: (actual_rate [S/s], actual_record_length [samples])
        """
        self.instr.write(f"HOR:RECO {record_length}")
        time_scale = (record_length / desired_rate) / div
        self.instr.write(f"HOR:SCALE {time_scale}")

        actual_record_length = float(self.instr.query("HOR:RECO?"))
        actual_time_scale    = float(self.instr.query("HOR:SCALE?"))
        xincr                = float(self.instr.query("WFMPRE:XINCR?"))  # s/sample

        actual_rate = actual_record_length / (div * actual_time_scale)

        print(f"Requested rate:          {desired_rate} S/s")
        print(f"Actual rate:             {actual_rate:.2f} S/s")
        print(f"Required time scale:     {time_scale} s/div")
        print(f"Actual time scale:       {actual_time_scale} s/div")
        print(f"Actual record length:    {actual_record_length}")
        print(f"Number of (time) divs:   {div}")
        print(f"Time increment:          {xincr} s")
        print(f"Inverse time increment:  {1/xincr:.2f} S/s")

        return actual_rate, actual_record_length

    def acquire_single_curve(
        self,
        desired_rate:  int = int(1e6),
        record_length: int = int(5e5),
        correction_50ohm: bool = True,
    ) -> dict:
        """
        Acquire one waveform from CH1 and CH2 sequentially.

        Configures the horizontal timebase via :meth:`set_samplerate`, triggers
        a single acquisition, then reads and converts both channels to volts.

        Args:
            desired_rate  (int): Target sample rate in S/s. Defaults to 20 000.
            record_length (int): Number of samples to acquire. Defaults to 1 000.

        Returns:
            dict with keys:
                "sources" (list)       : ["CH1", "CH2"]
                "time"    (np.ndarray) : Time axis in seconds.
                "CH1"     (np.ndarray) : CH1 voltage array in volts.
                "CH2"     (np.ndarray) : CH2 voltage array in volts.
        """
        readout = {
            "sources": ["CH1", "CH2"],
            "time": None,
            "CH1":  None,
            "CH2":  None,
        }

        real_rate, real_RL = self.set_samplerate(desired_rate, record_length)
        xincr = 1.0 / real_rate

        self.instr.write("ACQ:MODE SAMPLE")
        self.instr.write("WFMOutpre:ENCdg ASCii")
        self.instr.write("DATA:START 1")
        self.instr.write(f"DATA:STOP {int(real_RL)}")

        self.instr.write("ACQuire:STATE ON")
        time.sleep(1.5 * real_RL * xincr)   # wait for the full record to fill
        self.instr.write("ACQuire:STATE OFF")

        for source in readout["sources"]:
            self.write(f"DATA:SOURCE {source}")
            raw  = self.query("CURVe?")
            data = np.array([float(x) for x in raw.split(",")])
            yoff  = float(self.instr.query("WFMOutpre:YOFf?"))
            yzero = float(self.query("WFMOutpre:YZERo?"))

            ymult = float(self.query("WFMOutpre:YMUlt?"))
            

            volts = (data - yoff) * ymult + yzero

            if correction_50ohm:
                volts = volts / 2
            xzero     = float(self.query("WFMOutpre:XZERo?"))
            time_axis = np.array([xzero + i * xincr for i in range(len(volts))])

            readout[source] = volts
            readout["time"] = time_axis

        self.instr.write("ACQuire:STATE RUN")
        return readout
    
    def acquire_averaged_curve(
        self,
        n_avg:         int = 16,
        desired_rate:  int = int(1e6),
        record_length: int = int(5e5),
        correction_50ohm: bool = True,
        triggerch=1,
        triggervalue=0.01,
    ) -> dict:
        """
        Acquire one averaged waveform from CH1 and CH2 sequentially.

        Configures the horizontal timebase via :meth:`set_samplerate`, switches
        to AVERage acquisition mode with *n_avg* waveforms, waits for the full
        average to complete, then reads and converts both channels to volts.

        Args:
            n_avg         (int): Number of waveforms to average. Defaults to 16.
            desired_rate  (int): Target sample rate in S/s. Defaults to 1 000 000.
            record_length (int): Number of samples to acquire. Defaults to 500 000.

        Returns:
            dict with keys:
                "sources" (list)       : ["CH1", "CH2"]
                "time"    (np.ndarray) : Time axis in seconds.
                "CH1"     (np.ndarray) : CH1 voltage array in volts.
                "CH2"     (np.ndarray) : CH2 voltage array in volts.
        """
        readout = {
            "sources": ["CH1", "CH2"],
            "time": None,
            "CH1":  None,
            "CH2":  None,
        }

        real_rate, real_RL = self.set_samplerate(desired_rate, record_length)
        xincr = 1.0 / real_rate

        self.instr.write("ACQ:MODE AVERage")
        self.instr.write(f"ACQuire:NUMAVg {int(n_avg)}")
        self.instr.write("WFMOutpre:ENCdg ASCii")
        self.instr.write("DATA:START 1")
        self.instr.write(f"DATA:STOP {int(real_RL)}")
        self.instr.write("TRIGger:A:EDGE:SOURce CH" + str(triggerch))
        print(self.instr.query("TRIGger:A:EDGE:SOURce?"))
        self.instr.write("TRIGger:A:EDGE:SLOPe RIS")
        self.instr.write(f"TRIGger:A:LEVel:CH{triggerch} {triggervalue}")
        self.instr.write("ACQuire:STATE ON")
        time.sleep(n_avg * real_RL * xincr * 1.2)   # n_avg full records + 20% margin
        self.instr.write("ACQuire:STATE OFF")


        for source in readout["sources"]:
            self.write(f"DATA:SOURCE {source}")
            raw  = self.query("CURVe?")
            data = np.array([float(x) for x in raw.split(",")])

            yzero = float(self.query("WFMOutpre:YZERo?"))
            ymult = float(self.query("WFMOutpre:YMUlt?"))
            yoff  = float(self.instr.query("WFMOutpre:YOFf?"))

            volts = (data - yoff) * ymult + yzero
            if correction_50ohm:
                volts = volts / 2
            xzero     = float(self.query("WFMOutpre:XZERo?"))
            time_axis = np.array([xzero + i * xincr for i in range(len(volts))])

            readout[source] = volts
            readout["time"] = time_axis

        self.instr.write("ACQuire:STATE RUN")
        self.instr.write("ACQ:MODE SAMple")

        return readout
    
    def acquire_averaged_curve_singlechan(
        self,
        n_avg:         int = 16,
        desired_rate:  int = int(1e6),
        record_length: int = int(5e5),
        ch: int=1,
        correction_50ohm: bool = True,
        triggerch=1,
        triggervalue=0.01,
    ) -> dict:
        """
        Acquire one averaged waveform from CH1 and CH2 sequentially.

        Configures the horizontal timebase via :meth:`set_samplerate`, switches
        to AVERage acquisition mode with *n_avg* waveforms, waits for the full
        average to complete, then reads and converts both channels to volts.

        Args:
            n_avg         (int): Number of waveforms to average. Defaults to 16.
            desired_rate  (int): Target sample rate in S/s. Defaults to 1 000 000.
            record_length (int): Number of samples to acquire. Defaults to 500 000.

        Returns:
            dict with keys:
                "sources" (list)       : ["CH1", "CH2"]
                "time"    (np.ndarray) : Time axis in seconds.
                "CH1"     (np.ndarray) : CH1 voltage array in volts.
                "CH2"     (np.ndarray) : CH2 voltage array in volts.
        """
        readout = {
            "sources": ["CH1", "CH2"],
            "time": None,
            "CH1":  None,
            "CH2":  None,
        }

        real_rate, real_RL = self.set_samplerate(desired_rate, record_length)
        xincr = 1.0 / real_rate

        self.instr.write("ACQ:MODE AVERage")
        self.instr.write(f"ACQuire:NUMAVg {int(n_avg)}")
        print(f"Num averages set to {self.instr.query("ACQuire:NUMAVg?")}")
        self.instr.write("WFMOutpre:ENCdg ASCii")
        self.instr.write("DATA:START 1")
        self.instr.write(f"DATA:STOP {int(real_RL)}")
        self.instr.write("TRIGger:A:EDGE:SOURce CH" + str(triggerch))
        print(self.instr.query("TRIGger:A:EDGE:SOURce?"))
        self.instr.write("TRIGger:A:EDGE:SLOPe RIS")
        self.instr.write(f"TRIGger:A:LEVel:CH{triggerch} {triggervalue}")
        self.instr.write("ACQuire:STATE ON")
        time.sleep(n_avg * real_RL * xincr * 1.2)   # n_avg full records + 20% margin
        self.instr.write("ACQuire:STATE OFF")

        source = "CH" + str(ch)
        self.write(f"DATA:SOURCE {source}")
        raw  = self.query("CURVe?")
        data = np.array([float(x) for x in raw.split(",")])

        yzero = float(self.query("WFMOutpre:YZERo?"))
        ymult = float(self.query("WFMOutpre:YMUlt?"))
        yoff  = float(self.instr.query("WFMOutpre:YOFf?"))

        volts = (data - yoff) * ymult + yzero
        if correction_50ohm:
            volts = volts / 2
        xzero     = float(self.query("WFMOutpre:XZERo?"))
        time_axis = np.array([xzero + i * xincr for i in range(len(volts))])

        readout[source] = volts
        readout["time"] = time_axis

        self.instr.write("ACQuire:STATE RUN")
        self.instr.write("ACQ:MODE SAMple")

        return readout


    # ------------------------------------------------------------------ #
    #  Properties                                                         #
    # ------------------------------------------------------------------ #

    @property
    def AVG(self) -> int:
        """Number of waveforms averaged in AVERage mode (0 = disabled)."""
        return self._AVG

    @AVG.setter
    def AVG(self, value: int):
        self._AVG = int(value)
        self.instr.write(f"ACQuire:NUMAVg {int(value)}")

    @property
    def SR(self) -> int:
        """Sample rate in S/s."""
        return self._SR

    @SR.setter
    def SR(self, value: int):
        self._SR = int(value)
        self.instr.write(f"HORizontal:SAMPLERate {int(value)}")

    @property
    def HS(self) -> float:
        """Horizontal time scale in s/div."""
        return self._HS

    @HS.setter
    def HS(self, value: float):
        self._HS = value
        self.instr.write(f"HORizontal:SCAle {value}")

    @property
    def RL(self) -> int:
        """Record length in samples."""
        return self._RL

    @RL.setter
    def RL(self, value: int):
        self._RL = int(value)
        self.instr.write(f"HORizontal:RECOrdlength {int(value)}")