import csv
import logging

FS = 122.88e6
FIR_DEC = 468750

def load_lo_config(server, fw_version):
    server.frequencies.clear()
    server.metadata.clear()
    with open("lo_config.csv", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            lo = int(row["LO_frequency"])
            server.frequencies.append(lo)
            server.metadata[row["name"]] = {
                "LO_frequency": lo,
                "resonance_frequency": int(row["resonance_frequency"]),
                "t0": 0,
                "counter": 0,
                "fs": FS/FIR_DEC,
                "fir_dec": FIR_DEC,
                "fw_version": fw_version,
            }


def write_lo_config(config):
    with open("lo_config.csv", "w", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=["name", "LO_frequency", "resonance_frequency"]
        )
        writer.writeheader()
        for row in config:
            writer.writerow(row)
            logging.info(
                f"[LO] name={row['name']} LO={row['LO_frequency']} Hz res={row['resonance_frequency']} Hz"
            )
