#!/usr/bin/env python
import IPython
from instruments import agilent4395A
import numpy as np
import matplotlib.pyplot as plt
import argparse

def main():

    VNA = agilent4395A.Agilent4395A()
    print("VNA object created!")

    usage='./launchscan.py -p save_path -fmin freq_min -fmax freq_max -plot True'
    parser = argparse.ArgumentParser(description='find and save (.txt) all the resonance peaks between two frequencies', usage=usage)

    parser.add_argument("-p", "--path"   , dest="save_path"   , type=str , help="Output path"      , required = True)
    parser.add_argument("-fmin", "--fstart"    , dest="fstart"    , type=float , help="center start"  , required = True)
    parser.add_argument("-fmax", "--fstop"    , dest="fstop"    , type=float , help="center stop"  , required = True) 
    
    parser.add_argument("-plot", "--plot", dest="plot", type=bool , help="save plot in the folder "   , default = True)      
    parser.add_argument("-pw", "--power", dest="power", type=float , help="power dBm"   , default = -20)  
    parser.add_argument("-npt", "--npt", dest="npt", type=float , help="number of sweep points"   , default = 801) 
     
    parser.add_argument("-sl", "--span_large", dest="span_large", type=float , help="span large scan"   , default = 10e3)     
    parser.add_argument("-bwl", "--ifbw_large", dest="ifbw_large", type=float , help="ifbw large scan"   , default = 300)      

    parser.add_argument("-sm", "--span_small", dest="span_small", type=float , help="span small scan"   , default = 100)   
    parser.add_argument("-bws", "--ifbw_small", dest="ifbw_small", type=float , help="ifbw small scan"   , default = 30)
    
    parser.add_argument("-thr", "--threshold", dest="thr", type=float , help="threshold in Hz for ignore two nearby peaks"   , default = 1000)  
    parser.add_argument("-std", "--std", dest="std", type=float , help="nx(std) to identify a peak"   , default = 5)  
    
    args = parser.parse_args()

    VNA.set_save_path(args.save_path)
    VNA.routine(center_start=args.fstart, center_stop=args.fstop, span_large=args.span_large, IFBW_large=args.ifbw_large,
                power=args.power, npt=args.npt, 
                span_zoom=args.sm, IFBW_zoom=args.bws, 
                thr_freq=args.thr, n_std=args.std, 
                savePlot=args.plot)


    IPython.embed()
    
if __name__ == "__main__":
    main()
