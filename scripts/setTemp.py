#! /usr/bin/python3

from instruments import ls350, kei2231A

import sys
import time
import numpy as np
from optparse import OptionParser
from datetime import datetime
from simple_pid import PID

parser = OptionParser()

parser.add_option("--target", type=float, dest="target", default=4.0)
(options, args) = parser.parse_args()

debug = True

min_voltage = 0.
max_voltage = 8.

min_temp_safe = 0.   #K
max_temp_safe = 25.  #K

sensorName = 'D4'

if options.target < min_temp_safe or options.target > max_temp_safe:
    print("### ERROR: set temperature outside allowed range ["+str(min_temp_safe)+"-"+str(max_temp_safe)+"]. Exiting...")
    sys.exit(-1)


ps = kei2231A.Keithley2231A()  #instantiate PowerSupply
tempSensor = ls350.LS350()  #instantiate the temp sensor

state = ps.check_state()
print(datetime.now())
print(">>> PS::state: "+str(state))
if state == 0:
    print("--- powering on the PS")
    ps.set_V(0.0)
    ps.set_state(1)
    time.sleep(2)
    state = ps.check_state()
    print(">>> PS::state: "+str(state))
    if state == 0:
        print("### ERROR: PS did not power on. Exiting...")
        sys.exit(-2)


curr_temp = tempSensor.meas_T(sensorName)

V = ps.meas_V()
new_voltage = V
print("--- [Current DUT temperature: "+str(curr_temp)+"° K]\n")
sys.stdout.flush()

pid = PID(0.5, 0., 1, setpoint=options.target)
pid.output_limits = (-2, 2)


tempReadings = np.array([], dtype=np.float64)
nLoops = 0
while True:
    try:

        temp = tempSensor.meas_T(sensorName)
        tempReadings = np.append(tempReadings,temp)

        if nLoops > 10:
            lastTen = tempReadings[-min(10,len(tempReadings)):] #RMS on last 10 readings
            rms = np.std(lastTen)
            print('RMS is:', rms)
            if rms < 0.01:
                break
        
        output = pid(temp)
        new_voltage += output
        
        #safety check
        new_voltage = min([max([new_voltage,min_voltage]),max_voltage])

        if debug:
            p, i, d = pid.components
            print("== DEBUG == P=", p, "I=", i, "D=", d)

        V = ps.meas_V()
        print(datetime.now())
        print("--- setting PS voltage to "+str(new_voltage)+" V    [DUT temperature: "+str(temp)+"° K]")
        ps.set_V(new_voltage)
        sleep_time = 5
        print("--- sleeping for "+str(sleep_time)+" s   [kill at any time with ctrl-C]\n")
        sys.stdout.flush()
        time.sleep(sleep_time)

        nLoops += 1

    
    except KeyboardInterrupt:
        print("--- powering off the PS")
        ps.set_state(0)
        time.sleep(2)
        state = ps.check_state()
        print(">>> PS::state: "+str(state))
        if state == 1:
            print("### ERROR: PS did not power off. Exiting...")
            sys.exit(-3)
        print("bye")
        break

print("byebye")
sys.exit(0)