import numpy as np
import h5py
import os

class ScanWriter:
    
    '''
    some info here
    
    '''
    
    def __init__(self, name_file, output_path):
        
        '''
        some info here
        
        '''
        self._file=h5py.File(output_path+'/'+name_file  +'.scan', "w")
        
    def set_general_info(self, data='16/03', T_baw=0.2, N_baw=1, Note=None):
        
        '''
        some info here
        
        '''
        general_info=self._file.create_group('info')
        
        
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
    
    def write_resonances(self, path=None, file_name = 'Zoomed', desin='.dat', data_names=['freq', 'power'], data_pos=[0, 1]) :        
        
        '''
        some info here
        
        '''
        
        all_data=self._file.create_group('data')
        
        
        path_files = os.listdir(path)
        #controllare che i files siano tutti .dat

        for i in range(len(path_files)):
            if (path_files[i].find(file_name) != -1) & ((path_files[i].find(desin) != -1)):
                file_path = path + '/'+ path_files[i]
                
                header = self.__read_header(file_path)
                IFBW_riso=header['IFBW']
                power_riso=header['power']
                f_center = header['center']
            
                riso=all_data.create_group('resonance_'+str(i+1)) 
                scan_riso=riso.create_group('scan_info')
                scan_riso.create_dataset('ifbw',  data=IFBW_riso )
                scan_riso.create_dataset('input_power', data=power_riso)
                scan_riso.create_dataset('f_center', data=f_center)
                
                data = np.loadtxt(file_path)
                data_riso=riso.create_group('data')  
                
                for k in range(len(data_pos)):
                    data_riso.create_dataset(data_names[k], data=data[:,int(data_pos[k])]  )  
            else:
                pass
            
            
        return
    
    
    def close_file(self):
        
        self._file.close()
        
        return








class ScanReader:
    
    def __init__(self, path_file):
        self._file=h5py.File(path_file, "r")
        self._group_name = 'scan_info'

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
        return list(self._file['data'][list(self._file['data'].keys())[0]][location].keys())
    
    def set_group_name(self,name):
        self._group_name = name
        return
    
    def get_scan_info(self):
        return self._convert_to_dict(self._file['info'])
    
    def get_parameters_tags(self):
        return self._group_tags(self._group_name)

    def get_parameters(self,name=None):
        temp = []
        for el in self._file['data'].keys():
            value = self._file['data'][el][self._group_name][name]
            temp.append(np.array(value))
        return np.array(temp)
    
    def get_resonance(self,number=None,freq=None,loc=None):
        if freq is not None:
            f = self.get_parameters('f_center')
            resonance_name = list(self._file['data'].keys())[np.argmin(np.abs(f-freq))]
        if number is not None:
            resonance_name = 'resonance_'+str(number)
        if loc is not None:
            resonance_name = list(self._file['data'].keys())[loc]
            
        dic1 = self._convert_to_dict(self._file['data'][resonance_name][self._group_name])
        dic2 = self._convert_to_dict(self._file['data'][resonance_name]['data'])
        dic1.update(dic2)
        return dic1
        
    def close_file(self):
        self._file.close()
        return
