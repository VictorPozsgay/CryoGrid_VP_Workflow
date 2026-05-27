# Configuration

This page explains how to configure the **CryoGrid Optimization Automatization** project before running it.

## MATLAB Script Settings

- `main_optimization_parallel.m`:
  - `sensor_ID` : ID of the sensor to study
  - `sensor_file` : path to the (`PAPROG_Data.xlsx`) file with all the sensor metadata
  - `daily_mean_sensors_folder` : path to daily_mean CSV folder
  - `forcing_folder` : path to .mat forcing files in the (`forcing/`) folder
  - `cryogrid_excel_file` : path to (`CG_single.xlsx`), the CryoGrid parametrisation file
  - `cryogrid_source_path` : path to (`CryoGridCommunity_source/`), the CryoGrid source folder
  - `cryogrid_results_path` : path to (`CryoGridCommunity_results/`), the CryoGrid results folder
  and the optimization output folder also
  - `season_weigths` : value of weights for each season in scoring
  - `n_iterations` : number of Bayesian optimization iterations
  - `step_time` : step for CryoGrid (recommended 0.25)


## CryoGrid Excel Parameters

- `CG_single.xlsx`:
  - `albedo` : surface albedo to optimize. Physical bounds in mountain are most of the time between 0.05
  and 0.55
  - `z0` : roughness length in meter. 
  It is related to the roughness characteristics of the terrain.
  - `snow_fraction` : snow fraction, it depends on the field characteristics. 
  It's the snow quantity that stay on the ground, and this phenomenon has thermal properties. This 
  parameter is optimized only if the `detect_snow_presence` function detects more than 15 average 
  snow day per year.
  
Then, there are a lot of parameters you can change in this file. The sensor metadata like `altitude`,
`slope_angle`, `sky_view_factor`, ... are automatically modified in this file.

- `CONSTANTS_excel.xlsx`:
  - default values and boundaries for parameters
  

## Optimization Options

- `season_weights` : In function of your objective, you can give more importance to a season. 
This allows the optimization program to focus more on the performance during this season.
- Bayesian parameter bounds for `albedo`, `z0`, `snow_fraction`. 
You should adapt it to your configuration and your sensor location properties.
- Parallel workers configuration. In this code, all the usable worker are used for the optimization.


### Example MATLAB Configuration

```matlab
sensor_ID = '2ALP_S1';
sensor_file = 'data/PAPROG_Data_set.xlsx';
daily_mean_sensors_folder = 'Users/Documents/CryoGrid_Optimisation_Automatization/data/Daily_mean';
forcing_folder = 'Users/Documents/CryoGrid_Optimisation_Automatization/Forcing/Forcing_Data';
cryogrid_excel_file = 'CryoGrid/CryoGridCommunity_results/CG_single.xlsx';
cryogrid_source_path = 'CryoGrid/CryoGridCommunity_source';
cryogrid_results_path = 'CryoGrid/CryoGridCommunity_results/';
season_weights = struct('winter', 2.0, 'spring', 1.5, 'summer', 2.0, 'autumn', 1.0);
n_iterations = 80;
step_time = 0.25;

params_config = struct();


%----- Snow Fraction -----
params_config.snow_fraction = struct( ...
    'low_snow_bounds', [0, 0.4], ...
    'high_snow_bounds', [0, 1.2], ...
    'no_snow_bounds', [], ...
    'always_optimize', false, ...
    'fixed_if_no_snow', 0 ...
);



%----- Albedo -----

params_config.albedo = struct( ...
    'bounds', [0.05, 0.55], ...
    'always_optimize', true ...
);


%----- z0 -----

params_config.z0 = struct( ...
    'bounds', [0, 0.7], ...
    'always_optimize', true ...
);

```






