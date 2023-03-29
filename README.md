# BAWSHA
This project is a colection of classes, modules and packages used to handle and analyze data from BAW. It is built on top of the standard python packages for scientific computing. 

### Installation
1. Open up your terminal and clone the repository locally:  
   Clone with HTTPS by using by the web URL
   ```
   $ git clone https://github.com/Lab5015/BAWSHA.git
   ```

2.  Install virtualenv using python >= 3.X (X >=6). 
   ```
   $ sudo apt-get install python3.X-dev python3.X-tk python3.X-distutils libxext-dev build-essential 
   $ sudo pip install virtualenv
   ```
   with X the python version of your choice.
   
   Create the Bawsha virtual environment based on python3.X (X>=6) 
   ```
   $ virtualenv -p `which python3.X` ~/bawenv
   ```   
   Run the following command to activate the watson virtual environment 
   ```
   $ source bawenv/bin/activate
   ```  
   (optional) Check the version of python being used in the virtual environment  
   ```
   (bawenv) $ python -V
   ```
   Python 3.X.x
   if the returned value is the chosen verson, the version is ok
   
3. Install (or **update**) the packages and the dependencies of BAWSHA inside virtualenv
   Inside the BAWSHA folder, just type
   ```  
   (bawenv) $ pip install .
   ```  

 
### Project top-level directory layout
    
    bawsha
    │  
    ├── src                            # Project source code
    ├── scripts                        # Directory for scripts and executables 
    ├── test                           # Directory used to collect test code   
    ├── notebooks                      # Directory for guides and test  
    ├── requirements.txt               # Requirements file specifing the lists of packages to install
    ├── setup.py                       # script for install and update the package
    ├── .gitignore                     # Specifies intentionally untracked files to ignore
    └── README.md                      # README file
    
 ASCII art tree structure taken from [here](https://codepen.io/patrickhlauke/pen/azbYWZ)
  
### Documentation
* Python classes for newbies: [from dev.to](https://dev.to/oluchiorji_95/a-gentle-introduction-to-python-classes-for-newbies-p46);
 
 ### About README
 The README files are text files that introduces and explains a project. It contains information that is commonly required to understand what the project is about.  
 At this [link](https://help.github.com/en/github/writing-on-github/basic-writing-and-formatting-syntax) a basic guide on the writing and formatting syntax
