import numpy as np
import h5py
import os
import re

class ScanWriter:
    
    '''
    some info here
    
    '''
    
    def __init__(self, run_numb=None, output_path=None,name=None):
        
        '''
        some info here
        
        '''
        if name is not None:
            self.__file = output_path+'/'+name  +'.scan'
        else:
            temp = []
            path_files = os.listdir(output_path)
            for i in range(len(path_files)):
                if ((path_files[i].find('.scan') != -1)):
                    numb_list = re.findall(r'\d+',path_files[i])
                    if len(numb_list)!=0:
                        temp.append(int(numb_list[-1]))
                
            if len(temp) ==0:
                name_file ='BAW_'+str(run_numb)+'_1'
            else: 
                name_file = 'BAW_'+str(run_numb)+'_'+str(np.array(temp).max()+1)
            self.__file = output_path+'/'+name_file  +'.scan'
        
    def get_file_name(self):
        return self.__file
    
    def set_general_info(self, data='16/03', T_baw=0.2, N_baw=1,raw_data_path = '' ,Note=None):
        
        '''
        some info here
        
        '''
        with h5py.File(self.__file,'a') as f:
            general_info=f.create_group('info')
        
            general_info.create_dataset('raw_data_path', data=str(raw_data_path) )
            general_info.create_dataset('date', data=str(data) )
            general_info.create_dataset('temperature', data=T_baw )
            general_info.create_dataset('baw_number', data=str(N_baw) )
            general_info.create_dataset('note', data=str(Note) )
        
        return
    
    def __read_header(self,fname):
        header = {}
        f = open(fname)
        while True:
            line = f.readline()
            if line[0] != '#':
                break
            else:
                line = line.replace('#','')
                lista = line.split()
                header[lista[0]] = float(lista[1])
        return header
    
    def write_resonances(self, path=None, file_name = 'Zoomed', label = '', desin='.dat', data_names=['freq', 'power'], data_pos=[0, 1]) :        
        
        '''
        some info here
        
        '''
        with h5py.File(self.__file,'a') as f:
            all_data=f.require_group('data')
        
        
            path_files = os.listdir(path)
            #controllare che i files siano tutti .dat

            count = 0
            for i in range(len(path_files)):
                if (path_files[i].find(file_name) != -1) & ((path_files[i].find(desin) != -1)):
                    file_path = path + '/'+ path_files[i]
                    
                    header = self.__read_header(file_path)

                    riso=all_data.require_group('resonance_'+str(count+1)) 
                    scan_riso=riso.require_group('parameters')
                    for key, item in header.items():
                        if key not in scan_riso:
                            scan_riso.create_dataset(key,  data=item )
                    
                    data = np.loadtxt(file_path)
                    data_riso=riso.require_group('data'+label)

                    for k in range(len(data_pos)):
                        data_riso.create_dataset(data_names[k], data=data[:,int(data_pos[k])]  )  

                    count = count+1
                else:
                    pass
            
            
        return
        

    def save_parameter(self,path,name,value):
 
        with h5py.File(self.__file,'a') as f:       
            f.create_dataset(path+'/'+name,data=value)
        return

    def delete_parameter(self,path,name):
        with h5py.File(self.__file,  "a") as f:
            del f[path+'/'+name]
        return



class ScanReader:
    
    def __init__(self, path_file):
        self.__file = path_file
        #self._file=h5py.File(path_file, "r")
        self._group_name = 'parameters'

    def _convert_to_dict(self, group):
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
        
    def _group_tags(self,location):
        with h5py.File(self.__file,'r') as f:
            return list(f['data'][list(f['data'].keys())[0]][location].keys())
    
    def set_group_name(self,name):
        self._group_name = name
        return
    
    def get_scan_info(self):
        with h5py.File(self.__file,'r') as f:
            return self._convert_to_dict(f['info'])
            
    def get_resonances_list(self):
        with h5py.File(self.__file,'r') as f:
            return list(f['data'].keys())
    
    def get_parameters_tags(self):
        return self._group_tags(self._group_name)

    def get_parameters(self,name=None):
        with h5py.File(self.__file,'r') as f:
            temp = []
            for el in f['data'].keys():
                value = f['data'][el][self._group_name][name]
                temp.append(np.array(value))
        return np.array(temp)
    
    def get_resonance(self,name=None,freq=None,loc=None,label=''):
        with h5py.File(self.__file,'r') as f:
            if freq is not None:
                ff = self.get_parameters('f0')
                resonance_name = self.get_resonances_list()[np.argmin(np.abs(ff-freq))]
            if name is not None:
                resonance_name = name
            if loc is not None:
                resonance_name = self.get_resonances_list()[loc]
            
            dic1 = self._convert_to_dict(f['data'][resonance_name][self._group_name])
            dic2 = self._convert_to_dict(f['data'][resonance_name]['data'+label])
            dic1.update(dic2)
            dic1['reso_name'] = resonance_name
        return dic1

    def get_resonance_name(self,freq=None,loc=None):
        with h5py.File(self.__file,'r') as f:
            if freq is not None:
                ff = self.get_parameters('f0')
                resonance_name = self.get_resonances_list()[np.argmin(np.abs(ff-freq))]
            if loc is not None:
                resonance_name = self.get_resonances_list()[loc]
        return resonance_name
