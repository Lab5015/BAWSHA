import json
import os
import socket
from time import sleep

HOST = "212.189.204.163"
PORT_CTRL = 6000
PORT_DATA = 6001
SAVE_DIR = "./received_data"

os.makedirs(SAVE_DIR, exist_ok=True)


def send_cmd(cmd):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT_CTRL))
        s.sendall(json.dumps(cmd).encode())
        a = s.recv(1024).decode("utf-8")
        print(a)
        return a


def download_data():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT_DATA))
        while True:
            # Receive filename length
            raw_len = s.recv(4)
            if not raw_len:
                break
            fname_len = int.from_bytes(raw_len, "big")
            if fname_len == 0:
                print("[CLIENT] No more files.")
                break

            # Receive filename
            fname = s.recv(fname_len).decode()

            # Receive file size
            data_len = int.from_bytes(s.recv(8), "big")

            # Receive file content
            data = b""
            while len(data) < data_len:
                packet = s.recv(min(4096, data_len - len(data)))
                if not packet:
                    raise ConnectionError("Connection lost during file transfer")
                data += packet

            # Save file locally
            with open(os.path.join(SAVE_DIR, fname), "wb") as f:
                f.write(data)
            print(f"[CLIENT] Received and saved {fname}")


# test = send_cmd({"cmd": "state_info"})
# test = send_cmd(
#    {
#        "cmd": "config_lo",
#        "config": [
#            {"name": "0", "LO_frequency": 1000007, "resonance_frequency": 1000021},
#            {"name": "1", "LO_frequency": 5200007, "resonance_frequency": 5100021},
#            {"name": "2", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "3", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "4", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "5", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "6", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "7", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "8", "LO_frequency": 1000007, "resonance_frequency": 1000021},
#            {"name": "9", "LO_frequency": 5200007, "resonance_frequency": 5100021},
#            {"name": "10", "LO_frequency": 1000007, "resonance_frequency": 1000021},
#            {"name": "11", "LO_frequency": 5200007, "resonance_frequency": 5100021},
#            {"name": "12", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "13", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "14", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "15", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "16", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "17", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "18", "LO_frequency": 1000007, "resonance_frequency": 1000021},
#            {"name": "19", "LO_frequency": 5200007, "resonance_frequency": 5100021},
#            {"name": "20", "LO_frequency": 1000007, "resonance_frequency": 1000021},
#            {"name": "21", "LO_frequency": 5200007, "resonance_frequency": 5100021},
#            {"name": "22", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "23", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "24", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "25", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "26", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "27", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "28", "LO_frequency": 1000007, "resonance_frequency": 1000021},
#            {"name": "29", "LO_frequency": 5200007, "resonance_frequency": 5100021},
#            {"name": "30", "LO_frequency": 1000007, "resonance_frequency": 1000021},
#            {"name": "31", "LO_frequency": 5200007, "resonance_frequency": 5100021},
#            {"name": "32", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "33", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "34", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "35", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "36", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "37", "LO_frequency": 10200007, "resonance_frequency": 10100021},
#            {"name": "38", "LO_frequency": 1000007, "resonance_frequency": 1000021},
#            {"name": "39", "LO_frequency": 5200007, "resonance_frequency": 5100021},
#        ],
#    }
# )
send_cmd({"cmd": "stop"})
# send_cmd({"cmd": "start"})
# send_cmd({"cmd": "remove_files"})

# download_data()
