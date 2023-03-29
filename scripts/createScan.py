#!/usr/bin/env python
import numpy as np
import matplotlib.pyplot as plt
import argparse
from scipy.optimize import curve_fit 

from rw import scan_handler


#usefull functions for fit
def cauchy_asim(x,gamma,center,asim): #the gamma are HWHM
    gamma = gamma*2
    gamma_l = asim*gamma/(asim + 1.)
    gamma_r = gamma/(asim + 1.)
    if isinstance(x,float):
        if x < center:
            y = (gamma_l**2 )/ ((x - center)**2 + gamma_l**2) 

            if x >= center:
                y = (gamma_r**2 )/ ((x - center)**2 + gamma_r**2) 
    else:
        pos_vec = np.where(x >= center)[0]
        pos = int(pos_vec[0]) 
        SS = x[0:pos]
        DD = x[pos:int(len(x))]
        
        numerator1 = gamma_l**2
        denominator1 = (SS - center)**2 + gamma_l**2
        y1 = numerator1/denominator1
        
        numerator2 = gamma_r**2
        denominator2 = (DD - center)**2 + gamma_r**2
        y2 = numerator2/denominator2
        
        y = np.append(y1,y2)
        norm1 = 1./(np.pi*gamma_l*2)
        norm2 = 1./(np.pi*gamma_r*2)
        y = y *(norm1 + norm2)

    return y

def fit_func(x,norm,gamma,center,m,offset,asim):   #this is the fit function
    out = offset+x*m-norm*cauchy_asim(x,gamma,center,asim)
    return out


def main():


    usage=''
    parser = argparse.ArgumentParser(description='find and save (.txt) all the resonance peaks between two frequencies', usage=usage)

    parser.add_argument("-fp", "--folder_path"   , dest="folder_path"   , type=str , help="folder path with txt files"      , required = True)
    parser.add_argument("-sp", "--save_path"    , dest="save_path"    , type=str , help="where to save the .scan file"  , required = True)
    parser.add_argument("-n", "--name"    , dest="name"    , type=str , help="name of the file"  , required = True) 
    
    parser.add_argument("-d", "--data"    , dest="data"    , type=str , help="date of the measure"  , required = True) 
    parser.add_argument("-t", "--temperature"    , dest="temp"    , type=float , help="temperature of the BAW (K)"  , required = True) 
    parser.add_argument("-bn", "--baw_number"    , dest="baw"    , type=float , help="baw_number"  , required = True) 
    parser.add_argument("-note", "--note"    , dest="note"    , type=str , help="additional note"  , default = '') 
    
    parser.add_argument("-fit", "--fit", dest="fit", type=bool , help="do the fit "   , default = True)      


    
    args = parser.parse_args()


    print("Writing ", args.name, ".scan in ", args.save_path, "...")
    writer = scan_handler.ScanWriter(args.name,args.save_path)
    writer.set_general_info(data=args.data,T_baw = args.temp, N_baw = args.baw, Note = args.note)
    print("Saving data...")
    writer.write_resonances(path=args.folder_path)
    
    reader = scan_handler.ScanReader(args.save_path+"/"+args.name+'.scan')
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
                center_guess = freq[np.argmin(power)]
                gamma_guess = (freq[1]-freq[0])*5
                m_guess = np.polyfit(freq,power,deg=1)[0]
                offset_guess = np.polyfit(freq,power,deg=1)[1]
                norm_guess = 1e-6
                asim_guess = 1

                initial_guess = np.array([norm_guess,gamma_guess,center_guess,m_guess,offset_guess,asim_guess])
                bounds = np.array([[0,(freq[-1]-freq[0])/1000,freq[0],np.min([m_guess/10,m_guess*10]),np.min([offset_guess/10,offset_guess*10]),0],
                               [1e-4,(freq[-1]-freq[0])*100,freq[-1],np.max([m_guess/10,m_guess*10]),np.max([offset_guess/10,offset_guess*10]),100]])

                popt,pcov = curve_fit(fit_func,xdata=freq,ydata=power,p0=initial_guess,bounds=bounds)
                perr = (np.diag(pcov))**0.5

                norm = popt[0]
                gamma = popt[1]  #MHz
                center = popt[2] #MHz
                depth = np.max(popt[0]*cauchy_asim(freq,popt[1],popt[2],popt[-1]))
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
                writer.save_parameter('data/'+res_name+'/parameters','asim',popt[-1])
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
