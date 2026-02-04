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





def client(host="212.189.204.163", port = 6000, save_dir = "./received_data",verbose=True):
    
    os.makedirs(save_dir, exist_ok=True)

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((host, port))
        while True:
            # Receive filename length
            raw_len = s.recv(4)
            if not raw_len:
                break
            fname_len = int.from_bytes(raw_len, "big")
            if fname_len == 0:
                if verbose==True:
                    log("[CLIENT] No more files.",level=3)
                break

            # Receive filename
            fname = s.recv(fname_len).decode()

            # Receive file size
            data_len = int.from_bytes(s.recv(8), "big")

            # Receive file content
            data = b""
            while len(data) < data_len:
                packet = s.recv(min(4096, data_len - len(data)))
                if not packet:
                    raise ConnectionError("Connection lost during file transfer")
                data += packet

            # Save file locally
            with open(os.path.join(save_dir, fname), "wb") as f:
                f.write(data)
            if verbose == True:
                log("[CLIENT] Received and saved " + str(fname),level=2)





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


    usage='test_writer.py '
    parser = argparse.ArgumentParser(description='save data from RfSoc', usage=usage)
    
    parser.add_argument("-p", "--output_path"   , dest="output_path"   , type=str , help="path to save datastream", default = ".", required = False)
    parser.add_argument("-n", "--name"   , dest="fname"   , type=str , help="name of the .gw file", default = "", required = True) 
    parser.add_argument("-b", "--buffer"   , dest="buffer"   , type=int , help="buffer size", default = 100, required = False) 
    parser.add_argument("-s", "--sleep"   , dest="sleep"   , type=float , help="waiting time (s)", default = 10, required = False) 
    parser.add_argument("-del", "--delete"   , dest="delete"   , type=int , help="delete the .npz after download", default = 1, required = False) 

    parser.add_argument("-ho", "--host"   , dest="host"   , type=str , help="ip address for the rfsoc", default = "212.189.204.163", required = False) 
    parser.add_argument("-hp", "--port"   , dest="port"   , type=int , help="port for the rfsoc", default = 6000, required = False) 
    parser.add_argument("-v", "--verbose"   , dest="verbose"   , type=int , help="verbosity", default = 1, required = False) 


    args = parser.parse_args()    

    writer = gw_handler.GwWriter(output_path=args.output_path,name=args.fname)


    log(level=6)
    log("File: " + args.output_path + "/" + args.fname+".gw",level=1)
    log("Waiting time: " + str(args.sleep) + "(s)",level=1)
    log("Maximum buffer: " + str(args.buffer),level=1)    
    log(level=6)   
    print() 
    
    while True:
        time.sleep(args.sleep)
        log("executing the CLIENT",level=1)
        
        client(host=args.host, port=args.port, verbose=args.verbose, save_dir=args.output_path+"/received_data")

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
    
