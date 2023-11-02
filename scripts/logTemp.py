#! /usr/bin/python3

from instruments import ls350
from datetime import datetime
import os

tempSensor = ls350.LS350()  #instantiate the temp sensor
curr_temp = tempSensor.meas_T('D4')

runFile = '/home/cmsdaq/Analysis/Data/last_run'
run = -1
with open(runFile, 'r') as f:
    run = f.read()

tempFile = '/home/cmsdaq/Analysis/Data/raw/run0'+run
os.system('mkdir -p ' + tempFile)
tempFile += '/tempLog.txt'

with open(tempFile, 'a') as f:
    f.write(str(datetime.now())+' ')
    f.write(' ----> '+str(curr_temp)+'\n')


