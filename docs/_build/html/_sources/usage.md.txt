# Usage

This page explains how to use the **CryoGrid Optimization Automatization** project once it has been installed 
and set up.

---

## Add MATLAB Path

Before running any scripts, make sure the `src/`, `CryoGrid/`, `data/` and `forcing/` folders and subfolders 
are added to the MATLAB path:

```matlab
addpath('path_to_project/src')
savepath
```

This ensures that all functions, files and scripts are accessible.


---

## Overview of Scripts

The main script included in the project is:

- `main_optimization_parallel.m`
    - Runs the full optimization workflow in parallel for one sensor at the time. This is the main script to configure and 
run the optimization workflow. You typically only need to modify this script to set your sensor and paths.
    - This script calls, with run_program_parallel script, other functions for input file generation, snow detection, 
    - Bayesian optimization, and post-processing.
    - Runs the workflow for a single sensor. 

- `functions/ folder`
    - Contains MATLAB functions such as detect_snow_presence.m, run_CG_from_excel.m, score_model_seasonal.m, etc.

- `CryoGrid/ folder`
    - Contains all the CryoGrid model. It is the model which simulate the permafrost temperature in the sensor area.
In this folder, you have all the necessary files and scripts to run a CryoGrid simulation.


---

## Input Data

### Sensor CSV Files :
- Located in data/Daily_mean/
- Each CSV file should contain daily temperature measurements for a sensor.

Example:

```
csv
DATE,TEMP
2023-01-01,-2.1
2023-01-02,-1.8
...
```

- This filename should contain the sensor ID, followed by 'daily_mean.csv'. 

Exemple :
`2ALP_S1_daily_mean.csv`


### Sensor Excel File :
- Located in `data/PAPROG_Data_set.xlsx`
- Contains sensor metadata (IDs, altitudes, sensor_depth, slope_angle, etc...)
- Important : This file should contain all the requires columns mentionned in the `get_sensor_info.m` in
the function folder

```{figure} _static/global_excel_file.png
---
width: 600px
align: center
name: Golbal-excel-file
---
Visualization of the excel sensor metadata file
```


### Sensor forcing file :
- .mat file located in `forcing/Forcing_Data/`
- Used by CryoGrid as input forcing for simulations
- The filename should contain the sensor ID, and strat with 'FORCING' (any other information in the filename are not necessary).

Exemple : 
`FORCING_data_elev_3540_slope_0_aspect_-1_massif_15_dates_01Aug1958_01Aug2024_2ALP_S1.mat`


 > **Warning:** Ensure all sensor CSV and .mat files are in the correct folders with matching sensor IDs.


---

## Running the Optimization

Open the 'main_optimization_parallel.m' MATLAB script. 

### Configure Sensor and Paths
Before running the script, set the following variables in MATLAB:
- the sensor ID you want to study
- path to the PAPROG_Dataset
- path to the daily_mean temperature sensor folder
- path to the forcing folder
- path to the CryoGrid Excel file, called CG_single.xlsx in the .../CryoGridCommunity_results/CG_single/ folder
- path to the CryoGridCommunity_results/ and CryoGridCommunity_source/folders


### Set Optimization Parameters
Now you can set the optimisation informations :
- season_weights
- number of iterations
- step time, > **Note:** Step time should not exceed 1. For CryoGrid, the ideal value is 0.25.
- bounds of the optimised parameters : z0, albedo and snow fraction


### Run the Script
Steps performed:
- Update CryoGrid input files (CG_single.xlsx) based on sensor characteristics
- Detect snow periods using daily temperature data
- Run CryoGrid simulations in a Bayesian optimization loop
- Save results in CryoGridCommunity_results/

```{figure} _static/running_script.png
---
width: 600px
align: center
name: matlab-window
---
Image of MATLAB running `main_optimization_parallel.m`
```


---

## Parallelisation

To reduce the simulation runtime, this code is parallelized. The Bayesian loop :
- Uses parallel workers to run CryoGrid simulations with different tested parameters in the same time
- Automatically creates temporary folders with lock files to avoid conflicts and doing post-processing
- Saves results in separate folders per sensor


---

## Parameters and Configuration

Default parameters are stored in CryoGridCommunity_results/CG_single/CONSTANTS_excel.xlsx .

Parameters you want to adjust :
- albedo [dimensionless]
- z0 (roughness length) [m]
- snow_fraction [dimensionless]

Additional configuration options can be added in the future, like a new optimized variable.


---

## Output Results

Results are stored in CryoGrid/CryoGridCommunity_results/. 

### 📈 Figures 📈

In the output files, you have the figures folder with :
- Snow detection graph

```{figure} _static/Figures_exemple/snow_detection_example.png
---
width: 600px
name: snow-detection
align: center
---
Snow detection graph for sensor 2ALP_S1
```

- Bayesian score convergence graph

```{figure} _static/Figures_exemple/bayesian_score_convergence_example.png
---
width: 600px
name: bayesian-score
align: center
---
Bayesion best score evolution graph for sensor 2ALP_S1
```

- Graph of score in function of iteration

```{figure} _static/Figures_exemple/score_iteration_example.png
---
width: 600px
name: score-per-iteration
align: center
---
Score in function of iteration graph for sensor 2ALP_S1
```

- Histogram and individual influence of tested values for each optimized parameters

```{figure} _static/Figures_exemple/histogram_example.png
---
width: 600px
name: histogram-exemple
align: center
---
Histogram and individual optimized parameters influence results for sensor 2ALP_S1
```

- 3D surface/interpolation graph of parameters

```{figure} _static/Figures_exemple/3D_surface_example.png
---
width: 600px
name: 3D-surface-exemple
align: center
---
3D surface/interpolation parameters graph for sensor 2ALP_S1
```

- Temperature graph comparison between the first and the best simulation

```{figure} _static/Figures_exemple/comparison_best_vs_first_example.png
---
width: 600px
name: Comparison-best-and-first-simulation
align: center
---
Best an first simulation for sensor 2ALP_S1
```

- Best simulated temperature graph correlated with the snowfall accumulation curve over a hydrological year

```{figure} _static/Figures_exemple/best_and_snowfall_example.png
---
width: 600px
name: Best-simultion-compare-to-snowfall
align: center
---
Best simulation with cumulative snowfall for sensor 2ALP_S1
```

- Seasonal scatter plot

```{figure} _static/Figures_exemple/seasonal_plot_example.png
---
width: 600px
name: seasonal-plot
align: center
---
Seasonal scatter plot for sensor 2ALP_S1
```

- Uncertainty envelope

```{figure} _static/Figures_exemple/uncertainty_envelope_example.png
---
width: 600px
name: uncertainty-envelope
align: center
---
Uncertainty envelope graph for sensor 2ALP_S1
```


### Summarize Excel files
You have the summary excel files :
- `results_*sensor_ID*.xlsx` with the bests simulations, associated parameters values and statistics indicators
- `bayesopt_results_*sensor_ID*.xlsx` which summarise the Bayesian loop with all iterations and their parameter 
values 


### Matlab file result
And the total Matlab resume file called `bayesopt_results_*sensor_ID*.mat` where you have the details of each iteration,
for exemple the simulated temperature vector.


---






- 