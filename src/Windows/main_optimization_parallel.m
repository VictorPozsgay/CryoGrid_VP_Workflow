% ==============================================================
% AUTHOR:       Tristan FRIBAULT
% CONTACT:      fribaulttristan@gmail.com

%% ------------------- GENERAL CONFIGURATION -------------------
clc; clear; close all;
addpath(genpath('D:\Utilisateurs\lehmannb\Documents\0_Pro\16_PAPROG\2_Model\Cryogrid_Calibration_Optimisee\CryoGrid_Optimization_Automatization-main'))

% --- Input parameters (TO BE FILLED BY THE USER) ---

% --- Sensor identification ---

% Sensor ID
% ⚠️ The sensor identifier must be present in the Excel file containing
% all sensor data, and all required information must be filled in the columns

sensor_ID = 'MON1';                     % Sensor name to process

% --- File containing all sensor information ---

% Path to the Excel file listing all sensors and their information.
% Keep the exact column naming format
sensors_file = 'D:\Utilisateurs\lehmannb\Documents\0_Pro\16_PAPROG\2_Model\Cryogrid_Calibration_Optimisee\CryoGrid_Optimization_Automatization-main\data\PAPROG_Dataset_251007.xlsx';

% --- Folder containing reference sensor data ---

% Path to the folder containing all .csv or .xlsx files with reference data
% of the sensors listed in the Excel file. These files follow a strict
% standardized format
daily_mean_sensors_folder = 'D:\Utilisateurs\lehmannb\Documents\0_Pro\16_PAPROG\2_Model\Cryogrid_Calibration_Optimisee\CryoGrid_Optimization_Automatization-main\data\Daily_mean';

% --- Folder containing sensor forcing data ---

% Path to the folder containing forcing data
forcing_folder = 'D:\Utilisateurs\lehmannb\Documents\0_Pro\16_PAPROG\2_Model\Cryogrid_Calibration_Optimisee\CryoGrid_Optimization_Automatization-main\forcing\Forcing_Data';

% --- CryoGrid parameterization Excel file ---

% Path to the CryoGrid Excel file CG_single.xlsx
cryogrid_excel_file = 'D:\Utilisateurs\lehmannb\Documents\0_Pro\16_PAPROG\2_Model\Cryogrid_Calibration_Optimisee\CryoGrid_Optimization_Automatization-main\CryoGrid\CryoGridCommunity_results\CG_single\CG_single.xlsx';

% --- Path to the CryoGrid source folder ---

% Path to the CryoGrid source folder to add in order to run
% the CryoGrid model without Nanmin conflicts
cryogrid_source_path = 'D:\Utilisateurs\lehmannb\Documents\0_Pro\16_PAPROG\2_Model\Cryogrid_Calibration_Optimisee\CryoGrid_Optimization_Automatization-main\CryoGrid\CryoGridCommunity_source';

% --- Path to the CryoGrid results folder ---

cryogrid_results_path = 'D:\Utilisateurs\lehmannb\Documents\0_Pro\16_PAPROG\2_Model\Cryogrid_Calibration_Optimisee\CryoGrid_Optimization_Automatization-main\CryoGrid\CryoGridCommunity_results\';

% --- Seasonal weights to refine the model scoring ---

% Adjust seasonal weights to give more or less importance
% to each season in the scoring and optimization
season_weights = struct('winter', 2.0, 'spring', 1.5, 'summer', 2.0, 'autumn', 1.0);

% --- Optimization options ---
max_iterations = 6;                    % Max number of evaluations for bayesopt, more than 30 is effective
dt = 0.25;                             % Simulation time step, must match the CryoGrid Excel file

% ----------------- CONFIGURATION OF PARAMETERS TO OPTIMIZE -----------------

    
% Each field is a structure with:
%   - 'bounds_low_snow': if snow between 15 and 50 days/year
%   - 'bounds_high_snow': if snow >= 50 days/year
%   - 'bounds_no_snow': if snow < 15 days/year
%   - 'always_optimize': true if always optimized
%   - 'fixed_if_no_snow': fixed value if no snow is detected

params_config = struct();

% --------------- SNOW FRACTION ----------------
params_config.snow_fraction = struct( ...
    'low_snow_bounds', [0, 0.8], ...
    'high_snow_bounds', [0, 1], ...
    'no_snow_bounds', [], ...
    'always_optimize', false, ...
    'fixed_if_no_snow', 0 ...
);

% --------------- ALBEDO ----------------

params_config.albedo = struct( ...
    'bounds', [0.05, 0.55], ...
    'always_optimize', true ...
);

% --------------- ² ----------------
params_config.z0 = struct( ...
    'bounds', [0, 0.9], ...
    'always_optimize', true ...
);

%% ------------------- RUN OPTIMIZATION (DO NOT MODIFY) -------------------
run_program_parallel(sensor_ID, cryogrid_source_path, daily_mean_sensors_folder, ...
    sensors_file, cryogrid_excel_file, max_iterations, season_weights, ...
    forcing_folder, params_config, dt, cryogrid_results_path);
