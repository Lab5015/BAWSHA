import numpy as np
import h5py
from time import strftime, localtime, strptime
from datetime import datetime
import calendar
import os
import subprocess
from scipy import interpolate


def fix_path(path):
    '''
    fix a str path
    '''
    if path[-1] != "/":
        path += "/"
    return path
 
 
class GwWriter:
    
    '''
    Simple writer for the .lazy file (hdf5).
    
    '''
    
    def __init__(self, output_path=None,name=None,fname=None):
        '''
        Initialize the writer
        
        Parameters
        ----------
        output_path : string
            path where the .gw file will be saved. Default = None
        name : string
            name of the .gw file. Default = None
        fname : string
            if name is not None, the file is saved directly using this name (w/o the .gw). Default = None
        '''

        if output_path is not None:
            output_path = fix_path(output_path)
            self._file = output_path+name  +'.gw'
        if fname is not None:
            self._file = fname

        return

    def __check_exist(self,path=None,group_name = None):
        '''
        check whether a certain label (group_name) exist given a certain path inside the hdf5.
        '''

        with h5py.File(self._file,'r') as f:
            if path is None:
                names = list(f.keys())   
            else:
                names = list(f[path].keys() ) 
            if group_name in names:
                return True
            else:
                return False
    
    def set_general_info(self, dictionary=None):
        
        '''
        Write the header of the .gw file. The header is a python dictionary
        '''
                
        with h5py.File(self._file,'a') as f:

            if self.__check_exist(group_name = "info") is False:
                general_info=f.create_group('info')
            else:
                general_info=f.get("info")
        
            for key, value in dictionary.items():
                self.__save_parameter(general_info,key,value)
        return


    def write_data(self, resonance_label=None, dictionary=None, dataset=None,compression_default=None):   
        
        '''
        Write the dataset in the .gw file
        
        Parameters
        ----------
        resonance_label : string
            Resonance name (e.g. 3A, 3B...). Default = None
        dictionary : dict
            the dictionary to write. It must have "i" and "q" keys. Default = None
        dataset : int
            group index where the dictionary is written. If None, the last
            dataset present in the HDF5 file +1 is used. If the dataset already
            exists, the existing data are overwritten. Default is None.
        '''

        big_group = "tones"       
        
        
        with h5py.File(self._file,'a') as f:
        
            if self.__check_exist(path=None,group_name = big_group) is False:
                f.create_group(big_group)
            
            if self.__check_exist(path=big_group,group_name = resonance_label) is False:
                group=f.create_group(big_group + "/"+ resonance_label)
            else:
                group=f.get(big_group + "/"+ resonance_label)        
 
            resonance_group = big_group + "/"+ resonance_label 
            
            lista_counter = list(group.keys())
            if len(lista_counter) == 0:
                counter = "0"
            else:
                counter = str(np.sort(np.array(lista_counter).astype(int))[-1]+1)
            
            if dataset is not None:
                nn = str(dataset)
            else:
                nn = counter
            
            if self.__check_exist(path=resonance_group,group_name = nn) is False:
                f.create_group(resonance_group + "/"+nn)               
            dataset = resonance_group + "/"+nn
            if self.__check_exist(path=dataset,group_name = "data") is False:
                group=f.create_group(dataset+"/"+"data")
            else:
                group=f.get(dataset+"/"+"data")    
            I_data = dictionary["i"] 
            Q_data = dictionary["q"] 
            self.__save_parameter(group,"i",I_data,compression_default=compression_default)
            self.__save_parameter(group,"q",Q_data,compression_default=compression_default)
            self.__save_parameter(group,"t0",np.array(dictionary["t0"]))
            self.__save_parameter(group,"counter",np.array(dictionary["counter"]))


            if self.__check_exist(path=dataset,group_name = "info") is False:
                group=f.create_group(dataset+"/"+"info")
            else:
                group=f.get(dataset+"/"+"info")    
            for key, value in dictionary.items():
                if (key != "i") & (key != "q") & (key != "t0") & (key != "counter"):
                    self.__save_parameter(group,key,value)      
                    
        return

    def merge_and_compress(self,compression="gzip"):
        
        file1 = os.path.abspath(self._file)
        file2 = file1+"_bkup"
        subprocess.call(["cp",file1, file2])       
        
        reader = GwReader(self._file)
        reader.set_conversion(1)
        tones_list = reader.get_tones_labels()
        for tone in tones_list:
            list_output = reader.get_reso_data(Tname=tone,dtype=np.int32)
            self.__delete_parameter("tones",tone)
            for dic in list_output:
                self.write_data(resonance_label=tone,dictionary=dic,compression_default=compression)
        subprocess.call(["rm",file2])       
        return

            
    def __save_parameter(self,group,variable_name,value,compression_default=None):
        compression = None
        if type(value) == np.ndarray:
            if len(value.shape) != 1:
                compression = compression_default
        try:
            group.create_dataset(variable_name, data=value,compression=compression)        
        except (ValueError):     #if exist, overwrite it
            del group[variable_name]
            group.create_dataset(variable_name, data=value,compression=compression) 
        return

    def __delete_parameter(self,path,name):
        with h5py.File(self._file,  "a") as f:
            del f[path+'/'+name]
        return
        



class GwReader:
    
    '''
    Simple reader for the .lazy file (hdf5).
    
    '''
    def __init__(self, path_file):
        self._file = path_file
        self._conversion = None #conversion factor from ADC to V 
        self._cal_func = self._default_calibration_func()
        
    def __convert_to_dict(self, group):
        dic = {}

        for key in group.keys():
            el = group[key]
            if el.shape != ():
                el = np.array(el)
            elif el.dtype == 'object':
                el = str(np.array(el).astype(str))
            else:
                el = float(np.array(el).astype(float))
            dic[key] = el
        return dic   

    def _default_calibration_func(self):
        f_lo = np.array([20e6, 15e6, 10e6, 5e6, 3e6, 1e6, 6e6, 7e6, 8e6, 9e6, 500e3, 100e3, 50e3, 2e6, 4e6, 20e3, 10e3])
        conv = np.array([2.895750100627316e-07, 2.9052510475851067e-07, 2.9389089006815327e-07, 3.05916735582909e-07, 3.450600059350321e-07,
                7.765321626679574e-07, 3.0038569523267874e-07, 2.9762583868481125e-07, 2.9580314497903743e-07, 2.948820275301861e-07,
                1.5076134479119554e-06, 8.977466558937068e-06, 2.7183762232693003e-05, 4.296830800829002e-07, 3.1768959185359166e-07,
                0.00020661157024793388, 0.0009345794392523364])

        i_sort = np.argsort(f_lo)
        f_lo = f_lo[i_sort]
        conv = conv[i_sort]

        from scipy import interpolate
        cal_func = interpolate.interp1d(f_lo,conv,kind="linear",bounds_error=False,fill_value="extrapolate")
        return cal_func

    def set_cal_func(self,fun):
        self._self._cal_func = fun
        return
        
    def _get_dataset(self,Tname=None,loc = 0,trace=True,idx = None,dtype=None):
        
        '''
        Get the dataset corresponding to a given resonance and position in the .gw file.  
        
        Parameters
        ----------
        Tname : string
            Resonance name (e.g. 3A, 3B...). Default = None
        loc : int
            Index of the selected dataset. Default = 0
        trace : bool
            If true, also return the "i" and "q" data. Default = True.

        Return
        ----------
        dic : dictionary
            Dictionary with all information for the selected dataset.
        '''


        
        if (idx != None):
            if (len(idx) == 1) & (idx[0] == 0):
                idx = None
        with h5py.File(self._file,'r') as f: 
            if Tname not in f["tones"].keys():
                print(Tname,"not present")
                return
            dic = self.__convert_to_dict(f["tones"][Tname][str(loc)]["info"])
            if idx is not None:
                dic["t0"] = np.array(f["tones"][Tname][str(loc)]["data/t0"])[idx]
                dic["counter"] = np.array(f["tones"][Tname][str(loc)]["data/counter"])[idx]
            else:
                dic["t0"] = np.array(f["tones"][Tname][str(loc)]["data/t0"])
                dic["counter"] = np.array(f["tones"][Tname][str(loc)]["data/counter"])
            if trace == True:
                if idx is not None:
                    i = np.array(f["tones"][Tname][str(loc)]["data/i"])[idx,:]
                    q = np.array(f["tones"][Tname][str(loc)]["data/q"])[idx,:]
                else:
                    i = np.array(f["tones"][Tname][str(loc)]["data/i"])
                    q = np.array(f["tones"][Tname][str(loc)]["data/q"])
                
                if self._conversion is not None:
                    conversion = self._conversion
                else:
                    conversion = self._cal_func(dic["LO_frequency"])
                
                dic["i"] = (i*conversion).astype(dtype)
                dic["q"] = (q*conversion).astype(dtype)

        return dic


    def _string_to_epoch(self,string):
        
        dt = datetime.strptime(string, "%Y-%m-%d %H:%M:%S")
        res = calendar.timegm(dt.utctimetuple())
        return res

    def _epoch_to_string(self,epoch):
        return strftime('%Y-%m-%d %H:%M:%S', localtime(epoch))

    def set_conversion(self,conv):
        self._conversion = conv
        
    def get_tones_labels(self):
        '''
        Return the labels of the tones in the .gw file
    
        '''
        with h5py.File(self._file,'r') as f: #
            return list(f["tones"].keys())

    def get_tones_loc(self,Tname):
        with h5py.File(self._file,'r') as f: #
            return list(f["tones"+"/"+Tname].keys())    

    def get_times(self,Tname=None,epoch=True,return_tstamps = False):
        
        '''
        Return the first and last timestamps of the dataset.  
        
        Parameters
        ----------
        Tname : string
            Resonance name (e.g. 3A, 3B...). Default = None
        epoch : bool
            If True, timestamps are in epoch. If False, return a string in the 
            format YYYY-MM-DD HH:MM:SS. Default = True
        return_tstamps : bool
            If true, also return the array of timestamps in epoch. Default = False.

        Return
        ----------
        tstart : float or string
            The first timestamp
        tstop : float or string
            The last timestamp
        tstamp : np.array
            Array of timestamps in the same order as the datasets in the .gw file.
        '''

        if Tname == None:
            Tname = self.get_tones_labels()[0]

        tstamps = np.array([])
        positions = np.array([])
        internal_positions = np.array([])
        with h5py.File(self._file,'r') as f:
            for loc in f["tones"][Tname].keys():
                #tstamps.append(self._get_dataset(Tname=Tname,loc=loc,trace=False)["t0"][0])
                tt = self._get_dataset(Tname=Tname,loc=loc,trace=False)["t0"]
                tstamps = np.append(tstamps,tt)
                if len(tt.shape) != 0:
                    positions = np.append(positions,np.ones(len(tt))*int(loc))
                    internal_positions = np.append(internal_positions,np.arange(len(tt)))
                else:
                    positions = np.append(positions,int(loc))
                    internal_positions = np.append(internal_positions,0)
        tstamps = np.array(tstamps)
        if epoch == True:
            tstart = np.min(tstamps)
            tstop = np.max(tstamps)
        else:
            tstart = strftime('%Y-%m-%d %H:%M:%S', localtime(np.min(tstamps)))
            tstop = strftime('%Y-%m-%d %H:%M:%S', localtime(np.max(tstamps)))
        if return_tstamps == False:
            return tstart,tstop
        else:
            return tstart,tstop,tstamps,positions.astype(int), internal_positions.astype(int)
                


    def _check_consistency(self,d1,d2,keys):
        '''
        Return true if the dictionaries have the same entries.
        The keys in keys are not considered.
    
        '''
        d1_r = {x: d1[x] for x in d1 if x not in keys}
        d2_r = {x: d2[x] for x in d2 if x not in keys}
        
        return (d1_r == d2_r)
        
    def get_reso_data(self,Tname,tstart = -np.inf, tstop = np.inf,dtype=None):
        
        '''
        Return the dataset for the selected resonance within a specified time window. 
        
        Parameters
        ----------
        Tname : string
            Resonance name (e.g. 3A, 3B...). Default = None
        tstart : float or string
            Start time. If a float, it is interpreted as an epoch timestamp.
            If a string, it must be in the format "YYYY-MM-DD HH:MM:SS".
            If -np.inf, the first available timestamp is used.
            Default is -np.inf.
        tstop : float or string
            Stop time. If a float, it is interpreted as an epoch timestamp.
            If a string, it must be in the format "YYYY-MM-DD HH:MM:SS".
            If np.inf, the first available timestamp is used.
            Default is np.inf.

        Return
        ----------
        dic : dictionary
            Dictionary with all information for the selected dataset.
        '''
        
        with h5py.File(self._file,'r') as f:
            if Tname not in f["tones"].keys():
                print(Tname,"not present")
                return

            #select the dataset:
            if type(tstart) == str:
                tstart = self._string_to_epoch(tstart)
            if type(tstop) == str:
                tstop = self._string_to_epoch(tstop)
                
            _,_, tstamps, pos2, pos_internal =self.get_times(Tname=Tname,return_tstamps=True)
            ii = np.where((tstamps>=tstart)&(tstamps<=tstop))[0]

            out = []
            key_not_consider = ["t0","i","q","counter"]
            for loc in np.unique(pos2[ii]):
                ii2 = np.where(pos2==loc)[0]
                idx = list(pos_internal[np.intersect1d(ii2,ii)])
                dic = self._get_dataset(Tname=Tname,loc=loc,idx=idx,dtype=dtype)
                if len(out) == 0:
                    out.append(dic)
                    continue
                # Add i, q and timestamp data IF the other parameters are the same.
                # Otherwise, create a new output.
                c = 0
                for el in out:
                    if self._check_consistency(dic,el,key_not_consider):
                        el["i"]= np.vstack([el["i"],dic["i"]])
                        el["q"]= np.vstack([el["q"],dic["q"]])
                        el["t0"] = np.append(np.array(el["t0"]),dic["t0"])
                        el["counter"] = np.append(np.array(el["counter"]),dic["counter"])
                        break
                    else:
                        if c == len(out)-1:
                            out.append(dic)
                        else:
                            c +=1
                            continue
                            

            # convert list into array, and fix the order
            for el in out:
                if len(el["t0"].shape) != 0:
                    i_sort =np.argsort(el["t0"])
                    el["counter"] = el["counter"][i_sort]
                    el["i"] = el["i"][i_sort,:]
                    el["q"] = el["q"][i_sort,:]
                    el["t0"] =el["t0"][i_sort]
                else:
                    continue
            

        return out

