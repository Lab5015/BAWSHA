#!/usr/bin/env python
import IPython
from instruments import agilent4395A, hp8753e
import numpy as np
import matplotlib.pyplot as plt
import argparse

def main():

    usage='./launchscan.py -fmin freq_min -fmax freq_max -plot True'
    parser = argparse.ArgumentParser(description='find and save (.txt) all the resonance peaks between two frequencies', usage=usage)

    parser.add_argument("-dev", "--device", dest="device", type=str , help="device type", required = False, default='hp8753e', choices=['hp8753e','agilent4395A'])
    
    parser.add_argument("-fmin", "--fstart"    , dest="fstart"    , type=float , help="center start"  , required = False)
    parser.add_argument("-fmax", "--fstop"    , dest="fstop"    , type=float , help="center stop"  , required = False) 
    parser.add_argument("-fcen", "--fcen"    , dest="fcen"    , type=float , help="center"  , required = False)
    
    parser.add_argument("-plot", "--plot", dest="plot", type=bool , help="save plot in the folder "   , default = True)      
    parser.add_argument("-pw", "--power", dest="power", type=float , help="power dBm"   , default = -30)  
    parser.add_argument("-npt", "--npt", dest="npt", type=float , help="number of sweep points"   , default = 1601) 
     
    parser.add_argument("-sl", "--span-large", dest="span_large", type=float , help="span large scan"   , default = 20e3)     
    parser.add_argument("-bwl", "--ifbw-large", dest="ifbw_large", type=float , help="ifbw large scan"   , default = 300)      

    parser.add_argument("-sm", "--span-small", dest="span_small", type=float , help="span small scan"   , default = 200)   
    parser.add_argument("-bws", "--ifbw-small", dest="ifbw_small", type=float , help="ifbw small scan"   , default = 10)

    parser.add_argument("--span-values", dest="span_values", type=float, nargs="+", default=[])
    parser.add_argument("--ifbw-values", dest="ifbw_values", type=float, nargs="+", default=[])
    
    parser.add_argument("-thr", "--threshold", dest="thr", type=float , help="threshold in Hz for ignore two nearby peaks"   , default = 1000)  
    parser.add_argument("-std", "--std", dest="std", type=float , help="nx(std) to identify a peak"   , default = 10)
    
    args = parser.parse_args()

    if args.device == "hp8753e":
        VNA = hp8753e.HP8753E()
    elif args.device == "agilent4395A":        
        VNA = agilent4395A.Agilent4395A()
    print("VNA object created!")
    
    windowWidth = 6e2
    if args.fcen:
        args.fstart = args.fcen - windowWidth
        args.fstop  = args.fcen + windowWidth

    if not args.span_values or not args.ifbw_values or len(args.span_values)!=len(args.ifbw_values):
        VNA.routine(f_start=args.fstart, 
                    f_stop=args.fstop, 
                    span_large=args.span_large, 
                    IFBW_large=args.ifbw_large,
                    span_zoom=args.span_small, 
                    IFBW_zoom=args.ifbw_small, 
                    power=args.power, 
                    npt=args.npt, 
                    thr_freq=args.thr, 
                    n_std=args.std, 
                    savePlot=args.plot)
    else:
        print("Start new routine with span ",args.span_values," ifbw ",args.ifbw_values);
        VNA.routine_new(f_start=args.fstart, 
                        f_stop=args.fstop, 
                        span_values=args.span_values,
                        ifbw_values=args.ifbw_values,
                        power=args.power, 
                        npt=args.npt, 
                        thr_freq=args.thr, 
                        n_std=args.std, 
                        savePlot=args.plot)



    #IPython.embed()
    
if __name__ == "__main__":
    main()
