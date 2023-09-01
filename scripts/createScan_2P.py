#!/usr/bin/env python
import numpy as np
import matplotlib.pyplot as plt
import argparse
import os


from rw import scan_handler
from process import utils 

def power_beta(on,off):
    return (1-np.sqrt(10**(on/10)/10**(off/10)))/(1+np.sqrt(10**(on/10)/10**(off/10)))


def main():


    usage=''
    parser = argparse.ArgumentParser(description='find and save (.txt) all the resonance peaks between two frequencies', usage=usage)

    parser.add_argument("-fp", "--folder_path"   , dest="folder_path"   , type=str , help="folder path with txt files"  , default = '/home/cmsdaq/Analysis/Data/raw')
    parser.add_argument("-sp", "--save_path"    , dest="save_path"      , type=str , help="where to save the .scan file", default = '/home/cmsdaq/Analysis/Data/reco')
    parser.add_argument("-rn", "--run_number"    , dest="run_number"    , type=int , help="run_number"  , required = True) 
    
    parser.add_argument("-d", "--data"    , dest="data"    , type=str , help="date of the measure"  , required = True) 
    parser.add_argument("-t", "--temperature"    , dest="temp"    , type=float , help="temperature of the BAW (K)"  , required = True) 
    parser.add_argument("-bn", "--baw_number"    , dest="baw"    , type=float , help="baw_number"  , required = True) 
    parser.add_argument("-note", "--note"    , dest="note"    , type=str , help="additional note"  , default = '') 
    
    parser.add_argument("-fit", "--fit", dest="fit", type=bool , help="do the fit "   , default = True)      

    args = parser.parse_args()


    # check if RAW data exist before doing anything
    raw_data_path = args.folder_path+'/run%04d' % (int(args.run_number))
    if not os.path.isdir(raw_data_path):
        print('RAW DATA NOT FOUND!')
        return

    writer = scan_handler.ScanWriter(args.run_number,args.save_path)
    print("Writing ", writer.get_file_name(), "...")
    writer.set_general_info(data = args.data, T_baw = args.temp, N_baw = args.baw, raw_data_path=raw_data_path, Note = args.note)
    print("Saving data...")
    writer.write_resonances(path=raw_data_path, data_names=['freq', 'power', 'phase'], data_pos=[0, 1, 2], file_name='Zoomed_peak_S11', label="S11")
    writer.write_resonances(path=raw_data_path, data_names=['freq', 'power', 'phase'], data_pos=[0, 1, 2], file_name='Zoomed_peak_S21', label="S21")

    reader = scan_handler.ScanReader(writer.get_file_name())
    n_resonance = len(reader.get_resonances_list())
    print(n_resonance, " resonances were found!")

    if args.fit is True:    
        print("Fitting the resonances...")
        num = 1
        counter_wrong = 0
        for res_name in reader.get_resonances_list():
            
            #compute the Beta correction on the negative S11 resonance
            reso = reader.get_resonance(name=res_name, label='S11')
            freq = reso["freq"]
            pow = reso["power"]
            pOn = np.min(pow)
            pOff = np.max(pow)
            beta2 = 1/power_beta(pOn,pOff)
            Qcorr = (1 + 2*beta2)
            writer.save_parameter('data/'+res_name+'/parameters','Qcorr',Qcorr)

            #fit the positive resonance S21
            reso = reader.get_resonance(name=res_name, label='S21')
            freq = reso['freq']*1e-6
            power = reso['power']
            print("Resonance ", num, "/", n_resonance)
            num +=1
            try:
                popt, perr = utils.fit_resonance(freq,power,verbose=False,conversion='dBm-W')
                norm = popt[0]
                gamma  = popt[1]  #MHz
                f0     = popt[2]  #MHz
                offset = popt[-2] #dBm
                m      = popt[-3]
                asim = popt[-1]
                gamma_l = asim*gamma*2/(asim + 1.)
                gamma_r = gamma*2/(asim + 1.)
                depth = (1./(np.pi*gamma_l*2)+1./(np.pi*gamma_r*2))*norm
                offset_at_peak = offset + m*f0
                Q_factor = f0/(gamma*2)
                err = ((perr[2]/(popt[1]*2))**2+(popt[2]*perr[1]/(2*popt[2]**2))**2)**0.5
                x = 10**(-depth/10) / 4
                R_par = 50 * (x + np.sqrt(x)) / (1-x)
                R_baw = 50*R_par / (50-R_par)
                C_baw = 1. / (2. * np.pi*f0*1e6 * Q_factor * R_baw)
                L_baw = 1. / (4. * (np.pi**2) * ((f0*1e6)**2) * C_baw)
                writer.save_parameter('data/'+res_name+'/parameters','Q',Q_factor)
                writer.save_parameter('data/'+res_name+'/parameters','er_Q',err)                
                writer.save_parameter('data/'+res_name+'/parameters','depth',depth)
                writer.save_parameter('data/'+res_name+'/parameters','gamma',gamma)
                writer.save_parameter('data/'+res_name+'/parameters','er_gamma',perr[1])
                writer.save_parameter('data/'+res_name+'/parameters','f0',f0)
                writer.save_parameter('data/'+res_name+'/parameters','er_f0',perr[2])
                writer.save_parameter('data/'+res_name+'/parameters','offset_at_peak',offset_at_peak)
                writer.save_parameter('data/'+res_name+'/parameters','norm',norm)
                writer.save_parameter('data/'+res_name+'/parameters','er_norm',perr[0])
                writer.save_parameter('data/'+res_name+'/parameters','asim',asim)
                writer.save_parameter('data/'+res_name+'/parameters','er_asim',perr[-1])
                writer.save_parameter('data/'+res_name+'/parameters','L_baw',L_baw)
                writer.save_parameter('data/'+res_name+'/parameters','C_baw',C_baw)
                writer.save_parameter('data/'+res_name+'/parameters','R_baw',R_baw)
                writer.save_parameter('data/'+res_name+'/parameters','R_par',R_par)
                writer.save_parameter('data/'+res_name+'/parameters','x',x)
            except:
                counter_wrong +=1
                writer.save_parameter('data/'+res_name+'/parameters','Q',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_Q',-2)                
                writer.save_parameter('data/'+res_name+'/parameters','depth',-2)
                writer.save_parameter('data/'+res_name+'/parameters','gamma',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_gamma',-2)
                writer.save_parameter('data/'+res_name+'/parameters','f0',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_f0',-2)
                writer.save_parameter('data/'+res_name+'/parameters','offset_at_peak',-2)
                writer.save_parameter('data/'+res_name+'/parameters','norm',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_norm',-2)
                writer.save_parameter('data/'+res_name+'/parameters','asim',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_asim',-2)
                writer.save_parameter('data/'+res_name+'/parameters','L_baw',-2)
                writer.save_parameter('data/'+res_name+'/parameters','C_baw',-2)
                writer.save_parameter('data/'+res_name+'/parameters','R_baw',-2)
                writer.save_parameter('data/'+res_name+'/parameters','R_par',-2)
                writer.save_parameter('data/'+res_name+'/parameters','x',-2)

        print("All done! The fit procedure failed for ", counter_wrong, " resonances. For them a value of -2 has been assigned.")    
        
if __name__ == "__main__":
    main()
