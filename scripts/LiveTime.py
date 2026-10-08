#!/usr/bin/env python

import numpy as np
import argparse
from rw import gw_handler
import os
import matplotlib
#matplotlib.use("TkAgg")
import matplotlib.pyplot as plt

def main():
    usage='\n LiveTime.py -ignore test_Ricky,150902.gw -Tstart 2026-08-02 -Tstop 2026-09-15 \n'
    parser = argparse.ArgumentParser(description='Display livetime of the experiment', usage=usage)
    
    parser.add_argument("-Tstart", "--Tstart"   , dest="Tstart"   , type=str , help="inf or YYYY-MM-DD", default = "inf", required = False)
    parser.add_argument("-Tstop", "--Tstop"   , dest="Tstop"   , type=str , help="inf or YYYY-MM-DD", default = "inf", required = False)
    parser.add_argument("-fpath", "--fpath"   , dest="fpath"   , type=str , help="path for the .gw folder", default = "/bauscia-nas/data/gw_files/", required = False)    
    parser.add_argument("-ignore", "--ignore"   , dest="ignore"   , type=str , help="files to ignore. e.g. file1,file2", default = None, required = False)    
    
    args = parser.parse_args()    
    lista_ignora = []
    if args.ignore is not None:
        lista_ignora = args.ignore.split(",")
    reader = gw_handler.GwReader(args.fpath)
    if args.Tstart == "inf":
        Tstart = -np.inf 
    if args.Tstop == "inf":
        Tstop = np.inf 
    if args.Tstart != "inf":
        Tstart = reader._string_to_epoch(args.Tstart+" 00:00:00")
    if args.Tstop != "inf":
        Tstop = reader._string_to_epoch(args.Tstop+ " 23:59:59")
        
    listone = os.listdir(args.fpath)
    measure_dt = []
    fname = []
    for el in listone:
        if el in lista_ignora:   
            continue
        reader = gw_handler.GwReader(args.fpath+el)
        start,stop = reader.get_times(epoch=True)
        measure_dt.append([start,stop])
        fname.append(el)

    measure_dt = np.array(measure_dt)
    fname = np.array(fname)
    
    i_sort = np.argsort(measure_dt[:,0])
    fname = fname[i_sort]
    measure_dt = measure_dt[i_sort,:]
    
    ii = np.where((measure_dt[:,0]>=Tstart)&(measure_dt[:,0]<=Tstop))[0]
    fname = fname[ii]
    measure_dt = measure_dt[ii,:]
    
    print("Selected files in",args.fpath,":")
    print(fname)
    
    colors = ["navajowhite","lightblue"]
    it = 0
    for i in range(len(fname)):
        plt.axvspan(measure_dt[i][0],measure_dt[i][1],color=colors[it])
        pos = (measure_dt[i][1]+measure_dt[i][0])/2
        it +=1
        if it == 2:
            it = 0
        plt.text(pos,0.6,fname[i],rotation=90,fontsize=10)
    xtickpos = np.linspace(measure_dt[0,0],measure_dt[-1,1],5)
    tmp = []
    for el in xtickpos:
        tmp.append(reader._epoch_to_string(el))
    plt.xticks(xtickpos,tmp,rotation=45)
    plt.yticks([])
    plt.tight_layout()
    plt.show()
    
if __name__ == "__main__":
    main()
