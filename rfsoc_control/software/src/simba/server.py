import argparse
import logging

from logging_config import setup_logging
from rf_soc_server import RFSoCServer


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mode",
        choices=["service", "interactive"],
        default="interactive",
        help="Execution mode. Service mode disables console formatting.",
    )
    args = parser.parse_args()

    setup_logging(args.mode)

    logging.info("Starting RFSoC server")

    try:
        server = RFSoCServer()
        server.start()
    except KeyboardInterrupt:
        logging.info("Shutting down cleanly...")


if __name__ == "__main__":
    main()
