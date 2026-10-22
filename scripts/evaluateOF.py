#!/usr/bin/env python
import numpy as np
from scipy import signal
from rw import gw_handler
from process import filters
import argparse
from scipy.optimize import curve_fit
import pandas
from matplotlib import pyplot as plt


def find_noise_trace(tstamp, ydata, nwindow=1000, npt=1024, max_tries=100, nsigma_rly = 4, nsigma_poisson=2):
    '''
    Finds, roughly, a stretch of data without signals.
    ydata = |I + jQ| (with I, Q centred on zero).
    A timetrace w/o signals is the one which has rayleigh distribution
    with a number of events on the tail less or equal to n_sigma_possion*expectations
    '''
    rayleigh = lambda x, s, A: A * (x / s**2) * np.exp(-x**2 / (2 * s**2))

    L = nwindow * npt                      # window length in samples

    for _ in range(max_tries):
        pos = np.random.randint(0, len(ydata) - L)
        z_noise = ydata[pos:pos + L]

        counts, edges = np.histogram(z_noise, bins=50)
        centers = 0.5 * (edges[:-1] + edges[1:])
        p0 = [np.sqrt(np.mean(z_noise**2) / 2), np.sum(counts) * (edges[1] - edges[0])]

        ok = counts > 0                    # Poisson errors, skip empty bins
        try:
            param, cov = curve_fit(rayleigh, centers[ok], counts[ok], p0=p0,
                                   sigma=np.sqrt(counts[ok]), absolute_sigma=True)
        except RuntimeError:
            continue

        res = (counts[ok] - rayleigh(centers[ok], *param)) / np.sqrt(counts[ok])
        chi2_red = np.sum(res**2) / (ok.sum() - 2)

        prob = np.exp(-nsigma_rly**2 / 2) 
        expected = prob*np.sum(counts)
        measured = np.sum(counts[centers>=nsigma_rly*param[0]])
        if measured <= expected + nsigma_poisson*np.sqrt(expected):
            return pos, pos+L

    raise RuntimeError("No noise-only window found")

def medium(t,A=1,f0=None,tau=None,phi=0,t0=0):
    '''
    Generate a complex signal oscillating at frequency f0, with amplitude A
    and phase phi, starting at time t0 with respect to the time vector t.
    The signal decays with a time constant tau, in seconds.
    '''

    return (t>=t0)*A*np.exp(-(t-t0)/tau)*np.exp(1j*(np.pi*2*f0*(t-t0) + phi))
    
    
def power_bit_length(x):
    return 2**(x-1).bit_length()
    

def log(message='',level=1):
    out = '|'+level*2*'-'
    if level==-1:
        out = '|'+20*'-'
    else:
        out +=' '+ message
    if level == 0:
        out = message
    print(out)
    return
    
    
def main():
    usage='\n evaluateOF.py -p /path/of/the/gw/file/ -n name_of_the_gw_file -c /path/for/the/csv/file.csv [-ot rk08_7C,rk08_3C] [-n_tau 5] [-n_window 1000] [-j 4] [-ns_r 4] [-ns_p 2] \n'
    
            
    parser = argparse.ArgumentParser(description='Evaluate the optimum filter (OF) for each OT of a compressed .gw file and save the SNR in the file', usage=usage)
    
    parser.add_argument("-p", "--path"   , dest="path"   , type=str , help="path for the .gw file", default = "/data/", required = False)
    parser.add_argument("-n", "--name"   , dest="name"   , type=str , help="names", default = "", required = True)
    parser.add_argument("-c", "--config"   , dest="config"   , type=str , help=".csv file with the OF infos", default = None, required = True)
    parser.add_argument("-n_tau", "--n_tau"   , dest="n_tau"   , type=int , help="n_tau*tau is the lenght (in second) of the expected signal", default = 5, required = False)
    parser.add_argument("-n_window", "--n_window"   , dest="noise_window"   , type=int , help="number of traces (lenght: n_tau*tau) over which evaluate the noise spectrum", default = 1000, required = False)
    parser.add_argument("-ot", "--ot"   , dest="OT"   , type=str , help="OT to analyze. e.g. rk08_7C,rk08_3C. If None, all OT will be processed", default = None, required = False)    
    parser.add_argument("-j", "--jobs"   , dest="max_workers"   , type=str , help="Number of cores to use. If None, all will be used", default = None, required = False)    
    
    parser.add_argument("-ns_r", "--n_sigma_rly"   , dest="n_sigma_rly"   , type=int , help="n_sigma_rly of the rayleigh distribution that defines its tail", default = 4, required = False)
    parser.add_argument("-ns_p", "--n_sigma_pois"   , dest="n_sigma_pois"   , type=int , help="n_sigma_rly thr for find the noise trace", default = 2, required = False)    
    
    args = parser.parse_args()    
    
    log("OF expected shape for each channel is evaluated from "+ args.config + " file")
    
    path = args.path  if args.path .endswith("/") else args.path  + "/"
    log("Opening "+args.name+ " file in "+ path)
    reader = gw_handler.GwReader(path + args.name)   
    writer = gw_handler.GwWriter(fname=path+args.name)
    if args.OT is not None:
        channel_list = args.OT.split(",")
        log(args.OT + " OTs will be processed.",level=2)
    else:
        channel_list = reader.get_tones_labels()
        log("All OTs will be processed.",level=2)
        
    for tone in reader.get_tones_labels():
        if len(reader.get_tones_loc(tone)) > 1:
            log("Error: the file need to be merged and compressed!")
            return
        
    log("Loading config file for the optimum filter from "+ args.config)
    info = pandas.read_csv(args.config)    
    
    log("Opening the file...")
    
    nj = args.max_workers
    if args.max_workers is not None:
        nj = int(args.max_workers)
    output = reader.get_multi_reso_data(Tnames=channel_list,max_workers=nj)
    log("Done.",level=2)
    
    for label in channel_list[:]:
        log("Opening OT: " + label)
        try:
            pos = np.where(info["label"]==label)[0][0]
        except:
            log("Warning: The OT called " +label + " is NOT present in the config file, I will skip it", level=2)
            continue
    
        
        tstamp, raw = reader.get_IQ(output[label][0])
        fs = output[label][0]["fs"]

        try:
            tau = float(info["tau_s"][pos])
            npt = power_bit_length(int((args.n_tau*tau)*fs))
            f0 = float(info["fres_Hz"][pos])- output[label][0]["LO_frequency"]
        except:
            log("Warning: there is a problem in the config file. I will skip this OT",level=2)
            continue
            

        try:
            p1,p2 =find_noise_trace(tstamp, np.abs(raw), nwindow=args.noise_window, npt=npt,nsigma_rly = args.n_sigma_rly, nsigma_poisson=args.n_sigma_pois)
        except:
            log("Warning: no suitable time trace was found for the noise, i will skip this OT",level=2)
            continue
            
        log("Noise NPS was evaluated on a trace lasting ~ "+ str(np.round(npt*args.noise_window/fs/60,1)) + " minutes")
        freq , NPS, _ = filters.PSD(raw[p1:p2].reshape(args.noise_window, npt) ,1/fs,window="hann")

        t = np.arange(npt)/fs
        expected_signal = medium(t, A=1, f0=f0, tau=tau, phi=0, t0=0)
        
        log("Evaluating the OF...",level=2)       
        MatchedFilter = filters.OF(medium=expected_signal,NPS=NPS)
        MatchedFilter.create_filter(normalization="SNR")
        filtered = MatchedFilter.filter_event(raw,domain="time")
        log("Done",level=3)
        
        dic = {"OF_medium": expected_signal, "OF_NPS": NPS, "OF_freq": freq, "OF_TF": MatchedFilter._H,"SNR":np.abs(filtered).reshape(output[label][0]["i"].shape)}
        
        log("Saving the data..",level=3)
        writer.write_data(resonance_label=label,dictionary=dic,dataset=0,compression_default="gzip",data_keys=["SNR"])



if __name__ == "__main__":
    main()
    
