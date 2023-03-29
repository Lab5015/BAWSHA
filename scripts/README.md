# howto

### launch a scan
1. launch a scan from 5e6 Hz to 10e6 Hz, saving the output files AND plots in a folder in /location/random/dumb_folder. The folder must exist.
   ```
   $ launcscan.py -p /location/random/dumb_folder -fmin 5e6 -fmax 10e6 -plot True
   ```
   **default parameters:** power -20 dBm (-pw 20), sweep points 801 (-npt 801), span large 10 kHz (-sl 10e3), ifbw large 300 Hz (-bwl 300), 
   span small 100 Hz (-sm 100), ifbw small 30 Hz (-bws 30), threshold 1000 Hz (-thr 1000), std 5 (-std 5)


### Create a .scan
1. Create an hdf5 file (example.scan) from txt raw data-
   ```
   $ createScan.py -fp /location/folder_txt -sp /location/to_save_output_file -n name_output_file -d date_of the run -t baw_temperature -bn baw_number 
   ```
   ```
   $ createScan.py -fp /home/user/raw_data -sp /home/user/data -n example -d 4/12/2050 -t 0.750 -bn 41 -note "This is an example" 
   ```

   **default parameters:** do the resonances fit at the end (-fit True), add a custom note (-note '')