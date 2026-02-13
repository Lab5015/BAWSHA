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
        Initialize the writer and select the target `.gw` file.

        Parameters
        ----------
        output_path : string
            Directory where the `.gw` file will be saved. Default = None.
        name : string
            Base filename (without extension). The writer will save to
            `output_path + name + ".gw"`. Default = None.
        fname : string
            Full filename (including path). If provided, it overrides
            `output_path` and `name`. Default = None.
        '''

        if output_path is not None:
            output_path = fix_path(output_path)
            self._file = output_path+name  +'.gw'
        if fname is not None:
            self._file = fname

        return

    def __check_exist(self,path=None,group_name = None):
        '''
      
        Check whether a group/dataset name exists at a given HDF5 path.
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
        Write or update file-level metadata (header) under `/info`.

        Parameters
        ----------
        dictionary : dict
            Dictionary of key/value pairs to store as datasets under `/info`.
            Existing keys are overwritten. Default = None.

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
        Write one acquisition dataset (I/Q + metadata) for a resonance.

        Data are written under:
        `/tones/<resonance_label>/<dataset_index>/data` for trace-like fields and
        `/tones/<resonance_label>/<dataset_index>/info` for remaining metadata.

        Parameters
        ----------
        resonance_label : string
            Resonance name (e.g. 3A, 3B...). Default = None.
        dictionary : dict
            Acquisition dictionary to write. Must contain at least:
            - "i" : ndarray
                In-phase (I) lock-in samples.
            - "q" : ndarray
                Quadrature (Q) lock-in samples.
            - "t0" : scalar or array-like
                Acquisition start time or timestamp reference.
            - "counter" : scalar or array-like
                Acquisition counter / index.
            Any additional keys are stored under the dataset `/info` group.
            Default = None.
        dataset : int
            Dataset index to use under the resonance group. If None, the next
            available index is chosen (max existing + 1). If the index already
            exists, its content is overwritten. Default = None.
        compression_default : string
            HDF5 compression filter name (e.g. "gzip") to apply to non-1D numpy
            arrays. If None, no compression is applied. Default = None.
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
    
        '''
        Repack the file by rewriting tone datasets with compression.

        This method:
        1) Creates a temporary backup copy of the current `.gw` file.
        2) Reads each resonance dataset using `GwReader`.
        3) Deletes existing resonance groups under `/tones`.
        4) Rewrites all datasets using `write_data`, applying the chosen compression.
        5) Removes the backup file.

        Parameters
        ----------
        compression : string
            Compression filter to use when rewriting (commonly "gzip").
            Default = "gzip".
        '''
        
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
        '''
        Create or overwrite a dataset in an HDF5 group.

        Parameters
        ----------
        group : h5py.Group
            Open HDF5 group where the dataset will be created.
        variable_name : string
            Dataset name to create/overwrite.
        value : any
            Value to store. Scalars and numpy arrays are supported.
        compression_default : string
            Compression filter name to apply when `value` is a numpy array with
            dimension != 1. Default = None.
        '''

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
        
        '''
        Delete a group or dataset from the HDF5 file.

        Parameters
        ----------
        path : string
            Parent path inside the HDF5 file.
        name : string
            Name of the child object (group or dataset) to delete.
        '''        
        
        
        with h5py.File(self._file,  "a") as f:
            del f[path+'/'+name]
        return
        



class GwReader:
    
    '''
    Simple reader for the `.gw` file (HDF5).

    This class loads lock-in acquisition data written by `GwWriter`, including
    I/Q traces and associated metadata, and supports time-window selection and
    ADC-to-voltage conversion.
    
    '''
    def __init__(self, path_file):
        '''
        Initialize the reader.

        Parameters
        ----------
        path_file : string
            Path to the `.gw` HDF5 file to read.
        
        '''
        self._file = path_file
        self._conversion = None #conversion factor from ADC to V 
        self._cal_func = self._default_calibration_func()
        
    def __convert_to_dict(self, group):
        '''
        Convert an HDF5 group into a plain Python dictionary.
        
        '''
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
        '''
        Build the default ADC-to-voltage calibration function.

        The default calibration is defined by tabulated conversion factors vs
        LO frequency and returned as a 1D interpolating function.

        Return
        ----------
        cal_func : callable
            Function `cal_func(f_lo)` returning the conversion factor(s) from
            ADC units to volts for a given LO frequency (Hz).        
        
        '''
        
        f_lo = np.array([20e6, 15e6,10e6,6e6,4e6,2e6,1e6,800e3,500e3,100e3,50e3])
        conv = np.array([1.1757743453876332e-06,1.1809442830487258e-06,1.1943007965986313e-06,1.2230770171597705e-06,
                1.2972580289461507e-06, 1.7778936701059031e-06,3.210822612753387e-06,3.971248163297724e-06,
                 6.316853364777225e-06,3.7807183364839316e-05,0.00011070110701107011])

        i_sort = np.argsort(f_lo)
        f_lo = f_lo[i_sort]
        conv = conv[i_sort]

        from scipy import interpolate
        cal_func = interpolate.interp1d(f_lo,conv,kind="linear",bounds_error=False,fill_value="extrapolate")
        return cal_func

    def set_cal_func(self,fun):
        '''
        Set a custom ADC-to-voltage calibration function.

        Parameters
        ----------
        fun : callable
            Function `fun(f_lo)` that returns a conversion factor (scalar or
            array) from ADC units to volts for the provided LO frequency (Hz).
        '''
        
        self._self._cal_func = fun
        return
        
    def _get_dataset(self,Tname=None,loc = 0,trace=True,idx = None,dtype=None):
        '''
        Get one dataset for a given resonance and dataset index.

        Parameters
        ----------
        Tname : string
            Resonance name (e.g. 3A, 3B...). Default = None.
        loc : int
            Index of the selected dataset group under the resonance label.
            Default = 0.
        trace : bool
            If True, include the I/Q traces ("i" and "q") in the output.
            If False, only metadata and timestamps/counters are returned.
            Default = True.
        idx : array-like or None
            Optional selection of internal indices within the dataset group.
            Use this to select specific acquisitions stored inside the same
            `loc` group. If None, returns all acquisitions in that group.
            Default = None.
        dtype : numpy dtype or None
            dtype to cast the returned i/q arrays after conversion.
            If None, keep numpy default type. Default = None.

        Return
        ----------
        dic : dict
            Dictionary containing dataset metadata plus:
            - "t0" : ndarray or scalar
            - "counter" : ndarray or scalar
            - "i" : ndarray (only if trace=True)
            - "q" : ndarray (only if trace=True)
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
        '''
        Convert a UTC timestamp string to epoch seconds.
        
        Parameters
        ----------
        string : string
            Timestamp in the format "YYYY-MM-DD HH:MM:SS".

        Return
        ----------
        epoch : int
            Epoch timestamp (seconds since 1970-01-01 00:00:00 UTC).
        '''
        
        dt = datetime.strptime(string, "%Y-%m-%d %H:%M:%S")
        res = calendar.timegm(dt.utctimetuple())
        return res

    def _epoch_to_string(self,epoch):
        '''
        Convert epoch seconds to a local-time timestamp string.

        Parameters
        ----------
        epoch : float or int
            Epoch timestamp (seconds since 1970-01-01 00:00:00 UTC).

        Return
        ----------
        string : string
            Timestamp in the format "YYYY-MM-DD HH:MM:SS".
        '''
        
        return strftime('%Y-%m-%d %H:%M:%S', localtime(epoch))

    def set_conversion(self,conv):
        '''
        Set a constant conversion factor from ADC units to volts.

        Parameters
        ----------
        conv : float
            Multiplicative factor applied to i/q arrays to convert from ADC
            units to volts.
        '''
        
        self._conversion = conv
        
    def get_tones_labels(self):
        '''
        Return the resonance labels stored in the `.gw` file.
    
        '''
        with h5py.File(self._file,'r') as f: #
            return list(f["tones"].keys())

    def get_tones_loc(self,Tname):
        '''
        Return the dataset indices available for a given resonance label.
        
        '''
        with h5py.File(self._file,'r') as f: #
            return list(f["tones"+"/"+Tname].keys())    

    def get_times(self,Tname=None,epoch=True,return_tstamps = False):
        
        '''
        Return the first and last timestamps for a resonance, optionally with all timestamps.

        Parameters
        ----------
        Tname : string
            Resonance name (e.g. 3A, 3B...). If None, the first available tone
            label in the file is used. Default = None.
        epoch : bool
            If True, return timestamps as epoch seconds.
            If False, return timestamps as strings "YYYY-MM-DD HH:MM:SS".
            Default = True.
        return_tstamps : bool
            If True, also return the full timestamp array and index mapping
            arrays. Default = False.

        Return
        ----------
        tstart : float or string
            First timestamp (min).
        tstop : float or string
            Last timestamp (max).
        tstamps : np.array
            Array of timestamps in epoch seconds, in the same order as stored
            across dataset groups. Returned only if `return_tstamps=True`.
        positions : np.array
            Dataset-group index (`loc`) for each element in `tstamps`.
            Returned only if `return_tstamps=True`.
        internal_positions : np.array
            Internal index within each `loc` group for each element in `tstamps`.
            Returned only if `return_tstamps=True`.
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
        Compare two dictionaries while ignoring selected keys.

        Parameters
        ----------
        d1 : dict
            First dictionary.
        d2 : dict
            Second dictionary.
        keys : list
            Keys to ignore during the comparison.

        Return
        ----------
        same : bool
            True if `d1` and `d2` match after removing `keys`, otherwise False.
    
        '''
        d1_r = {x: d1[x] for x in d1 if x not in keys}
        d2_r = {x: d2[x] for x in d2 if x not in keys}
        
        return (d1_r == d2_r)
        
    def get_reso_data(self,Tname,tstart = -np.inf, tstop = np.inf,dtype=None):
        
        '''
        Return resonance datasets within a specified time window.

        This method selects acquisitions whose timestamps `t0` fall within
        `[tstart, tstop]`, loads the corresponding I/Q traces and metadata, and
        merges acquisitions into as few output dictionaries as possible by
        grouping entries with identical metadata (excluding i/q/t0/counter).

        Parameters
        ----------
        Tname : string
            Resonance name (e.g. 3A, 3B...).
        tstart : float or string
            Start time (inclusive). If float, interpreted as epoch seconds.
            If string, must be "YYYY-MM-DD HH:MM:SS".
            If -np.inf, the earliest available timestamp is used.
            Default = -np.inf.
        tstop : float or string
            Stop time (inclusive). If float, interpreted as epoch seconds.
            If string, must be "YYYY-MM-DD HH:MM:SS".
            If np.inf, the latest available timestamp is used.
            Default = np.inf.
        dtype : numpy dtype or None
            dtype to cast the returned i/q arrays after conversion.
            If None, keep numpy default type. Default = None.
            Default = None.

        Return
        ----------
        out : list of dict
            List of dictionaries. Each dictionary contains metadata and arrays:
            - "i" : ndarray, shape (N, nsamples) or (nsamples,) depending on storage
            - "q" : ndarray, shape (N, nsamples) or (nsamples,) depending on storage
            - "t0" : ndarray
            - "counter" : ndarray
            plus additional metadata keys from the dataset `/info`.
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

