import subprocess
import time
import sys
from datetime import datetime
import serial
import pyvisa

##########################
class DPO3014():
    """Instrument class for Tektronix TBS1000C

    Args:
        * portname (str): port name
        * channel (str): channel name

    """

    def __init__(self, portname='TCPIP0::100.100.100.2::INSTR'):
        self.instr = pyvisa.ResourceManager('@py').open_resource(portname)
        print(self.instr.query("*IDN?"), "connected")
        self.instr.write("WFMOutpre:ENCdg ASCii") #set the output WF in ASCII
        self._AVG = 0       # Number of averages
        self._SR = int(1e3) # Sample Rate
        self._HS = 1e-3     # Horizontal time scale
        self._RL = 1e4

    def set_source(self, ch):
        """Set the source to readout"""
        return(self.instr.write("DATa:SOUrce CH"+str(ch)))

    def get_wf(self):
        """Acquire a wafe form"""
        return(self.instr.query("CURV?"))
    
    def query(self, myquery):
        return(self.instr.query(myquery))

    def write(self, myquery):
        return(self.instr.write(myquery))
    
    @property
    def AVG(self):
        "Define AVG property"
        return self._AVG

    @AVG.setter
    def AVG(self, value):
        "Set AVG attribute to value"
        self._AVG = int(value)
        self.write("ACQuireNUMAVg "+str(int(value)))

    def query_AVG(self):
       "Query AVG"
       return self.instr.query("ACQuireNUMAVg?")
    
    @property
    def SR(self):
        "Define the Sample Rate attribute"
        return self._SR

    @SR.setter
    def SR(self, value):
        "Set Sampling rate to value"
        self._SR = int(value)
        self.write("HORizontal:SAMPLERate "+str(int(value)))
    
    def query_SR(self):
        "Query SR value"
        print( self.instr.query("HORizontal:SAMPLERate?"))

    @property
    def HS(self):
        "Define the time scale property"
        return self._HS
        
    @HS.setter
    def HS(self,value):
        "Set Time scale to value"
        self._HS = value
        self.write("HORizontal:SCAle "+str(value))

    def query_HS(self):
        "Query HS"
        print(self.instr.query("HORizontal:SCAle?"))

    @property
    def RL(self):
        "Define the REcord Lenght property"
        return self._RL

    @RL.setter
    def RL(self, value):
        "Set thye record lenght to value"
        self._RL = int(value)
        self.write("HORizontal:RECOrdlength "+str(int(value)))

    def query_RL(self):
        "Query RL value"
        print(self.instr.query("HORizontal:RECOrdlength"))
