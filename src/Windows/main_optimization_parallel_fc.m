function main_optimization_parallel_fc(sensor_ID)
% ==============================================================
% AUTHOR:       Tristan FRIBAULT (modifié pour lancement automatisé)
% CONTACT:      fribaulttristan@gmail.com
% USAGE:        main_optimization_parallel_fc('PEL_N')
% sensor_ID = 'MEN15';
%% ------------------- GENERAL CONFIGURATION -------------------
clc; clearvars -except sensor_ID; close all;

% --- Ajout des chemins nécessaires ---
% base_path = 'E:\CG_Merge\CryoGrid_Optimization_Automatization_Workflow-main';
base_path = '..\..';
base_path = char(java.io.File(fullfile(base_path)).getCanonicalPath());
addpath(genpath(base_path));

%% ------------------- PARAMÈTRES FIXES -------------------

% --- Fichier Excel contenant les infos capteurs ---
sensors_file = fullfile(base_path, 'data', 'PAPROG_Dataset_final_exemple.xlsx');
 
% --- Dossier contenant les données journalières ---
daily_mean_sensors_folder = fullfile(base_path, 'data', 'Daily_mean');

% --- Dossier contenant les forçages ---
forcing_folder = fullfile(base_path, 'forcing', 'Forcing_Data');

% --- Fichier Excel de paramétrage CryoGrid ---
cryogrid_excel_file = fullfile(base_path, 'CryoGrid', 'CryoGridCommunity_results', 'CG_single', 'CG_single.xlsx');

% --- Dossier source CryoGrid  %%nanmin conflicts ---
cryogrid_source_path = ('E:\CG_Merge\CryoGrid_Optimization_Automatization_Workflow-main\CryoGrid\CryoGridCommunity_source');

% --- Dossier résultats CryoGrid ---
cryogrid_results_path = fullfile(base_path, 'CryoGrid', 'CryoGridCommunity_results');

% --- Pondérations saisonnières ---
season_weights = struct('winter', 1.0, 'spring', 2.0, 'summer', 1.0, 'autumn', 1.0);

% --- Options d’optimisation ---
max_iterations = 24;
dt = 0.25;  % doit correspondre au fichier Excel de CryoGrid

%% ------------------- PARAMÈTRES À OPTIMISER -------------------
params_config = struct();

% --------------- SNOW FRACTION ----------------
params_config.snow_fraction = struct( ...
    'low_snow_bounds', [2.7, 2.9], ...      %  
    'high_snow_bounds', [2.7, 2.9], ...     %
    'no_snow_bounds', [], ...               %
    'always_optimize', false, ...
    'fixed_if_no_snow', 0 ...
);

% --------------- ALBEDO ----------------
params_config.albedo = struct( ...
    'bounds', [0.245, 0.255], ...
    'always_optimize', true ...
);

% --------------- z0 ----------------
params_config.z0 = struct( ...
    'bounds', [0.1, 0.5], ...
    'always_optimize', true ...
);

%% ------------------- EXÉCUTION -------------------
fprintf('\n=== Lancement de l’optimisation pour le capteur : %s ===\n', sensor_ID);
run_program_parallel(sensor_ID, cryogrid_source_path, daily_mean_sensors_folder, ...
    sensors_file, cryogrid_excel_file, max_iterations, season_weights, ...
    forcing_folder, params_config, dt, cryogrid_results_path);
fprintf('\n=== Optimisation terminée pour %s ===\n', sensor_ID);

end

