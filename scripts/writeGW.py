#!/usr/bin/env python

from os import listdir
import re
import json
import time
import numpy as np
import h5py
import os
import subprocess
from pathlib import Path
import socket
import argparse


from rw import gw_handler
from instruments import RFSoC

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



        
def write_gw_data(raw_data_folder = "received_data", data_key="arr_0",delete=True,writer=None):
    lista = np.array(listdir(raw_data_folder))

    lista_to_del = []  #list of file to delate after writing
    
    for el in lista:

        if "config" in el:
            #print("processing",el)

            number = re.findall(r'\d+', el)[0]
        
            #load config metadata into dictionary
            with open(raw_data_folder+"/"+el) as f:
                dic = json.load(f)
            
            #load i,q data into the dictionary
            try:
                idata = np.load(raw_data_folder+"/"+"ivals_"+str(number)+".npz")
                qdata = np.load(raw_data_folder+"/"+"qvals_"+str(number)+".npz")
            except Exception as e: 
                print("warning:", e)
                continue              
                
                
            i = 0
            for key in dic.keys():
                dic[key]["i"] = idata[data_key][i].astype("int32")
                dic[key]["q"] = qdata[data_key][i].astype("int32")
                i +=1
            
            #write the data for each channel
            for key in dic.keys():
                writer.write_data(resonance_label=key,dictionary=dic[key])
            lista_to_del.append(el)
            lista_to_del.append("ivals_"+str(number)+".npz")
            lista_to_del.append("qvals_"+str(number)+".npz")

    #delete or move the files
    if delete == True:
        for el in lista_to_del:
            os.remove(raw_data_folder + "/"+el)
    else:
        Path(raw_data_folder+"/processed_data").mkdir(parents=True, exist_ok=True)
        for el in lista_to_del:
            subprocess.call(["mv",raw_data_folder + "/"+el, raw_data_folder+"/processed_data/"+el])  
    return
        






def main():
    usage='\n writeGW.py -p /path/for/the/output/file -n name_of_the_gw_file -t 1 -cf /path/for/the/csv/file \n'
    usage += '    Start a new acquisition using the configuration provided in the CSV file.csv file\n\n'
    
    usage+='writeGW.py -p /path/for/the/output/file -n name_of_the_gw_file -t 1 -fc 5e6 -fs 100 -Nm 16 \n'
    usage+='    Start a new acquisition by configuring 16 lock-ins at different frequencies centered at 5 MHz, spaced by 100 Hz\n\n'
    
    usage+='writeGW.py -p /path/for/the/output/file -n name_of_the_gw_file -t 1 -fm 4e6 -fs 100 -Nm 16 \n'
    usage+='    Start a new acquisition by configuring 16 lock-ins at different frequencies, starting from 4 MHz, spaced of 100 Hz\n\n'    
    
    usage+='writeGW.py -p /path/for/the/output/file -n name_of_the_gw_file -t 1 -fM 7e6 -fs 100 -Nm 16 \n'
    usage+='    Start a new acquisition by configuring 16 lock-ins at different frequencies, ending at 7 MHz, spaced of 100 Hz\n\n'        
    
    usage += "-------------------------------------------------------------\n"
    usage += '-t 1 --> start new acquisition. Stop existing acquisition.\n'
    usage += '-t 0 --> Continue the existing acquisition. Ignore other input option\n'
    usage += '-t 2 --> Stop the existing acquisition. Ignore other input option\n'
    usage += "-------------------------------------------------------------\n"
        
    parser = argparse.ArgumentParser(description='Config and download data from the RfSoc', usage=usage)
    
    parser.add_argument("-p", "--output_path"   , dest="output_path"   , type=str , help="path to save datastream", default = ".", required = False)
    parser.add_argument("-n", "--name"   , dest="fname"   , type=str , help="name of the .gw file", default = "", required = True) 
    parser.add_argument("-b", "--buffer"   , dest="buffer"   , type=int , help="buffer size", default = 20, required = False) 
    parser.add_argument("-s", "--sleep"   , dest="sleep"   , type=float , help="waiting time (s)", default = 10, required = False) 
    parser.add_argument("-del", "--delete"   , dest="delete"   , type=int , help="delete the .npz after download", default = 1, required = False) 
    parser.add_argument("-t", "--type"   , dest="type"   , type=int , help="0: Continue; 1: New; 2: Kill.", default = 1, required = True) 

    parser.add_argument("-ho", "--host"   , dest="host"   , type=str , help="ip address for the rfsoc", default = "212.189.204.163", required = False) 
    parser.add_argument("-v", "--verbose"   , dest="verbose"   , type=int , help="verbosity", default = 1, required = False) 

    parser.add_argument("-cf", "--csv"   , dest="csv"   , type=str , help="path for the config csv file", default = None, required = False) 

    parser.add_argument("-fc", "--fcenter"   , dest="fcenter"   , type=float , help="center frequency (Hz)", default = None, required = False) 
    parser.add_argument("-fm", "--fstart"   , dest="fstart"   , type=float , help="starting frequency (Hz)", default = None, required = False) 
    parser.add_argument("-fM", "--fstop"   , dest="fstop"   , type=float , help="stop frequency (Hz)", default = None, required = False) 
    parser.add_argument("-fs", "--fspan"   , dest="fspan"   , type=float , help="Spacing between frequencies (Hz)", default = 60, required = False)     
    parser.add_argument("-Nm", "--Nmodes"   , dest="Nmodes"   , type=int , help="Number of lock-in", default = 16, required = False)     

    args = parser.parse_args()    

    writer = gw_handler.GwWriter(output_path=args.output_path,name=args.fname)
    xilinx = RFSoC.LoRFSoC(args.host)

    log(level=6)
    log("File: " + args.output_path + "/" + args.fname+".gw",level=1)
    log("Waiting time: " + str(args.sleep) + "(s)",level=1)
    log("Maximum buffer: " + str(args.buffer),level=1)    
    log(level=6)   
    print() 
    
    log("executing the CLIENT",level=1)
    output = xilinx.get_status()
    if output is None:
        return


    obj = xilinx.create_lo_dic(fcenter = args.fcenter,start=args.fstart,stop = args.fstop,span=args.fspan,Nmodes=args.Nmodes)
    if obj is not None:
        input_dic,fm, fM,fc = obj
        log("SCAN MODE:",level=1)
        log("fcenter: " + str(fc) + " (Hz)", level=2)
        log("fstart: " + str(fm) + " (Hz)", level=2)
        log("fstop: " + str(fM) + " (Hz)", level=2)
        print()
        
    if obj is None:
        input_dic = xilinx.load_csv(args.csv)
        if input_dic is not None:
            log("Sending config data from the csv file",level=1)
            log(args.csv,level=2)    
            obj = 1

    output = xilinx.get_status()

    if output == "idle":
        if args.type == 2:
            log("No existing acquisition is present.",level=1)
            return
            
        log("Starting new acquisition...",level=1)
        if obj is not None:
            xilinx.send_config_file(input_dic)
            
        xilinx.start_acquisition()
        log("Acquisition started",level=2)
    
    if output == 'running':
        if args.type == 1:
            log("An existing acquisition is present, I will kill it and start a new one",level=1)
            xilinx.stop_acquisition()
            if obj is not None:
                xilinx.send_config_file(input_dic)
                
            xilinx.start_acquisition()
            log("New acquisition started",level=2)
        elif args.type == 2:
            log("An existing acquisition is present, I will kill it.",level=1)
            xilinx.stop_acquisition()
            return
            
        else:
            log("An existing acquisition is present, I will continue downloading the data.",level=1)
                      
    while True:
        time.sleep(args.sleep)
        
        
        xilinx.download_data(verbose=args.verbose, save_dir=args.output_path+"/received_data")
        file_in_folder = listdir(args.output_path+"/received_data")
        if (len(file_in_folder)<=2):
            continue
        
        write_gw_data(raw_data_folder = args.output_path+"/received_data", delete=bool(args.delete), writer=writer)
        
        reader = gw_handler.GwReader(args.output_path+"/"+args.fname+".gw")
        
        regroup = False
        for tone in reader.get_tones_labels():
            tstart,tstop = reader.get_times(Tname=tone,epoch=False)
            buffer = len(reader.get_tones_loc(tone))
            log(tone,level=1)
            printt = "buffer size : "+str(buffer) + " ; " + "tstart : " + tstart + " ; " + "tstop : " + tstop
            log(printt, level=2)
            
            if buffer >= args.buffer:
                regroup = True
        
        if regroup == True:
            log("Compressing the dataset...",level=1)
            writer.merge_and_compress()
            regroup = False
            log("Done!",level=2)  
          

if __name__ == "__main__":
    main()
    
