import numpy as np
import h5py
from time import strftime, localtime, strptime
from datetime import datetime, timezone
import calendar
import os
import subprocess
from scipy import interpolate
from concurrent.futures import ProcessPoolExecutor
from functools import partial


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


    def write_data(self, resonance_label=None, dictionary=None, dataset=None,compression_default=None,data_keys=["i","q","t0","counter"],overwrite=True):   
        
        '''
        Write one acquisition dataset (data + metadata) for a resonance.

        Data are written under:
        `/tones/<resonance_label>/<dataset_index>/data` for the keys listed in `data_keys` and
        `/tones/<resonance_label>/<dataset_index>/info` for remaining metadata.
        If the dataset index already exists, only the keys present in `dictionary`
        are written; all the other existing keys are left untouched.

        Parameters
        ----------
        resonance_label : string
            Resonance name (e.g. 3A, 3B...). Default = None.
        dictionary : dict
            Acquisition dictionary to write. Must contain at least all the keys
            listed in `data_keys` (by default "i", "q", "t0", "counter").
            Any additional keys are stored under the dataset `/info` group.
            Default = None.
        dataset : int
            Dataset index to use under the resonance group. If None, the next
            available index is chosen (max existing + 1). If the index already
            exists, the keys in `dictionary` are added to it. Default = None.
        compression_default : string
            HDF5 compression filter name (e.g. "gzip") to apply to non-1D numpy
            arrays. If None, no compression is applied. Default = None.
        data_keys : list of string
            Keys of `dictionary` to store under `/data`. All the other keys are
            stored under `/info`. If None, ["i","q","t0","counter"] is used.
            Default = None.
        overwrite : bool
            If True, keys already present in the dataset are overwritten.
            If False, a KeyError is raised (and nothing is written) if any key
            of `dictionary` already exists in the dataset. Default = True.
        '''

        big_group = "tones"       
        
        
        # check that all the data keys are in the dictionary
        missing = [key for key in data_keys if key not in dictionary]
        if len(missing) != 0:
            raise KeyError("Missing data keys in dictionary: " + str(missing))
        
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
            
            # protect existing keys
            if overwrite is False:
                existing = []
                if "data" in f[dataset]:
                    existing += [key for key in data_keys if key in f[dataset+"/data"]]
                if "info" in f[dataset]:
                    existing += [key for key in dictionary if (key not in data_keys) & (key in f[dataset+"/info"])]
                if len(existing) != 0:
                    raise KeyError("Keys already present in " + dataset + ": " + str(existing) + ". Use overwrite=True to overwrite them.")
            
            # write data
            if self.__check_exist(path=dataset,group_name = "data") is False:
                group=f.create_group(dataset+"/"+"data")
            else:
                group=f.get(dataset+"/"+"data")    
            for key in data_keys:
                value = dictionary[key]
                if type(value) != str:
                    value = np.asarray(value)   # lists/scalars -> numpy array (as before for t0 and counter)
                self.__save_parameter(group,key,value,compression_default=compression_default)

            # write metadata
            if self.__check_exist(path=dataset,group_name = "info") is False:
                group=f.create_group(dataset+"/"+"info")
            else:
                group=f.get(dataset+"/"+"info")    
            for key, value in dictionary.items():
                if key not in data_keys:
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
           Keys stored under `/data` (i, q, t0, counter and any additional
           variable, e.g. z) are written again under `/data`.
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
            # all the keys stored under /data, for any dataset index of this tone
            all_data_keys = []
            for loc in reader.get_tones_loc(tone):
                all_data_keys += reader.get_data_keys(tone,loc)
            all_data_keys = list(set(all_data_keys))
            list_output = reader.get_reso_data(Tname=tone,dtype=np.int32)
            self.__delete_parameter("tones",tone)
            for dic in list_output:
                data_keys = [key for key in dic if key in all_data_keys]
                self.write_data(resonance_label=tone,dictionary=dic,compression_default=compression,data_keys=data_keys)
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
        
        f_lo = np.array([   50000.,   100000.,   500000.,   800000.,  1000000.,  2000000.,
                        4000000.,  6000000., 10000000., 15000000., 20000000.])
        conv = np.array([1.11288475e-04, 3.78583059e-05, 6.31778694e-06, 3.97361609e-06,
                        3.21185706e-06, 1.77819986e-06, 1.29734258e-06, 1.22319717e-06,
                        1.19453950e-06, 1.18113775e-06, 1.17588244e-06])

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
        
        self._cal_func = fun
        return
        
        
    def get_data_keys(self,Tname,loc=0):
        '''
        Return the keys stored under `/tones/<Tname>/<loc>/data`.

        Parameters
        ----------
        Tname : string
            Resonance name (e.g. 3A, 3B...).
        loc : int
            Dataset index under the resonance label. Default = 0.

        Return
        ----------
        keys : list of string
            Keys of the data group (e.g. ["counter","i","q","t0","z"]).
        '''
        with h5py.File(self._file,'r') as f:
            return list(f["tones"][Tname][str(loc)]["data"].keys())
            
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
            If True, include all the keys stored under `/data` (i, q and any
            additional variable, e.g. z) in the output.
            If False, only metadata and timestamps/counters are returned.
            Default = True.
        idx : array-like or None
            Optional selection of internal indices within the dataset group.
            Use this to select specific acquisitions (rows) stored inside the
            same `loc` group. The selection is applied to every key under
            `/data`. If None, returns all acquisitions in that group.
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
            - any other key stored under `/data` (only if trace=True).
              These keys are returned as stored (no ADC-to-V conversion
              and no dtype cast).
        '''

        with h5py.File(self._file,'r') as f: 
            if Tname not in f["tones"].keys():
                print(Tname,"not present")
                return
            dic = self.__convert_to_dict(f["tones"][Tname][str(loc)]["info"])
            data_group = f["tones"][Tname][str(loc)]["data"]
            
            # a single acquisition (scalar t0) has no rows to select
            if (idx is not None) and (data_group["t0"].shape == ()):
                idx = None
            
            if trace == True:
                data_keys = list(data_group.keys())
            else:
                data_keys = ["t0","counter"]
            
            for key in data_keys:
                value = np.array(data_group[key])
                if idx is not None:
                    value = value[idx]      # select the rows (works for 1D and 2D arrays)
                dic[key] = value
            
            if trace == True:
                if self._conversion is not None:
                    conversion = self._conversion
                else:
                    conversion = self._cal_func(dic["LO_frequency"])
                
                dic["i"] = (dic["i"]*conversion).astype(dtype,copy=False)
                dic["q"] = (dic["q"]*conversion).astype(dtype,copy=False)

        return dic
            
        


    def _string_to_epoch(self,string):
        '''
    
        Convert a UTC timestamp string to epoch seconds.
    
        Parameters
        ----------
        string : str
            Timestamp in the format "YYYY-MM-DD HH:MM:SS", interpreted as UTC.

        Returns
        -------
        int
            Epoch timestamp (seconds since 1970-01-01 00:00:00 UTC).
        '''
        
        
        dt = datetime.strptime(string, "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        return dt.timestamp()

    def _epoch_to_string(self,epoch):
        '''
        Convert epoch seconds to a UTC timestamp string.
    
        Parameters
        ----------
        epoch : int
            Epoch timestamp (seconds since 1970-01-01 00:00:00 UTC).

        Returns
        -------
        str
            Timestamp in the format "YYYY-MM-DD HH:MM:SS", expressed in UTC.
        '''
        dt = datetime.fromtimestamp(epoch, tz=timezone.utc)
        return  dt.strftime("%Y-%m-%d %H:%M:%S")

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
            tstart = self._epoch_to_string(np.min(tstamps)) 
            tstop = self._epoch_to_string(np.max(tstamps)) 
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
            in_window = (tstamps>=tstart)&(tstamps<=tstop)

            out = []
            out_keys = []   # data keys of each element of out
            for loc in np.unique(pos2[in_window]):
                in_loc = (pos2==loc)
                if np.all(in_window[in_loc]):
                    idx = None      # whole dataset selected: no row selection (avoid a copy)
                else:
                    idx = list(pos_internal[in_loc & in_window])
                dic = self._get_dataset(Tname=Tname,loc=loc,idx=idx,dtype=dtype)
                key_not_consider = self.get_data_keys(Tname,loc)
                # Add the data IF the data keys and the other parameters are the same.
                # Otherwise, create a new output.
                # The data are collected in lists and merged only once at the end (faster).
                for c, el in enumerate(out):
                    same_keys = (set(out_keys[c]) == set(key_not_consider))
                    if same_keys and self._check_consistency(dic,el,key_not_consider):
                        for key in key_not_consider:
                            el[key].append(dic[key])
                        break
                else:
                    # no compatible output found (or out is empty)
                    for key in key_not_consider:
                        dic[key] = [dic[key]]
                    out.append(dic)
                    out_keys.append(key_not_consider)

            # merge the lists into arrays, and fix the order
            for c, el in enumerate(out):
                t0_pieces = el["t0"]
                for key in out_keys[c]:
                    pieces = el[key]
                    if len(pieces) == 1:
                        el[key] = pieces[0]
                    elif np.ndim(pieces[0]) == np.ndim(t0_pieces[0]):
                        # one value per acquisition (e.g. t0, counter) -> append
                        el[key] = np.concatenate([np.atleast_1d(p) for p in pieces])
                    else:
                        # one row per acquisition (e.g. i, q, z) -> stack rows
                        el[key] = np.vstack(pieces)
                if len(el["t0"].shape) != 0:
                    if np.any(np.diff(el["t0"]) < 0):      # sort only if needed
                        i_sort =np.argsort(el["t0"])
                        for key in out_keys[c]:
                            el[key] = el[key][i_sort]      # sort rows (works for 1D and 2D arrays)

        return out
 

    def get_multi_reso_data(self, Tnames=None, tstart=-np.inf, tstop=np.inf,
                            dtype=None, max_workers=None):
        '''
        Run get_reso_data in parallel on a list of resonance labels.
        Returns a dict {Tname: list of dict}, same output as get_reso_data.
        If Tnames is None, all tones in the file are read.
        '''
        if Tnames is None:
            Tnames = self.get_tones_labels()

        func = partial(self.get_reso_data, tstart=tstart, tstop=tstop, dtype=dtype)
        with ProcessPoolExecutor(max_workers=max_workers) as ex:
            results = list(ex.map(func, Tnames))

        return dict(zip(Tnames, results))    




    def get_IQ(self,dic,skip=0,remove_dc=True,correct_circle=False):
        
        I = dic["i"][:,:].flatten()
        Q = dic["q"][:,:].flatten()

        I0 = np.mean(I[skip:]) if remove_dc else 0
        Q0 = np.mean(Q[skip:]) if remove_dc else 0
        I_cor = I-I0
        Q_cor = Q-Q0

        if correct_circle is True:
            
            cov = np.cov(I[skip:],Q[skip:])
            
            evals, evecs = np.linalg.eigh(cov)
            # Build C^{-1/2} = V diag(1/sqrt(λ)) V^T
            D_inv_sqrt = np.diag(1.0 / np.sqrt(evals))
            W = evecs @ D_inv_sqrt @ evecs.T

            I_cor, Q_cor = np.matmul(W,np.array([I_cor,Q_cor]))
                    
        z = I_cor + 1j*Q_cor
        tt = []
        t = np.arange(0,dic["i"].shape[1])*(1/dic["fs"])
        for i in range(len(dic["t0"])):
            tt.append(t+dic["t0"][i])
        t_long = np.array(tt).flatten()
        return t_long, z
        
        
        
        
        
        
        
        
