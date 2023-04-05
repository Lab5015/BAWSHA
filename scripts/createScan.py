#!/usr/bin/env python
import numpy as np
import matplotlib.pyplot as plt
import argparse


from rw import scan_handler
from process import utils 



def main():


    usage=''
    parser = argparse.ArgumentParser(description='find and save (.txt) all the resonance peaks between two frequencies', usage=usage)

    parser.add_argument("-fp", "--folder_path"   , dest="folder_path"   , type=str , help="folder path with txt files"      , required = True)
    parser.add_argument("-sp", "--save_path"    , dest="save_path"    , type=str , help="where to save the .scan file"  , required = True)
    parser.add_argument("-rn", "--run_number"    , dest="run_number"    , type=int , help="run_number"  , required = True) 
    
    parser.add_argument("-d", "--data"    , dest="data"    , type=str , help="date of the measure"  , required = True) 
    parser.add_argument("-t", "--temperature"    , dest="temp"    , type=float , help="temperature of the BAW (K)"  , required = True) 
    parser.add_argument("-bn", "--baw_number"    , dest="baw"    , type=float , help="baw_number"  , required = True) 
    parser.add_argument("-note", "--note"    , dest="note"    , type=str , help="additional note"  , default = '') 
    
    parser.add_argument("-fit", "--fit", dest="fit", type=bool , help="do the fit "   , default = True)      


    
    args = parser.parse_args()


    writer = scan_handler.ScanWriter(args.run_number,args.save_path)
    print("Writing ", writer.get_file_name(), "...")
    writer.set_general_info(data=args.data,T_baw = args.temp, N_baw = args.baw, raw_data_path=args.folder_path,Note = args.note)
    print("Saving data...")
    writer.write_resonances(path=args.folder_path,data_names=['freq', 'power','phase'], data_pos=[0, 1, 2])
    
    reader = scan_handler.ScanReader(writer.get_file_name())
    n_resonance = len(reader.get_resonances_list())
    print(n_resonance, " resonances were found!")

    if args.fit is True:    
        print("Fitting the resonances...")
        num = 1
        counter_wrong = 0
        for res_name in reader.get_resonances_list():
            reso = reader.get_resonance(name=res_name)
            freq = reso['freq']*1e-6
            power = reso['power']
            
            print("Resonance ", num, "/", n_resonance)
            num +=1
            try:
                popt, perr = utils.fit_resonance(freq,power,verbose=False)
                
                norm = popt[0]
                gamma = popt[1]  #MHz
                center = popt[2] #MHz
                asim = popt[-1]
                gamma_l = asim*gamma*2/(asim + 1.)
                gamma_r = gamma*2/(asim + 1.)
                
                depth = (1./(np.pi*gamma_l*2)+1./(np.pi*gamma_r*2))*norm
                Q_factor = center/(gamma*2)
                err = ((perr[2]/(popt[1]*2))**2+(popt[2]*perr[1]/(2*popt[2]**2))**2)**0.5
                
                writer.save_parameter('data/'+res_name+'/parameters','Q',Q_factor)
                writer.save_parameter('data/'+res_name+'/parameters','er_Q',err)                
                writer.save_parameter('data/'+res_name+'/parameters','depth',depth)
                writer.save_parameter('data/'+res_name+'/parameters','gamma',gamma)
                writer.save_parameter('data/'+res_name+'/parameters','er_gamma',perr[1])
                writer.save_parameter('data/'+res_name+'/parameters','f0',center)
                writer.save_parameter('data/'+res_name+'/parameters','er_f0',perr[2])
                writer.save_parameter('data/'+res_name+'/parameters','norm',norm)
                writer.save_parameter('data/'+res_name+'/parameters','er_norm',perr[0])
                writer.save_parameter('data/'+res_name+'/parameters','asim',asim)
                writer.save_parameter('data/'+res_name+'/parameters','er_asim',perr[-1])
                
            except:
                counter_wrong +=1
                writer.save_parameter('data/'+res_name+'/parameters','Q',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_Q',-2)                
                writer.save_parameter('data/'+res_name+'/parameters','depth',-2)
                writer.save_parameter('data/'+res_name+'/parameters','gamma',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_gamma',-2)
                writer.save_parameter('data/'+res_name+'/parameters','f0',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_f0',-2)
                writer.save_parameter('data/'+res_name+'/parameters','norm',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_norm',-2)
                writer.save_parameter('data/'+res_name+'/parameters','asim',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_asim',-2)
            
        print("All done! The fit procedure failed for ", counter_wrong, " resonances. For them a value of -2 has been assigned.")    
        
if __name__ == "__main__":
    main()
