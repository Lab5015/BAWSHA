#!python

import IPython
from instruments import agilent4395A
import numpy as np

def main():
    VNA = agilent4395A.Agilent4395A()
    print("VNA object created!")
    IPython.embed()
    return
    

if __name__ == "__main__":
    main()
