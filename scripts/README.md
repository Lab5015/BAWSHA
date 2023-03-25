# howto

### launch a scan
1. launch a scan from 5e6 Hz to 10e6 Hz, saving the output files AND plots in a folder in /location/random/dumb_folder. The folder must exist.
   ```
   $ launcscan.py -p /location/random/dumb_folder -fmin 5e6 -fmax 10e6 -plot True
   ```
   **default parameters:** power -20 dBm (-pw 20), sweep points 801 (-npt 801), span large 10 kHz (-sl 10e3), ifbw large 300 Hz (-bwl 300), 
   span small 100 Hz (-sm 100), ifbw small 30 Hz (-bws 30), threshold 1000 Hz (-thr 1000), std 5 (-std 5)