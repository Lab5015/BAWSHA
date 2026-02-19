import json
import os
import socket

HOST = "212.189.204.163"
PORT_CTRL = 6000
PORT_DATA = 6001
SAVE_DIR = "./received_data"

os.makedirs(SAVE_DIR, exist_ok=True)


def send_cmd(cmd):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT_CTRL))
        s.sendall(json.dumps(cmd).encode())
        print(s.recv(1024).decode())


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


# send_cmd({"cmd": "start"})
send_cmd({"cmd": "stop"})
# send_cmd({
#  "cmd": "config_lo",
#  "config": [
#    {"name":"3W","LO_frequency":1000007,"resonance_frequency":1000021},
#    {"name":"3P","LO_frequency":1200007,"resonance_frequency":1100021},
#    {"name":"3Z","LO_frequency":1200007,"resonance_frequency":1100021}
#  ]
# })

# download_data()
