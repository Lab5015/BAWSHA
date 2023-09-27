import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit 
from scipy.integrate import simps


def cauchy(x,gamma,center):
    return (1./np.pi)*gamma/((x-center)**2+gamma**2)

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

def fit_func(x,norm,gamma,center,m,offset,asim):
    #out = offset+x*m-norm*cauchy(x,gamma,center)
    out = offset+x*m+norm*cauchy_asim(x,gamma,center,asim)
    return out


def fit_resonance(freq,power,auto=True,conversion='dBm-W',thr=0.5,n=10,verbose=True):
    if conversion == 'dBm-W':
        print('conversion is:',conversion)
        power = (10**(power/20))  # dBm to mW
    
    if auto is True:
        MaxMin = np.max(power)-np.min(power)
        pos = np.where(power<=np.max(power)-thr*MaxMin)[0]
        pmin = pos[0]-len(pos)*n
        pmax = pos[-1]+len(pos)*n
        if pmin <0:
            pmin = 0
        if pmax>len(power):
            pmax=len(power)
        freq=freq[pmin:pmax]
        power=power[pmin:pmax]


    center_guess = -1
    if np.fabs(np.max(power)) > np.fabs(np.min(power)):
        center_guess = freq[np.argmax(power)]  #positive peak
    else:
        center_guess = freq[np.argmin(power)]  #negative peak

    gamma_guess = (freq[1]-freq[0])*5
    m_guess = np.polyfit(freq,power,deg=1)[0]
    offset_guess = np.polyfit(freq,power,deg=1)[1]
    norm_guess = simps(power,freq)
    asim_guess = 1
    
    initial_guess = np.array([norm_guess,gamma_guess,center_guess,m_guess,offset_guess,asim_guess])
    bounds = np.array([[-1e-3,(freq[-1]-freq[0])/1000,freq[0],np.min([m_guess/10,m_guess*10]),np.min([offset_guess/10,offset_guess*10]),0],
                       [1e-3,100*(freq[-1]-freq[0]),freq[-1],np.max([m_guess/10,m_guess*10]),np.max([offset_guess/10,offset_guess*10]),100]])

    popt,pcov = curve_fit(fit_func,xdata=freq,ydata=power,p0=initial_guess,bounds=bounds)

    perr = (np.diag(pcov))**0.5

    if verbose is True:
        print(initial_guess,'\n',bounds)
        for i in range(len(popt)):
            print('Parametro ', i+1, ': ', popt[i], ' +/- ', perr[i])
            
        Q_factor = popt[2]/(popt[1]*2)
        err = ((perr[2]/(popt[1]*2))**2+(popt[2]*perr[1]/(2*popt[2]**2))**2)**0.5
        print('Q = ' + "{:.2e}".format(Q_factor),' +/- ', err)
        
        plt.plot(freq,power,'.',c='k',label='data')
        plt.plot(freq,fit_func(freq,*popt),color='r',label='Fit')
        plt.grid(alpha=0.6)
        plt.legend()
        plt.show()
        return
    else:
        return popt, perr
