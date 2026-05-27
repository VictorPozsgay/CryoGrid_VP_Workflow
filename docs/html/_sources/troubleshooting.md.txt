# Troubleshooting & Common Errors

This page lists typical errors you may encounter when running the **CryoGrid Optimization 
Automatization** workflow, along with possible solutions.

---

## ⚠️ MATLAB Errors

### `Undefined function or variable`
- **Cause**: A script or function is not in the MATLAB path.  
- **Solution**: Make sure that the `src/` and `CryoGrid/` folders are added to the MATLAB path:
```
    matlab
    addpath(genpath('src/'))
    addpath(genpath('CryoGrid/'))
```

Note : Add path with folder and subfolders

### Index exceeds matrix dimensions

Cause: Sensor data file (CSV) is not correctly formatted.

Solution: Check that the CSV has columns DATE and TEMP with no missing values.

Another thing to see if missing values, in the `results_*sensor_ID*.xlsx` file, you may have empty values
for statistics indicators.

## 📂 File & Path Issues

### File not found: measurement file

If you have this error message : 
```
matlab
❌ No .csv or .xlsx measurement file found for sensor "sensor_ID".
```
Cause: Wrong path to the `data/` folder in the configuration section or not contain columns `DATA` and 
`TEMP`. It could be a problem with the sensor_ID. It can be not the same between your configuration 
section, Excel metadata file or in your measurement file name.

Solution: Verify the file is located in data/ and update sensor_file accordingly.
Verify that your measurement file is called exactly : `*sensor_ID*_daily_mean.csv`.
Check the exemple file.

### Forcing .mat files not recognized

If you have this error message : 
```
matlab
❌ No FORCING file found for  sensor "sensor_ID".
```

Cause: Wrong path to the `Forcing_Data/` folder in the configuration section or not containn rigth 
variables. It could be a problem with the sensor_ID. It can be not the same between your configuration 
section, Excel metadata file or in your forcing file name.

Solution: Ensure they contain temperature and precipitation variables as expected.
Verify that your forcing file starts exactly by `FORCING_*` and finishes by `*_sensor_ID`.
Check the exemple file.


## CryoGrid issues

Cause : Incorect path to CryoGrid folders and file in the configuration section. 
Incorect CryoGrid configuration.
No autorization to modify the Excel files.

Solution : Check the path.
Check autorizations.
Check your CryoGrid configuration and CryoGrid documentation.


## ⚡ Optimization Issues

### Optimization stops after few iterations
Cause: Parameter bounds are too restrictive or lead to invalid CryoGrid runs.

Solution: Check and expand the Bayesian parameter bounds in configuration.md.

### Parallel workers crash
Cause: Too many workers allocated for available system memory.

Solution: Reduce the number of workers in MATLAB Parallel Preferences.

## Issues in the objective function 

You will not have an error message because it is in the parallelisation loop.

To detect a problem, you have to go to the `CryoGridCommunity_results/CG_single/` folder. 
- First step, check if there is a .mat result file in your workers folders. If there is not a .mat file 
after a long time after the beginning of the simulation it's because the CryoGrid script doesn't work. 
--> Test to run CryoGrid in isolation

- Second step, check if the `temp_results` folder is created with the results files. If it is not the case
you have a problem with your path to create this folder.



## ✅ Best Practices

Always start with a fresh MATLAB session before launching main_optimization_parallel.m.

Keep your `data/`, `forcing/`, `/src` and `CryoGrid/` folders well organized.

If you add a new sensor, verify its metadata in `PAPROG_Data.xlsx`

