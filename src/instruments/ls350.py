import serial
import pyvisa
from pyvisa.constants import StopBits, Parity
import subprocess
import time
import sys
from datetime import datetime

class LS350():
    """Instrument class for LakeShore 350

    Args:
        * portname (str): port name

    """

    def __init__(self, portname='ASRL/dev/ls350::INSTR'):
        self.instr = pyvisa.ResourceManager('@py').open_resource(portname, baud_rate=57600, data_bits=7, parity=Parity.odd, stop_bits=StopBits.one)
        print(self.instr.query('*IDN?'))

    def query(self, query):
        """Pass a query to the power supply"""
        print(self.instr.query(query))
        
    def meas_T(self, sensor):
        """Return temperature"""
        myquery = 'KRDG? '+sensor
        return(float(self.instr.query(myquery)))
