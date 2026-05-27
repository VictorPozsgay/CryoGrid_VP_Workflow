
<div style="text-align:center; margin:20px 0;">
  <img src="_static/banner.png" alt="Banner" style="width:100%; border-radius:10px;"/>
</div>


# 🎯 CryoGrid Optimization Automatization 🎯

Welcome to the documentation of **CryoGrid Optimization Automatization**.  
This project provides a fully automated MATLAB workflow to calibrate and optimize CryoGrid simulations using 
measured near-surface temperature for  modelling mountain permafrost temperature.

As the variability of snow cover pattern in mountain environment makes snow depth one of the most 
challenging parameter to calibrate, this workflow is particularly designed to retrieve snow characteristics,
especially snow fraction (i.e. the proportion of deposited snow when a snowfall occurs).

It automates the entire process of:
- Recovering sensor characteristics measured temperature in an Excel file gathering sensors metadata
- Updating CryoGrid input files based on sensor characteristics
- Detecting snow periods from daily temperature measurements
- Running Bayesian optimization (`bayesopt`) to infer physical parameters
- Generating statistics and plots for model performance evaluation


---

## 🛠️ Key Features

- **Automated Calibration:** No manual parameter tuning is required.  
- **Snow Detection Module:** Analyzes daily temperature variations to detect snow cover periods.  
- **Optimization method:** Global optimization via Bayesian inference.  
- **Modular MATLAB Workflow:** Organized in four stages for clarity and reusability.  
- **Scalable to Multiple Sensors:** Adaptability to different sensor configuration.
- **Parallelized code:** Parallelization to reduce optimization time. Workflow with lock mechanisms to prevent conflicts.  

---

## 📂 Project Structure

- `CryoGrid_Optimization_Automatization/`
  - `src/` → MATLAB scripts
  - `data/` → Sensor data files (CSV) and global excel file with all the sensors metadata
  - `forcing/` →  Sensor forcing data files (.mat) and automatization forcing scripts
  - `CryoGrid/` → All the CryoGrid scripts and file, `CryoGridCommunity_results/` is the optimization 
  output folder
  - `docs/` → Documentation (Sphinx)

---

## 📑 Documentation Overview

This documentation is organized into several sections:

```{toctree}
:maxdepth: 2
:caption: Contents

installation
usage
configuration
api
troubleshooting
```