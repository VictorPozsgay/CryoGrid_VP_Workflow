# Installation

This page explains how to install and set up the **CryoGrid Optimization Automatization** project on your 
computer.

---

## Prerequisites

Before starting, make sure you have the following installed:

- **MATLAB R2022b** or later  
- **MATLAB Toolboxes**:
  - Optimization Toolbox
  - Statistics and Machine Learning Toolbox
- **Python 3.10+** (optional, only if you want to build the documentation locally)  
- **pip packages** for documentation:
```bash
pip install sphinx myst-parser sphinx-rtd-theme
```
---

## Code launch

Clone the GitHub repository to your local machine:

git clone https://github.com/username/CryoGrid_Optimization_Automatization.git
cd CryoGrid_Optimization_Automatization

After cloning, the project folder should look like this:

```
CryoGrid_Optimization_Automatization/
├── src/                                    # MATLAB scripts 
│   ├── functions/                              # MatLab Optimization functions
│   ├── main_optimization_parallel/             # Main Matlab script, unique code to open                
├── CryoGrid/                               # CryoGrid MATLAB 
│   ├── CryoGridCommunity_results/              # Files and Results of CryoGrid and Optimization outputs
│   ├── CryoGridCommunity_source/               # CryGrid code source files
│   └── ...
├── data/                                   # Sensors data folder
│   ├── Daily_mean/                             # Exemple of sensor CSV files format
│   ├── Sensors_metedata.xlsx                   # Exemple of Excel sensor format 
├── forcing/                                # Forcing folder
│   ├── Forcing_Data/                           # Exemple of sensor .mat forcing files
│   ├── Forcing_code/                           # Code to create Matlab forcing file
└── docs/                                   # Documentation (Sphinx / Read the Docs)
```


## Data Preparation

- The `data/Daily_mean/` folder contains example sensor CSV files. Make sure to follow the formatting of the template file.
- For your own simulations, place your sensor CSV files in `data/Daily_mean/`. 
- `.mat` forcing files should be placed in `forcing/Forcing_Data/`. Make sure to follow the formatting of the template file.
- Ensure that file names match the sensor ID used in your MATLAB scripts and in the `PAPROG_Data_set.xlsx` file.


## MATLAB Path

Before running any scripts, add the `src/`, `CryoGrid/`, `data/` and `forcing/` folders and subfolders to 
the MATLAB path in MATLAB:

```
Exemple : matlab
addpath(genpath('path_to_project/src'))
addpath(genpath('path_to_project/CryoGrid'))
addpath(genpath('path_to_project/data'))
addpath(genpath('path_to_project/forcing'))
```







