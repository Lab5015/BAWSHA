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
