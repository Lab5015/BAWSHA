import numpy as np
from scipy import signal
import scipy

def PSD(edata, t_sample, window="hann"):
    """
    Mean noise power spectrum of a set of noise traces (one trace per row).
    Works for real and complex traces.
    
    Returns
    -------
    f   : frequencies in np.fft.fftfreq order (length N)
    J   : two-sided noise spectrum in numpy-FFT units.
          This is the array to pass to OF as NPS.
    pxx : mean one-sided PSD density in physical units. e.g. if edata is in V, pxx--> (V^2/Hz), length N/2+1
    """
    N = edata.shape[1]
    if N % 2:
        raise ValueError("PSD: an even record length is required")
        
    onesided = not np.iscomplexobj(edata)
    _, pxx = signal.welch(edata, fs=1./t_sample, window=window, nperseg=N,
                          scaling="density", axis=1, return_onesided=onesided)
    pxx = pxx.mean(axis=0)

    if onesided:
        # one-sided -> two-sided density: welch doubles every bin except DC and Nyquist
        p2 = pxx.copy()
        p2[1:-1] /= 2.
     
        # mirror into FFT order (0, 1, ..., N/2, N/2-1, ..., 1) and convert to E|FFT|^2
        J = np.concatenate((p2, p2[1:-1][::-1])) * N / t_sample
    else:
        # complex data: welch already returns the two-sided density in FFT order
        J = pxx * N / t_sample     
        
    f = np.fft.fftfreq(N, d=t_sample)
    return f, J, pxx
    
    
class OF():   
    """
    Optimum filter class. Works with real or complex traces.
    """

    def __init__(self, medium=None, NPS=None, H=None):
        self._medium = medium # Expected pulse shape (real or complex)
        self._NPS = NPS # two sided Noise Power Spectral Density in numpy fft units.
        self._H        = H	# OF transfer function                                                           

    def create_filter(self,normalization="SNR"): 
        """
        Create the tranfer function H.
 
        Parameters
        ----------
        normalization : "amplitude" or "SNR"
            "amplitude": K is set in such a way that the OF medium amplitude
                         is equal to the medium amplitude.
            "SNR"      : H is scaled so that the filtered noise has unit RMS
                         (E|y|^2 = 1), i.e. the output is the SNR.
 
        The amplitude resolution (output noise RMS of the amplitude-normalized
        filter) is stored in self._sigma in both cases.
          	
        Return
        ------
        None
           
        """

        
        m = np.abs(self._medium) if np.iscomplexobj(self._medium) else self._medium   
        
        i = np.argmax(m)
        if not 0 < i < m.size - 1:
            val_max = m[i]
        else:
            a, b, c = np.polyfit([-1, 0, 1], m[i-1:i+2], 2)
            val_max = c - b**2 / (4.*a)
 
        S       = np.fft.fft(self._medium)
 
        # remove the DC bin, and avoid 0/0
        W = np.zeros(len(self._NPS))
        W[1:] = 1. / self._NPS[1:]
        
        OF_med  = np.fft.ifft(S*S.conjugate()*W).real
        K       = val_max/np.amax(OF_med)  
        self._H = K*S.conjugate()*W
 
        # output noise RMS of the amplitude filter: E|y|^2 = (1/N^2) sum |H|^2 J
        self._sigma = np.sqrt(np.sum(np.abs(self._H)**2 * self._NPS)) / len(self._NPS)
 
        if normalization == "SNR":
            self._H = self._H / self._sigma
        elif normalization != "amplitude":
            raise ValueError('normalization must be "amplitude" or "SNR"')
        return


    def filter_event(self, edata,domain="time"): 
    
        if domain == "frequency":
            """Works on a single trace (1D) or on a matrix of traces (one per row)."""
            event_OF_f = self._H*np.fft.fft(edata) if np.ndim(edata) == 1 else np.fft.fft(edata, axis=1)*self._H
            event_OF = np.fft.ifft(event_OF_f)
            
            if not (np.iscomplexobj(edata) or np.iscomplexobj(self._medium)):          
                event_OF = event_OF.real
                
            if np.ndim(event_OF) == 1:
                return np.concatenate((event_OF[int(edata.shape[0]/2):edata.shape[0]],event_OF[0:int(edata.shape[0]/2)]))
            else:
                return np.concatenate((event_OF[:,int(edata.shape[1]/2):edata.shape[1]],event_OF[:,0:int(edata.shape[1]/2)]),axis=1)
        if domain == "time":
            h = np.roll(np.fft.ifft(self._H), len(self._H) // 2)

            filtered = scipy.signal.oaconvolve(edata, h, mode="full")
            filtered = filtered[len(self._H) // 2: len(self._H) // 2 + len(edata)]        
            return filtered  
        
        
        
