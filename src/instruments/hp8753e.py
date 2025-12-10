import pyvisa
import numpy as np
import struct
import matplotlib as mpl
#mpl.use('Agg')
import matplotlib.pyplot as plt
import time
import sys
import os
import tkinter
from scipy.signal import find_peaks

'''
def progressBar(toolbar_width=300):
    toolbar_width = int(toolbar_width + 1)
    # setup toolbar
    sys.stdout.write("[%s]" % (" " * toolbar_width))
    sys.stdout.flush()  
    sys.stdout.write("\b" * (toolbar_width+1)) # return to start of line, after '['
    for i in range(toolbar_width):
        time.sleep(0.1) # do real work here
        # update the bar
        sys.stdout.write(".")
        sys.stdout.flush()
    sys.stdout.write("]\n") # this ends the progress bar
    return
'''
def progressBar(time_sleep=300):

    toolbar_width = 20
    sleep = time_sleep
    sleep_rep = sleep/toolbar_width

    for rep in range(toolbar_width):
        time.sleep(sleep_rep) # do real work here
        # update the bar
        sys.stdout.write("=")
        sys.stdout.flush()
    sys.stdout.write("\n") # this ends the progress bar
    return


class HP8753E():

    def __init__(self,name='GPIB0::16::INSTR'):
        resources = pyvisa.ResourceManager('@py')
        self._vna = resources.open_resource(name)

        self.set_sleep(0.5)
        #self.reset()
        self.set_NA()

        self._vna.read_termination = '\n'
        self._vna.write_termination = '\n'

        self._path = None  #save path for data files
        self._run = -1     #default run number
        self._params = {}  #self._params["nome elemento"] = oggetto

        return

    def reset(self):
        self._vna.write('*RST;')
        return

    def set_sleep(self,time):
        self._sleep = time
        return    

    def get_name(self):
        print(self._vna.query('*IDN?'))    
        return

    def set_NA(self):
        self._vna.write('FORM2;')
        time.sleep(self._sleep)
        self._vna.write('CHAN1;')
        time.sleep(self._sleep)
        self._vna.write('S11;')  #S21 or MEASB
        time.sleep(self._sleep)
        #self._vna.write('TSTP 1;')  #generate RF from port 1
        #time.sleep(self._sleep)
        #self._vna.write('CHAN2;')
        #time.sleep(self._sleep)
        #self._vna.write('S11;')
        #time.sleep(self._sleep)
        self._vna.write('LINFREQ;')
        time.sleep(self._sleep)
        self._vna.write('CONT;') #set continuous sweep
        return

    def set_point(self,npt):
        self._vna.write('POIN '+str(npt))
        return

    def set_center(self,freq):    #freq in Hz
        self._vna.write('CENT '+str(freq))
        return

    def set_span(self,df):
        self._vna.write('SPAN '+str(df))
        return        

    def set_IFBW(self,bw):
        self._vna.write('IFBW '+str(bw))
        return        

    def set_frequencies(self,fmin,fmax):
        self._vna.write('STAR '+str(fmin))
        time.sleep(self._sleep)
        self._vna.write('STOP '+str(fmax))
        pass

    def set_scale(self,tipo='AUTO'):
        self._vna.write(tipo)
        return        

    def set_power(self,power):
        self._vna.write("POWE "+str(power))
        return
    
    def set_mode(self,mode):
        self._vna.write(mode)
        return

    def set_save_path(self,path):
        self._path = path
        return

    def start_single_measure(self,mode='S11',npt=1601,center=5.175e6,span=100,IFBW=300,power=-20):
        self.set_mode(mode)
        time.sleep(self._sleep)
        self.set_point(npt)
        time.sleep(self._sleep)
        self.set_center(center)
        time.sleep(self._sleep)
        self.set_span(span)
        time.sleep(self._sleep)
        self.set_IFBW(IFBW)
        time.sleep(self._sleep)
        self.set_power(power)
        time.sleep(self._sleep)
        #self.set_scale() #skip this one to save time. otherwise need to wait for a full sweep to avoid timeout
        #time.sleep(self._sleep)
        return

    def query(self, query):
        return self._vna.query(query)
    
    def write(self, query):
        return self._vna.write(query)

    
    def set_format(self, format):
        ''' Set the format for the displayed data'''
        if format == 'polar':
            write_string = 'POLA;'
        elif format == 'log magnitude':
            write_string = 'LOGM;'
        elif format == 'phase':
            write_string = 'PHAS;'
        elif format == 'delay':
            write_string = 'DELA;'
        elif format == 'smith chart':
            write_string = 'SMIC;'
        elif format == 'linear magnitude':
            write_string = 'LINM;'
        elif format == 'standing wave ratio':
            write_string = 'SWR;'
        elif format == 'real':
            write_string = 'REAL;'
        elif format == 'imaginary':
            write_string = 'IMAG;'

        self._vna.write(write_string)

    def output_data_format(self, format):
        if format == 'raw data array 1':
            msg = 'OUTPRAW1;'
        elif format == 'raw data array 2':
            msg = 'OUTPRAW2;'
        elif format == 'raw data array 3':
            msg = 'OUTPRAW3;'
        elif format == 'raw data array 4':
            msg = 'OUTPRAW4;'
        elif format == 'error-corrected data':
            msg = 'OUTPDATA;'
        elif format == 'error-corrected trace memory':
            msg = 'OUTPMEMO;'
        elif format == 'formatted data':
            msg = 'DISPDATA;OUTPFORM'
        elif format == 'formatted memory':
            msg = 'DISPMEMO;OUTPFORM'
        elif format == 'formatted data/memory':
            msg = 'DISPDDM;OUTPFORM'
        elif format == 'formatted data-memory':
            msg = 'DISPDMM;OUTPFORM'
        
        self._vna.write(msg)  

    def get_data(self, format_data = 'polar', format_out = 'formatted data'):

        self.get_init_par()  #fill the _params dict
        sweeping_time = self._params.get("sweep")
        npt =  self._params.get("npt")

        num_bytes = 8*int(npt)+4

        self.set_format(format_data)
        time.sleep(self._sleep)
        self.output_data_format(format_out)
        time.sleep(self._sleep)

        progressBar(sweeping_time)

        raw_bytes = self._vna.read_bytes(num_bytes)

        trimmed_bytes = raw_bytes[4:]
        tipo = '>' + str(2*int(npt)) + 'f'
        x = struct.unpack(tipo, trimmed_bytes)

        yIm = list(x)
        yRe = yIm.copy()
        del yRe[1::2]
        del yIm[0::2]

        yRe = np.array(yRe)
        yIm = np.array(yIm)

        #yIm = yIm - np.mean(yIm)  #FIXME? it seems that the phase is shifted. re-alining it to 0. apparently not needed for RAKON
        #yIm = yIm - yIm[-1]  #FIXME? it seems that the phase is shifted. re-alining it to 0. apparently not needed for RAKON

        yPow = 20*np.log10(np.sqrt(yRe**2 + yIm**2))  #log mag
        yPhase = np.arctan2(yIm,yRe)

        xx = np.linspace(1, self._params.get("npt"), int(self._params.get("npt")))
        xdata = self._params.get("fmin") + (xx - 1) * (self._params.get("fmax")-self._params.get("fmin")) / (self._params.get("npt") - 1)
        return xdata, yPow, yPhase, yRe, yIm
    
    def print_current_path(self):
        print(self._path)
        return 

    def plot_power(self):
        x, y, _, _, _ = self.get_data()
        plt.plot(x,y,color='k')
        plt.show()
        return

    def plot_phase(self):
        x, _, z, _, _ = self.get_data()
        plt.plot(x,z,color='k')
        plt.show()
        return

    def make_new_run(self):
        with open('/home/cmsdaq/Analysis/Data/last_run') as f:
            runs = [int(x) for x in next(f).split()]
            run = str(runs[0]+1)
        os.remove('/home/cmsdaq/Analysis/Data/last_run')
        with open('/home/cmsdaq/Analysis/Data/last_run','w+') as f:
            f.write(run)
        self.set_save_path("/home/cmsdaq/Analysis/Data/raw/run%04d" % (int(run)))
        self.run = int(run)
        return

    def save_data_txt(self, name='Run', savePlot=False):
    
        file_name = 'run%04d' % (int(self.run))
        if name is not None:
            file_name += ('_'+name)
        file_name += '.dat' 
        if self._path is not None:
            os.system('mkdir -p ' + self._path)
            file_name = self._path + "/" +file_name

        self.get_init_par()
        lista = list(self._params.items())
        x,y,z,re,im = self.get_data()
        np.savetxt(file_name, np.array([x,y,z,re,im]).T)
        with open(file_name, "r+") as f:
            content = f.read()
            f.seek(0,0)
            for j in range(len(lista)):
                f.write("#"+str(lista[j][0])+"\t"+str(lista[j][1]))
                f.write('\n')
            f.write(content)
            f.close()

        if savePlot:
            plt.plot(x,y,c='k')
            plt.savefig(file_name.rstrip('.dat')+'_pow.png')
            plt.close()

            plt.plot(x,z,c='k')
            plt.savefig(file_name.rstrip('.dat')+'_phase.png')
            plt.close()
        return

    def get_init_par(self):
        npt = float(self._vna.query('POIN?').strip())
        self._params["npt"] = npt
        center = float(self._vna.query('CENT?').strip())
        self._params["fcenter"] = center
        sweep_time = float(self._vna.query('SWET?').strip())
        self._params["sweep"] = sweep_time
        span = float(self._vna.query('SPAN?').strip())
        self._params["span"] = span
        bw = float(self._vna.query('IFBW?').strip())
        self._params["bw"] = bw
        power = float(self._vna.query('POWE?').strip())
        self._params["input_power"] = power
        freq_min = float(self._vna.query('STAR?').strip())
        self._params["fmin"] = freq_min
        freq_max = float(self._vna.query('STOP?').strip())  
        self._params["fmax"] = freq_max    
        return self._params

    def find_peak(self, n_std=5,distance_f=500,rm_thr=600): #distance and rm_thr in Hz
        x, y, z, _, _ = self.get_data()

        Y = np.abs(-y+y[np.argmin([y[0],y[-1]])]  )
        df = x[1]-x[0]
        distance_s = int(np.round(distance_f/df))
        peaks, _ = find_peaks(Y,height=None, distance=distance_s,width=2)
        
        #find the positions in the x vector without a peak (no_peaks).
        rm_thr_s = int(np.round(rm_thr/df))
        no_peaks = np.arange(len(Y))
        for pos in peaks:
            no_peaks = no_peaks[(no_peaks<(pos-int(rm_thr_s/2))) | (no_peaks>(pos+int(rm_thr_s/2))) ]
        print(len(no_peaks)," ",len(peaks))
        #define a proper threshold
        thr1 = np.mean(Y[no_peaks])+n_std*np.std(Y[no_peaks])
        print(np.mean(Y[no_peaks])," ",np.std(Y[no_peaks])," ",thr1);

        peaks, _ = find_peaks(Y, height=thr1,distance=distance_s,width=1)
        print(peaks);
        return x[peaks], y[peaks]        

    def routine(self, f_start = None, f_stop=None, span_large=None, IFBW_large = None, power=None,
                npt = None, span_zoom=100, IFBW_zoom=30,thr_freq=1000, n_std=5,savePlot=False):

        self.make_new_run()

        dic = self.get_init_par()
        if npt is None:
            npt = dic["npt"]
        if IFBW_large is None:
            IFBW_large = dic["bw"]
        if power is None:
            power = dic["power"]

        centers = np.arange(f_start+span_large/2 ,f_stop-span_large/2, span_large)  #*0.8) #superimposition between intervals needed

        count = 0;
        for i in centers:
            self.start_single_measure(mode='S21',npt=npt,center=i,span=span_large,IFBW=IFBW_large,power=power)
            print(self.get_init_par())
            sweeping_time = self._params.get("sweep")
            #time.sleep(sweeping_time)
            freq, heights = self.find_peak(n_std=n_std, distance_f=thr_freq, rm_thr=2*IFBW_large)
            
            if (len(freq) !=  0):
                fmin = str(self._params["fmin"])
                fmax = str(self._params["fmax"])
                self.save_data_txt('Peak_S21'+'_'+fmin+'_'+fmax, savePlot=savePlot)
                for f in freq:
                    count  = count + 1
                    new_c = f

                    print("### Peak found! Number: ", count)
                    print('###### Zooming in S21')
                    self.start_single_measure(mode='S21',npt=npt,center=new_c,span=span_zoom,IFBW=IFBW_zoom,power=power)
                    print(self.get_init_par())
                    self.save_data_txt('Zoomed_peak_S21_'+str(count), savePlot=savePlot)

                    print('###### Zooming in S11')
                    self.start_single_measure(mode='S11',npt=npt,center=new_c,span=span_zoom,IFBW=IFBW_zoom,power=power)
                    print(self.get_init_par())
                    self.save_data_txt('Zoomed_peak_S11_'+str(count), savePlot=savePlot)

                    print('###### Zooming in S22')
                    self.start_single_measure(mode='S22',npt=npt,center=new_c,span=span_zoom,IFBW=IFBW_zoom,power=power)
                    print(self.get_init_par())
                    self.save_data_txt('Zoomed_peak_S22_'+str(count), savePlot=savePlot)
                    print('######')

        return


    def routine_new(self, f_start = None, f_stop=None, span_values=None, ifbw_values=None, power=None, npt=None, thr_freq=1000, n_std=5, savePlot=False):

        self.make_new_run()
        
        dic = self.get_init_par()
        if npt is None:
            npt = dic["npt"]
        if power is None:
            power = dic["power"]
            
        ## define centers of starting search regions
        count = 0;
        centers = np.arange(f_start+span_values[0]/2 ,f_stop-span_values[0]/2, span_values[0])
        ## loop on the defined centers 
        for ic, centre in enumerate(centers):            
            ## loop over span values and ifbw part the last value
            freq = np.array([]);
            for ispan, span in enumerate(span_values[:-1]):
                ## if frequencies and heights are alread non empty --> additional scans at reduced span and ifbw
                if np.any(freq):                    
                    print("Found some frequencies --> improved span")
                    freq_tmp = np.array([]);
                    for f in freq:
                        ## setup measurement parameters
                        self.start_single_measure(mode='S21',npt=npt,center=f,span=span,IFBW=ifbw_values[ispan],power=power)
                        print(self.get_init_par())                
                        sweeping_time = self._params.get("sweep")
                        a, _ = self.find_peak(n_std=n_std,distance_f=thr_freq,rm_thr=2*ifbw_values[ispan])
                        freq_tmp = np.append(freq_tmp,a);
                    freq = freq_tmp;
                    if np.any(freq):
                        fmin = str(self._params["fmin"])
                        fmax = str(self._params["fmax"])
                        print("Improved frequencies found --> ",freq);
                        self.save_data_txt('Peak_S21'+'_'+fmin+'_'+fmax, savePlot=savePlot)
                    else:
                        break;
                else:
                    ## setup measurement parameters
                    self.start_single_measure(mode='S21',npt=npt,center=centre,span=span,IFBW=ifbw_values[ispan],power=power)
                    print(self.get_init_par())          
                    sweeping_time = self._params.get("sweep")
                    freq, _ = self.find_peak(n_std=n_std,distance_f=thr_freq,rm_thr=2*ifbw_values[ispan])
                    if np.any(freq):
                        fmin = str(self._params["fmin"])
                        fmax = str(self._params["fmax"])
                        print("Frequencies found --> ",freq);
                        self.save_data_txt('Peak_S21'+'_'+fmin+'_'+fmax, savePlot=savePlot)
                    else:
                        break;
                   
            ## if frequencies are found ... use last values of ifbw and span
            print("Found frequncies --> ",freq," --> save data")
            if  np.any(freq):
                fmin = str(self._params["fmin"])
                fmax = str(self._params["fmax"])
                for f in freq:
                    count  = count + 1
                    print("### Peak found! Number: ", count)
                    print('###### Zooming in S21')
                    self.start_single_measure(mode='S21',npt=npt,center=f,span=span_values[-1],IFBW=ifbw_values[-1],power=power)
                    print(self.get_init_par())
                    self.save_data_txt('Zoomed_peak_S21_'+str(count), savePlot=savePlot)
                    print('###### Zooming in S11')
                    self.start_single_measure(mode='S11',npt=npt,center=f,span=span_values[-1],IFBW=ifbw_values[-1],power=power)
                    print(self.get_init_par())
                    self.save_data_txt('Zoomed_peak_S11_'+str(count), savePlot=savePlot)
                    print('###### Zooming in S22')
                    self.start_single_measure(mode='S22',npt=npt,center=f,span=span_values[-1],IFBW=ifbw_values[-1],power=power)
                    print(self.get_init_par())
                    self.save_data_txt('Zoomed_peak_S22_'+str(count), savePlot=savePlot)
                    print('######')
            
        return
