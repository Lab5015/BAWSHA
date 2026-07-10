# RFSoC Acquisition Software

This package provides the software interface for the RFSoC lock-in acquisition system. It includes the acquisition server running on the RFSoC board, a TCP client for remote communication, configuration utilities, and hardware drivers.

The project can be installed either with **Poetry** or **pip**.

## Installation

### Using Poetry

```bash
poetry install
```

### Using pip

```bash
pip install .
```

> **Note:** Accessing the RFSoC hardware requires administrator privileges. The server should therefore be started with `sudo -E` so that the Python environment is preserved.

## Running the server

For testing or development, the acquisition server can be started manually:

```bash
sudo -E python server.py
```

## Running as a system service (recommended)

For production deployments, it is recommended to run the acquisition server as a `systemd` service.

Create the file:

```
/etc/systemd/system/rfsoc_server.service
```

with the following contents:

```ini
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

Then enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rfsoc_server
sudo systemctl start rfsoc_server
```

Useful commands:

```bash
sudo systemctl status rfsoc_server
sudo systemctl restart rfsoc_server
sudo journalctl -u rfsoc_server -f
```

## Client

The client connects to the acquisition server and configures it and starts it:

Look into the file for some examples.

```bash
python client.py
```

Ensure that the server IP address and port are correctly configured before connecting.
