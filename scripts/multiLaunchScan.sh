#!/bin/bash

for temp in {5..12}
do
    echo "TARGET TEMP: $temp"

    time setTemp.py --target $temp > /tmp/logScan.txt
    sleep 300
    launchScan.py -fcen 4.99308e6  -sl 200 -sm 60 -bws 10 -bwl 100  -npt 1601   >> /tmp/logScan.txt #3C
    logTemp.py
    launchScan.py -fcen 5.50550e6  -sl 200 -sm 60 -bws 10 -bwl 100  -npt 1601   >> /tmp/logScan.txt #3B
    logTemp.py
    launchScan.py -fcen 9.34710e6  -sl 200 -sm 40 -bws 10 -bwl 100  -npt 1601   >> /tmp/logScan.txt #3A
    logTemp.py
    launchScan.py -fcen 8.39189e6  -sl 200 -sm 60 -bws 10 -bwl 100  -npt 1601   >> /tmp/logScan.txt #5C
    logTemp.py
    launchScan.py -fcen 9.24676e6  -sl 200 -sm 60 -bws 10 -bwl 100  -npt 1601   >> /tmp/logScan.txt #5B
    logTemp.py
    launchScan.py -fcen 15.8990e6  -sl 200 -sm 40 -bws 10 -bwl 100  -npt 1601   >> /tmp/logScan.txt #5A
    logTemp.py

done