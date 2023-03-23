import pyvisa
import numpy as np
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


class Agilent4395A():

    def __init__(self,name='GPIB::17::INSTR'):
        resources = pyvisa.ResourceManager('@py')
        self._vna = resources.open_resource(name)
        self._sleep = 0.5       #sleep between commands
        self._path = None  #save path for data files
        self._params = {}
        #self._params["nome elemento"] = oggetto
        return

    def reset(self):
        self._vna.write('*RST')
        return

    def set_sleep(self,time):
        self._sleep = time
        return    

    def get_name(self):
        print(self._vna.query('*IDN?'))    
        return

    def set_NA(self,ch="1",net="B",sweep_type = "CONT"):
        self._vna.write('CHAN'+ch)
        time.sleep(self._sleep)
        self._vna.write('NA')
        time.sleep(self._sleep)
        self._vna.write('MEAS '+net)
        time.sleep(self._sleep)
        self._vna.write(sweep_type) #set continuous sweep
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
        self._vna.write('BW '+str(bw))
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

    def set_save_path(self,path):
        self._path = path
        return

    def start_single_measure(self,npt=800,center=5.175e6,span=100,IFBW=300,power=-20):
        self.set_point(npt)
        time.sleep(self._sleep)
        self.set_center(center)
        time.sleep(self._sleep)
        self.set_span(span)
        self._params["span"] = span
        time.sleep(self._sleep)
        self.set_IFBW(IFBW)
        self._params["IFBW"] = IFBW
        time.sleep(self._sleep)
        self.set_power(power)
        self._params["power"] = power
        time.sleep(self._sleep)
        self.set_scale()
        return

    

    def get_data(self):
        dtype = 'float'
        ydata = self._vna.query('OUTPDTRC?').strip().split(',')
        ydata = np.array(ydata)
        ydata = ydata[np.arange(int(len(ydata)/2))*2].astype(dtype) #FIXME?
        xdata = self._vna.query('OUTPSWPRM?').strip().split(',')
        xdata = np.array(xdata).astype(dtype)
        return xdata, ydata

    def print_current_path(self):
        print(self._path)
        return 

    def plot_data(self):
        x,y = self.get_data()
        plt.plot(x,y,color='k')
        plt.show()
        return

    def save_data_txt(self,name='Run', savePlot=False):
        save_path = ''
        if name is not None:
            save_path = name + '_'
        save_path += time.strftime("%y:%m:%d:%H:%M:%S") + '.dat' 
        if self._path is not None:
            os.system('mkdir -p ' + self._path)
            save_path = self._path +"/" +save_path

        self.get_init_par()
        lista = list(self._params.items())
        x,y = self.get_data()
        np.savetxt(save_path, np.array([x,y]).T)
        with open(save_path, "r+") as f:
            content = f.read()
            f.seek(0,0)
            for j in range(len(lista)):
                f.write("#"+str(lista[j][0])+"\t"+str(lista[j][1]))
                f.write('\n')
            f.write(content)
            f.close()

        if savePlot:
            plt.plot(x,y,c='k')
            plt.savefig(save_path.rstrip('.dat')+'.png')
            plt.close()
        return

    def get_init_par(self):
        npt = float(self._vna.query('POIN?').strip())
        self._params["npt"] = npt
        center = float(self._vna.query('CENT?').strip())
        self._params["center"] = center
        sweep_time = float(self._vna.query('SWET?').strip())
        self._params["sweep"] = sweep_time
        span = float(self._vna.query('SPAN?').strip())
        self._params["span"] = span
        bw = float(self._vna.query('BW?').strip())
        self._params["bw"] = bw
        power = float(self._vna.query('POWE?').strip())
        self._params["power"] = power
        freq_min = float(self._vna.query('STAR?').strip())
        self._params["fmin"] = freq_min
        freq_max = float(self._vna.query('STOP?').strip())  
        self._params["fmax"] = freq_max
        #print("Npoints: ", npt)    
        #print("Center: ", center)
        #print("Sweep time: ", sweep_time)
        #print("Span: ", span)
        #print("IF BW: ", bw)
        #print("Power: ", power)
        #print("(freq_min, freq_max): ", freq_min, freq_max)      
        return self._params

    def find_peak(self, n_std=5,distance_f=500,rm_thr=600): #distance and rm_thr in Hz
        x, y = self.get_data()
        Y = np.abs(-y+y[np.argmin([y[0],y[-1]])]  )
        
        df = x[1]-x[0]
        distance_s = int(np.round(distance_f/df))

        peaks, _ = find_peaks(Y,height=None, distance=distance_s,width=2)
        
        #find the positions in the x vector without a peak (no_peaks).
        rm_thr_s = int(np.round(rm_thr/df))
        no_peaks = np.arange(len(Y))
        for pos in peaks:
            no_peaks = no_peaks[(no_peaks<(pos-int(rm_thr_s/2))) | (no_peaks>(pos+int(rm_thr_s/2))) ]

        #define a proper threshold
        thr1 = np.mean(Y[no_peaks])+n_std*np.std(Y[no_peaks])

        peaks, _ = find_peaks(Y, height=thr1,distance=distance_s,width=1)
        return x[peaks], y[peaks]        

    def routine(self, center_start = None, center_stop=None, span_large=None, IFBW_large = None, power=None,
                npt = None, span_zoom=100, IFBW_zoom=30,thr_freq=1000, n_std=5,savePlot=False):

        dic = self.get_init_par()
        if npt is None:
            npt = dic["npt"]
        if IFBW_large is None:
            IFBW_large = dic["bw"]
        if power is None:
            power = dic["power"]

        centers = np.arange(center_start ,center_stop, span_large)
        count = 0;
        for i in centers:
            self.start_single_measure(npt=npt,center=i,span=span_large,IFBW=IFBW_large,power=power)
            print(self.get_init_par())
            sweeping_time = self._params.get("sweep")
            progressBar(sweeping_time)
            #time.sleep(sweeping_time)
            freq, heights = self.find_peak(n_std=n_std,distance_f =thr_freq, rm_thr=2*IFBW_large)

            
            if (len(freq) !=  0):
                fmin = str(self._params["fmin"])
                fmax = str(self._params["fmax"])
                self.save_data_txt('Peak'+'_'+fmin+'_'+fmax, savePlot=savePlot)
                for f in freq:
                    count  = count + 1
                    new_c = f
                    print("### Peak found! Number: ", count)
                    print('###### Zooming in')
                    self.start_single_measure(npt=npt,center=new_c,span=span_zoom,IFBW=IFBW_zoom,power=power)
                    print(self.get_init_par())
                    progressBar(self._params.get("sweep"))
                    self.save_data_txt('Zoomed_peak'+str(count), savePlot=savePlot)
                    print('######')

        return
