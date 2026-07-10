import logging
import sys
from logging.handlers import RotatingFileHandler


def setup_logging(mode: str):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    if logger.hasHandlers():
        logger.handlers.clear()

    formatter = logging.Formatter(
        fmt="%(asctime)s | %(levelname)s | %(threadName)s | %(funcName)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    if mode == "service":
        handler = RotatingFileHandler(
            "/home/xilinx/logs/rfsoc_server.log",
            maxBytes=5 * 1024 * 1024,  # 5 MB
            backupCount=3,  # 3 files
        )
    else:
        handler = logging.StreamHandler(sys.stdout)

    handler.setFormatter(formatter)
    logger.addHandler(handler)

    return logger
