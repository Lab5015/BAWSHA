import socket
import os
import json
import numpy as np
import pandas
import time

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
    

class LoRFSoC:
    
    '''
    Controller for the rfSoc 4x2 (lock-in mode).
    
    '''
    
    def __init__(self, host="212.189.204.163"):
        '''
        ssh xilinx@jarvis2.mib.infn.it
        '''
        self._host = host
        return

    def send_cmd(self,cmd,port = 6000):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((self._host, port))
            s.sendall(json.dumps(cmd).encode())
            return s.recv(1024).decode()

    def force_cmd(self,cmd,port = 6000,required=None):
        if required is not None:
            while True:
                flag = self.send_cmd({"cmd": "state_info"})
                time.sleep(1)
                if flag == required:
                    break
        while True:
            output = self.send_cmd(cmd)
            if output == '{"status":"ok"}':
                break  
        return
        
    def get_status(self):
        try:
            out = self.send_cmd({"cmd": "state_info"})
            return out
        except Exception as e:
            print(e)
            log("ERROR: FPGA not connected OR server not started.", level=2)
            log("Lauch the server", level=3)
            log("ssh xilinx@jarvis2.mib.infn.it ",level=3)
            log("cd Simba/software/src/simba", level=3)
            log("sudo -E python server.py", level=3)
            return None
        return 

    def start_acquisition(self):
        self.force_cmd({"cmd": "start"})
        return

    def stop_acquisition(self):
        self.force_cmd({"cmd": "stop"})
        return

    def send_config_file(self,input_dic):
        self.force_cmd({"cmd":"config_lo","config":input_dic},required="idle")
        return

    def download_data(self,port = 6001, save_dir = "./received_data",verbose=True):
    
        os.makedirs(save_dir, exist_ok=True)

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((self._host, port))
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
                    
                    
                    
    def load_csv(self,path=None):
        if path == None:
            return None
        csvFile = pandas.read_csv(path)
        names = np.array(csvFile["name"].astype(str))
        LO_frequency = np.array(csvFile["LO_frequency"].astype(int))
        resonance_frequency = np.array(csvFile["resonance_frequency"].astype(str))
        out = []
        for i in range(len(names)):
            dic = {"name":str(names[i]),"LO_frequency":int(LO_frequency[i]),"resonance_frequency":int(resonance_frequency[i])}
            out.append(dic)
        return out
        

    def create_lo_dic(self,fcenter = None,start=None,stop = None,span=None,Nmodes=16):
        flag = len(np.where(np.array([fcenter,start,stop])!=None)[0])
        if  flag > 1:
            log("Error: specify only one parameter (fc,fm,fM)",level=1)
            return None
        if flag == 0:
            return None
       
        if fcenter != None:
            start = fcenter - Nmodes//2 * span
            stop = start + Nmodes * span

        if start != None:
            stop = start + Nmodes * span

        if stop != None:
            start = stop - Nmodes*span
        
        f_lo = np.arange(start, stop, span).astype('int')
        out = []
        for freq in f_lo:
            dic = {"name":str(freq),"LO_frequency":int(freq),"resonance_frequency":int(freq)}
            out.append(dic)
        return out,start,stop,fcenter
