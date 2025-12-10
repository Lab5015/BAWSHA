import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit 
try :
    from scipy.integrate import simpson as simps
except:
    from scipy.integrate import simps
from iminuit import cost,Minuit,describe
from scipy import interpolate
from scipy import optimize
import iminuit


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
    
def Q_raw(freq,power,thr=0.5,conversion='dB-lin',skip=10):
    power = power[skip:]
    freq = freq[skip:]

    if conversion == 'dB-lin':
        power = (10**(power/20))  # dB(W) to voltage ratio                                                                                                                                                   
    if conversion == 'dBm-W':
        power = (10**(power/10))  # dB(W) to voltage ratio                                                                                                                                                    

    pos_max = np.argmax(power)
    par = np.polyfit(np.arange(5),power[pos_max-2:pos_max+3],deg=2)
    x_max = -par[1]/(2*par[0])
    y_max = np.poly1d(par)(x_max)
    pos_thr =np.where(power>=y_max*thr)[0][[0,-1]]
    
    m, q = np.polyfit([pos_thr[0]-1,pos_thr[0]],power[pos_thr[0]-1:pos_thr[0]+1],deg=1)
    x1 = (y_max*thr-q)/m

    m, q = np.polyfit([pos_thr[1],pos_thr[1]+1],power[pos_thr[1]:pos_thr[1]+2],deg=1)
    x2 = (y_max*thr-q)/m

    dF = (x2-x1)*(freq[1]-freq[0])
    f0 = freq[pos_max-2]+x_max*(freq[1]-freq[0])
    Q = f0 / dF
    return Q, f0, y_max


def fit_resonance_old(freq,power,auto=True,conversion='dB-lin',thr=0.5,n=10,verbose=True):
    '''
    old, fit the resonance with an asymmetric cauchy
    '''
    if conversion == 'dB-lin':
        print('conversion is:',conversion)
        power = (10**(power/20))  # dB(W) to voltage ratio
    if conversion == 'dBm-W':
        print('conversion is:',conversion)
        power = (10**(power/10))  # dB(W) to voltage ratio
                
    power_original = power
    freq_original = freq    
    
    if auto is True:
        MaxMin = np.max(power)-np.min(power)
        pos = np.where(power>=np.min(power)+thr*MaxMin)[0]
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
    bounds = np.array([[0,(freq[-1]-freq[0])/1000,freq[0],np.min([m_guess/10,m_guess*10]),np.min([offset_guess/10,offset_guess*10]),0],
                       [100*norm_guess,100*(freq[-1]-freq[0]),freq[-1],np.max([m_guess/10,m_guess*10]),np.max([offset_guess/10,offset_guess*10]),100]])


    if verbose is True:
        print(initial_guess,'\n',bounds)


    popt,pcov = curve_fit(fit_func,xdata=freq,ydata=power,p0=initial_guess,bounds=bounds)

    perr = (np.diag(pcov))**0.5

    if verbose is True:
        for i in range(len(popt)):
            print('Parametro ', i+1, ': ', popt[i], ' +/- ', perr[i])
            
        Q_factor = popt[2]/(popt[1]*2)
        err = ((perr[2]/(popt[1]*2))**2+(popt[2]*perr[1]/(2*popt[2]**2))**2)**0.5
        print('Q = ' + "{:.2e}".format(Q_factor),' +/- ', err)
        
        plt.plot(freq_original,power_original,'.',c='k',label='Data')
        plt.plot(freq,power,'+',c='b',label='Fit Data')
        plt.plot(freq_original,fit_func(freq_original,*popt),color='r',label='Fit')
        plt.grid(alpha=0.6)
        plt.legend()
        plt.show()
        return
    else:
        return popt, perr
        
        
def fit_minuit_bvd(x,L,fc,Y):
    
    omega = np.pi*2*x #x sono le frequenze

    LC = 1./(fc*np.pi*2)**2
    C = LC/L

    R = 1./interpolate.interp1d(x,np.real(Y))(fc)

    C0 = (interpolate.interp1d(x,np.imag(Y))(fc))*(LC**0.5)
    
    Yb = (1j*omega*C0+(1j*omega*L-1j/(omega*C)+R)**(-1))
    return np.abs(Yb)        
        

def set_parameter(minuit_obj=None,name=None,dictionary={}):

    dic={"p0":None,"pmin":None, "pmax":None,"step":None,"fixed":False}
    for key in dic.keys():
        if key in dictionary.keys():
            dic[key] = dictionary[key] 
    
    minuit_obj.values[name] = dic["p0"]
    minuit_obj.limits[name]=(dic["pmin"],dic["pmax"])
    if dic["step"] is not None:
        minuit_obj.errors[name]=dic["step"]
    minuit_obj.fixed[name]=dic["fixed"]
    return 
    
            
        
def fit_resonance_bvd(freq,power,phase,conversion='dB-lin',skip=10,dicL = {"p0":100,"pmin":0},dicFc = None, npt_std=30):
    '''
    resonance fit assuming BVD circuit model
    '''
    if conversion == 'dB-lin':
        power = (10**(power/20))  # dB(W) to voltage ratio
    if conversion == 'dBm-W':
        power = (10**(power/10))  # dB(W) to voltage ratio
    
    S = power[skip:]
    freq = freq[skip:]
    phase = phase[skip:]
    
    real = np.sqrt((S**2)/(1+np.tan(phase)**2))  
    imag = np.tan(phase)*real
    
    Z = 2*50*(real/(S**2)-1j*imag/(S**2) -1)      #impedance
    Y = 1./Z                                      #admittance

    unc_Y = np.min([np.std(Y[:npt_std]), np.std(Y[-npt_std:])])

    fitfunc = lambda x,L,fc : fit_minuit_bvd(x,L,fc,Y)
    c = cost.LeastSquares(freq, np.abs(Y), unc_Y, fitfunc,verbose=0)

    m1 = Minuit(c,L=0,fc=0)

    L0 = 100
    fc0 = freq[np.argmax(np.real(Y))]

    set_parameter(m1,'L',dicL)
    if dicFc is None:
        set_parameter(m1,'fc',{"p0":fc0,"pmin":fc0-20,"pmax":fc0+20})
    else:
        set_parameter(m1,'fc',dicFc)
    m1.migrad()
    
    fc = m1.params["fc"].value
    L = m1.params["L"].value
    LC = 1./(fc*np.pi*2)**2
    C = LC/L
    R = 1./interpolate.interp1d(freq,np.real(Y))(fc)
    C0 = (interpolate.interp1d(freq,np.imag(Y))(fc))*(LC**0.5)
    Q0 = 1/R*((L/C)**0.5)
    return m1, R,L,C,C0,Q0
    
    
def fit_minuit_gregory(x,rSd,iSd,d,delta, Ql, fl,phi,A):
    Sd = (rSd + 1j*iSd)
    t = 2*(x-fl)/fl
    K = np.exp(-2j*delta)/(1+1j*Ql*t)
    # print('fl[MHz]: ', fl/1e6, ' d: ', d)
    return A*np.exp(-1j*phi)*(Sd +d*K)
    
    

def circlefit(x,y,xc,yc):
    def calc_R(xc, yc):
        """ calculate the distance of each 2D points from the center (xc, yc) """
        return ((x-xc)**2 + (y-yc)**2)**0.5

    def f_2(c):
        """ calculate the algebraic distance between the data points and the mean circle centered at c=(xc, yc) """
        Ri = calc_R(*c)
        return Ri - np.mean(Ri)

    center_estimate = xc, yc
    center_2, ier = optimize.leastsq(f_2, center_estimate)

    xc_2, yc_2 = center_2
    Ri_2       = calc_R(*center_2)
    R_2        = Ri_2.mean()
    residu_2   = sum((Ri_2 - R_2)**2)
    return xc_2,yc_2,R_2
    
class MinimizeFunction:
    def __init__(self,model, real, imag, freq, unc_real, unc_imag):
        self.fc = model
        self.real = real
        self.imag = imag
        self.freq = freq
        self.unc_real = unc_real
        self.unc_imag = unc_imag
        self.func_code = iminuit.util.make_func_code(describe(self.fc)[1:])
        return
        
class MinFunc(MinimizeFunction):
    
    def __init__(self,model, real , imag,freq, unc_real, unc_imag):
        MinimizeFunction.__init__(self,model, real, imag,freq, unc_real, unc_imag)
        return
    
    def __call__(self,*par):
        out = (self.real-np.real(self.fc(self.freq,*par)))**2/self.unc_real**2 + (self.imag-np.imag(self.fc(self.freq,*par)))**2/self.unc_imag**2
        
        return np.sum(out)
    

def fit_resonance_circle(reso21=None,reso22=None,reso11=None,conversion='dB-lin',skip=10, npt_std=30,
                         dicQl = {"p0":1e5,"pmin":1e2,"pmax":1e9},dicA = {"p0":1,"pmin":0},dicPhi = {"p0":0,"pmin":-np.pi,"pmax":np.pi},
                         dicFl = None,wm=0.1,span_peak=100):
                         
                         
    '''
    resonance fit with model from Gregory's manual
    '''
    if conversion == 'dB-lin':
        power = (10**(reso21["power"]/20))  # dB(W) to voltage ratio
    if conversion == 'dBm-W':
        power = (10**(reso21["power"]/10))  # dB(W) to voltage ratio
    
    S = power[skip:]
    freq = reso21["freq"][skip:]
    phase = reso21["phase"][skip:]
    
    real = np.sqrt((S**2)/(1+np.tan(phase)**2))  
    imag = np.tan(phase)*real

    unc_r = np.min([np.std(real[:npt_std]), np.std(real[-npt_std:])])
    unc_i = np.min([np.std(imag[:npt_std]), np.std(imag[-npt_std:])])
    
    if (np.argmax(real)-span_peak//2) < 0:
        span_peak = 2*np.argmax(real)
    if (np.argmax(real)+span_peak//2) > len(real):
        span_peak = (len(real)-np.argmax(real))*2
    
    unc_real = np.ones(len(real))
    unc_real[np.argmax(real)-span_peak//2:np.argmax(real)+span_peak//2] = np.append(np.linspace(wm,1,span_peak//2)[::-1],np.linspace(wm,1,span_peak//2))
    unc_real = unc_real*unc_r
 
    if (np.argmax(imag)-span_peak//2) < 0:
        span_peak = 2*np.argmax(real)
    if (np.argmax(imag)+span_peak//2) > len(imag):
        span_peak = (len(imag)-np.argmax(imag))*2
           
    unc_imag = np.ones(len(imag))
    unc_imag[np.argmax(imag)-span_peak//2:np.argmax(imag)+span_peak//2] = np.append(np.linspace(wm,1,span_peak//2)[::-1],np.linspace(wm,1,span_peak//2))
    unc_imag = unc_imag*unc_i      
    

    c = MinFunc(fit_minuit_gregory, real, imag, freq, unc_real, unc_imag)

    m1 = Minuit(c,rSd=(real[0] + real[-1])/2,iSd=(imag[0] + imag[-1])/2,d=0,delta=0,Ql=5e5,fl=freq[np.argmax(S)],phi=0,A=1)

    fmax = freq[np.argmax(S)]
    if dicFl is None:
        dicFl = {"p0":fmax, "pmin":fmax-40, "pmax":fmax+40}
    set_parameter(m1,'Ql',dicQl)
    set_parameter(m1,'fl',dicFl)
    set_parameter(m1,'d',{"p0":np.abs(np.max(real)-np.min(real)),"pmin":0})
    set_parameter(m1,'A',dicA)
    set_parameter(m1,'phi',dicPhi)
    set_parameter(m1,'delta',{"p0": 0.12, "pmin": -np.pi, "pmax": np.pi})

    m1.migrad()

    obj = [reso22,reso11]
    diameters = []
    for i in range(2):
        if obj[i] is not None:
            S = (10**(obj[i]["power"]/20))[skip:]
            freq = obj[i]["freq"][skip:]
            phase = obj[i]["phase"][skip:]
            real = np.sqrt((S**2)/(1+np.tan(phase)**2))  # +/-
            imag = np.tan(phase)*real
            xc, yc,radius =circlefit(real,imag,np.mean(real),np.mean(imag))
            diameters.append(2*radius)
        else:
            diameters.append(0)
        
    beta1 = diameters[0]/(2-diameters[0]-diameters[1])
    beta2 = diameters[1]/(2-diameters[0]-diameters[1])

    Ql = m1.params["Ql"].value
    Q0 = Ql*(1+beta1+ beta2)
    
    return m1, Ql, Q0, beta1, beta2
