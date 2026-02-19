add at "/etc/systemd/system/rfsoc_server.service"

```
[Unit]
Description=RFSoC Acquisition Server
After=network.target

[Service]
User=root
WorkingDirectory=/home/xilinx/SimBa/software/src/simba
ExecStart=/usr/bin/python3 server.py --mode service
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Activable with:

```
sudo systemctl daemon-reload
sudo systemctl enable rfsoc_server
sudo systemctl start rfsoc_server
```
