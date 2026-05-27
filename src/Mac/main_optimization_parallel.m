% ==============================================================
% AUTHOR:         Tristan FRIBAULT
% CONTACT:        fribaulttristan@gmail.com


%% ------------------- GENERAL CONFIGURATION -------------------

clc; clear; close all;

% --- Input parameters (TO BE FILLED BY THE USER) ---

% --- Sensor identification ---

% Sensor ID
% ⚠️ The sensor ID must be present in the Excel file with all sensor data,
% and all related information must be filled in the corresponding columns.
sensor_ID = 'MON1';                     % Name of the sensor to process

% --- File containing all sensor information ---

% Path to the Excel file listing all sensors and their information.
% Must keep the exact column naming format.
sensors_file = '/Users/maximefadel/Documents/Stage_Edytem/CryoGrid_Optimization_Automatization/data/PAPROG_Dataset_final_exemple.xlsx';

% --- Folder with reference sensor data ---

% Path to the folder containing all .csv or .xlsx files with reference
% sensor data from the Excel table. These files have been formatted in a
% standardized way.
daily_mean_sensors_folder = "/Users/maximefadel/Documents/Stage_Edytem/CryoGrid_Optimization_Automatization/data/Daily_mean";

% --- Folder with sensor forcing data ---

% Path to the folder containing forcing data.
forcing_folder = '/Users/maximefadel/Documents/Stage_Edytem/CryoGrid_Optimization_Automatization/forcing/Forcing_Data';

% --- CryoGrid parameterization Excel file ---

% Path to the Excel file CG_single.xlsx 
cryogrid_excel_file = '/Users/maximefadel/Documents/Stage_Edytem/CryoGrid_Optimization_Automatization/CryoGrid/CryoGridCommunity_results/CG_single/CG_single.xlsx';

% --- Path to the CryoGrid source folder ---

% Path to the CryoGrid source folder to be added in order to run the model
% without Nanmin conflicts.
cryogrid_source_path = '/Users/maximefadel/Documents/Stage_Edytem/CryoGrid_Optimization_Automatization/CryoGrid/CryoGridCommunity_source';

% --- Path to the CryoGrid results folder ---

cryogrid_results_path = '/Users/maximefadel/Documents/Stage_Edytem/CryoGrid_Optimization_Automatization/CryoGrid/CryoGridCommunity_results/';

% --- Seasonal weights for refining model scoring ---

% Adjustment of seasonal weights allows giving more or less importance to
% each season in the scoring and therefore in the optimization.
season_weights = struct('winter', 2.0, 'spring', 1.5, 'summer', 2.0, 'autumn', 1.0);

% --- Optimization options ---
num_iterations = 5;               % Max number of evaluations for bayesopt, >30 for efficiency
dt = 0.25;                         % Simulation timestep, must match CryoGrid Excel file


% ----------------- CONFIGURATION OF PARAMETERS TO OPTIMIZE -----------------

% Each field is a structure with:
%   - 'low_snow_bounds'  : if snow between 15 and 50 days/year
%   - 'high_snow_bounds' : if snow >= 50 days/year
%   - 'no_snow_bounds'   : if snow < 15 days/year
%   - 'always_optimize'  : true if always optimized
%   - 'fixed_if_no_snow' : fixed value if snow is absent

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

% --- z0: truncated exponential distribution ---
% lambda_z0 = 5;  % paramètre de la loi exponentielle
% pd_z0 = makedist('Exponential','mu',1/lambda_z0);  % loi exponentielle
% pd_z0 = truncate(pd_z0, 0, 0.9);                  % tronquée à [0,0.9]
% 
% params_config.z0 = struct( ...
%     'bounds', [0, 0.9], ...       % bornes physiques
%     'always_optimize', true, ...
%     'distribution', pd_z0 ...     % distribution pour l'ICDF
% );


%% ------------------- START OPTIMIZATION (DO NOT MODIFY) -------------------

run_program_parallel(sensor_ID, cryogrid_source_path, daily_mean_sensors_folder, ...
    sensors_file, cryogrid_excel_file, num_iterations, season_weights, ...
    forcing_folder, params_config, dt, cryogrid_results_path);
