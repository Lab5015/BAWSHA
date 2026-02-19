# Lock-in Acquisition and Transfer System

This project performs continuous acquisition from multiple digital lock-in amplifiers on a PYNQ-based system,
saves the data locally in compressed NumPy format, and exposes a TCP server for clients to retrieve the most recent data.

## Features

- Acquisition of I/Q data at configurable frequencies using DMA
- Asynchronous file saving to avoid blocking the acquisition loop
- TCP server running on a fixed IP and port to serve latest `.npz` files
- Remote client can connect, fetch data, and trigger automatic deletion

## Usage

### On the Acquisition Device (Server)

1. Ensure the PYNQ board is set up with a static IP (e.g., `192.168.0.0`)
2. Run the acquisition script:
   ```bash
   sudo -E python server.py
   ```

### On the Storage Device (Client)

1. Ensure the IP and port configuration in `client.py` is correct
2. Run the script to download latest files:
   ```bash
   python client.py
   ```
