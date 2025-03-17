#!/usr/bin/env python
import numpy as np
import matplotlib.pyplot as plt
import argparse
import os


from rw import scan_handler
from process import utils 

def power_beta(on,off):
    return (1-np.sqrt(10**(on/20)/10**(off/20)))/(1+np.sqrt(10**(on/20)/10**(off/20)))

def computeBeta(reso):
    freq = reso["freq"]
    pow = reso["power"]
    pOn = np.min(pow)
    pOff = pow[-1] #take the baseline far from the peak
    phase = reso['phase']
    phase = np.unwrap(phase)
    delta_phase = np.max(phase)-np.min(phase)

    if delta_phase > np.pi :  #over_coupled
        beta = 1/power_beta(pOn,pOff)
    else:
        beta = power_beta(pOn,pOff)

    return beta


def main():


    usage=''
    parser = argparse.ArgumentParser(description='find and save (.txt) all the resonance peaks between two frequencies', usage=usage)

    parser.add_argument("-fp", "--folder_path"   , dest="folder_path"   , type=str , help="folder path with txt files"  , default = '/home/cmsdaq/Analysis/Data/raw')
    parser.add_argument("-sp", "--save_path"    , dest="save_path"      , type=str , help="where to save the .scan file", default = '/home/cmsdaq/Analysis/Data/reco')
    parser.add_argument("-rn", "--run_number"    , dest="run_number"    , type=int , help="run_number"  , required = True) 
    parser.add_argument("-n",  "--name"          , dest="name"          , type=str , help="output file name"  , required = False,default = None) 
    
    parser.add_argument("-d", "--data"    , dest="data"    , type=str , help="date of the measure"  , required = True) 
    parser.add_argument("-t", "--temperature"    , dest="temp"    , type=str , help="temperature of the BAW (K)"  , required = True) 
    parser.add_argument("-bn", "--baw_number"    , dest="baw"    , type=str , help="baw number or label"  , required = True) 
    parser.add_argument("-note", "--note"    , dest="note"    , type=str , help="additional note"  , default = '') 
    
    parser.add_argument("-fit", "--fit", dest="fit", type=bool , help="do the fit "   , default = True)      

    args = parser.parse_args()


    # check if RAW data exist before doing anything
    if args.folder_path == '/home/cmsdaq/Analysis/Data/raw':
        raw_data_path = args.folder_path+'/run%04d' % (int(args.run_number))
    else:
        raw_data_path = args.folder_path
    print(raw_data_path)
    if not os.path.isdir(raw_data_path):
        print('RAW DATA NOT FOUND!')
        return

    writer = scan_handler.ScanWriter(args.run_number,args.save_path,name=args.name)
    print("Writing ", writer.get_file_name(), "...")
    writer.set_general_info(data = args.data,N_baw = args.baw, raw_data_path=raw_data_path, Note = args.note)
    T = str(args.temp)
    print("Setting temperature to", args.temp, " K")
    writer.set_temperature(args.temp)    
    writer.overwrite_temperature()
    print("Saving data...")
    writer.write_resonances(path=raw_data_path, data_names=['freq', 'power', 'phase'], data_pos=[0, 1, 2], file_name='Zoomed_peak_S11', label="S11")
    writer.write_resonances(path=raw_data_path, data_names=['freq', 'power', 'phase'], data_pos=[0, 1, 2], file_name='Zoomed_peak_S21', label="S21")
    writer.write_resonances(path=raw_data_path, data_names=['freq', 'power', 'phase'], data_pos=[0, 1, 2], file_name='Zoomed_peak_S22', label="S22")

    reader = scan_handler.ScanReader(writer.get_file_name())
    print("Temperature in the .scan (K): ",reader.get_temperatures())
    reader.set_temperature(args.temp)
    n_resonance = len(reader.get_resonances_list())
    print(n_resonance, " resonances were found!")

    if args.fit is True:    
        print("Fitting the resonances...")
        num = 1
        counter_wrong_raw = 0
        counter_wrong_bvd = 0
        counter_wrong_circle = 0
        for res_name in reader.get_resonances_list():
            
            hdfpath = 'data/'+T+"/"+res_name
            
            #fit the positive resonance S21
            reso = reader.get_resonance(name=res_name, label='S21')
            freq = reso['freq']
            power = reso['power']  
            phase = reso["phase"]
            print(freq.shape,freq[:2],res_name)
            
            print("Resonance ", num, "/", n_resonance)
            num +=1
            try:
                Q_raw,f0,depth = utils.Q_raw(freq,power)
                writer.save_parameter(hdfpath+'/parameters','Qr',Q_raw)
                writer.save_parameter(hdfpath+'/parameters','depth',depth)
                writer.save_parameter(hdfpath+'/parameters','f0',f0)
            except Exception as e: 
                print("Error in raw fit:",e)
                counter_wrong_raw += 1
                
            try:
                _,R,L,C,C0,Q0 = utils.fit_resonance_bvd(freq,power,phase)
                writer.save_parameter(hdfpath+'/parameters','Q0_bvd',Q0)
                writer.save_parameter(hdfpath+'/parameters','R',R)
                writer.save_parameter(hdfpath+'/parameters','L',L)
                writer.save_parameter(hdfpath+'/parameters','C',C)
                writer.save_parameter(hdfpath+'/parameters','C0',C0)                           
            except Exception as e: 
                print("Error in bvd fit:",e)
                counter_wrong_bvd += 1    
                
            try:
                _, Ql, Q0, b1, b2 = utils.fit_resonance_circle(reader.get_resonance(name=res_name, label='S21'),reader.get_resonance(name=res_name, label='S22'),
                                                         reader.get_resonance(name=res_name, label='S11'))

                writer.save_parameter(hdfpath+'/parameters','Ql_c',Ql)
                writer.save_parameter(hdfpath+'/parameters','Q0_c',Q0)
                writer.save_parameter(hdfpath+'/parameters','b1',b1)
                writer.save_parameter(hdfpath+'/parameters','b2',b2)
            except Exception as e: 
                print("Error in circle fit:",e)
                counter_wrong_circle += 1 
            '''
            try:
                Q_raw = utils.Q_raw(freq,power)[0] 
                popt, perr = utils.fit_resonance(freq,power,verbose=False)
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
                writer.save_parameter('data/'+res_name+'/parameters','gamma',gamma)
                writer.save_parameter('data/'+res_name+'/parameters','er_gamma',perr[1])
                #writer.save_parameter('data/'+res_name+'/parameters','er_f0',perr[2])
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
                writer.save_parameter('data/'+res_name+'/parameters','gamma',-2)
                writer.save_parameter('data/'+res_name+'/parameters','er_gamma',-2)
                #writer.save_parameter('data/'+res_name+'/parameters','er_f0',-2)
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
        '''
        print("All done! The raw fit procedure failed for ", counter_wrong_raw, " resonances.")    
        print("All done! The bvd fit procedure failed for ", counter_wrong_bvd, " resonances.")    
        print("All done! The circe fit procedure failed for ", counter_wrong_circle, " resonances.")    
if __name__ == "__main__":
    main()
