function [provider] = run_spatial(folder_path,massif_num)
%RUN_SPATIAL Run a spatial CryoGrid simulation for one SAFRAN massif.
%
%   [PROVIDER] = RUN_SPATIAL(FOLDER_PATH,MASSIF_NUM)
%   initializes the CryoGrid VP workflow, prepares the CryoGrid provider
%   from the spatial template, runs the model, and organizes the generated
%   MAT files into a massif-specific output folder.
%
%   Input:
%
%       FOLDER_PATH - Path relative to the CryoGridCommunity_results
%                     directory where the simulation output is stored.
%                     Trailing slashes are optional.
%
%                     Example:
%                         "templates\test_spatial"
%
%       MASSIF_NUM  - Numerical SAFRAN massif number.
%
%                     Example:
%                         5
%
%   Output:
%
%       PROVIDER    - PROVIDER object used to initialize and configure
%                     the CryoGrid simulation. It contains the resolved
%                     paths, constants, parameters, and class configuration
%                     used for the run.
%
%   Output organization:
%
%       The simulation is initially executed in:
%
%           CryoGridCommunity_results/FOLDER_PATH/
%
%       After the simulation, generated MAT files are moved to:
%
%           CryoGridCommunity_results/FOLDER_PATH/massif_XX/
%
%       where XX is the two-digit SAFRAN massif number.
%
%       For example, with:
%
%           run_spatial("templates\test_spatial",5)
%
%       the output files are moved to:
%
%           CryoGridCommunity_results/templates/test_spatial/massif_05/
%
%
%   Example:
%
%       [run_info,provider,tile] = ...
%           run_spatial("templates\test_spatial",5);
%
%   See also INITIALIZE_CRYOGRID_VP, VP_RETURN_PATHS, PROVIDER,
%            RUN_MODEL, REPLACE_PATHS_STRINGS.
%
% -------------------------------------------------------------------------
% CryoGrid VP workflow
% -------------------------------------------------------------------------

PATHS = initialize_CryoGrid_VP();

CG_FORCING_PATH = PATHS.FORCING.root;
CG_RESULTS_PATH = PATHS.RESULTS.root;

% ---------------------------------------------------------------------
% Prepare output paths
% ---------------------------------------------------------------------

% Remove trailing slashes from the supplied folder path.
folder_path = regexprep(folder_path,'[\\/]+$','');

TARGET_FOLDER = char(fullfile(CG_RESULTS_PATH,folder_path));
[result_path,run_name] = fileparts(TARGET_FOLDER);
result_path = char([result_path filesep]);
run_name    = char(run_name);

% Zero-padded massif identifier used in file and folder names.
MASSIF_NUM = char(sprintf('%02d',massif_num));
massif_folder = fullfile(TARGET_FOLDER,sprintf('massif_%s',MASSIF_NUM));

% ---------------------------------------------------------------------
% CryoGrid initialization settings
% ---------------------------------------------------------------------

constant_file = 'CONSTANTS_excel';
init_format   = 'EXCEL3D';

% ---------------------------------------------------------------------
% Create and load PROVIDER
% ---------------------------------------------------------------------

provider = PROVIDER;

provider = assign_paths( ...
    provider, ...
    init_format, ...
    run_name, ...
    result_path, ...
    constant_file);

provider = read_const(provider);

provider = read_parameters(provider);

% Replace placeholders in the CryoGrid parameter file.
%
% REPLACE_PATHS_STRINGS performs the substitutions as character data.
% The massif_num parameter is subsequently interpreted numerically by
% the corresponding CryoGrid class.

provider = replace_PATHS_strings( ...
    provider, ...
    {'TARGET_FOLDER';'CG_FORCING_PATH';'MASSIF_NUM';'massif_num'}, ...
    {TARGET_FOLDER;CG_FORCING_PATH;MASSIF_NUM;massif_num});

% ---------------------------------------------------------------------
% Run CryoGrid
% ---------------------------------------------------------------------

[run_info,provider] = run_model(provider);
[run_info,tile] = run_model(run_info);

% ---------------------------------------------------------------------
% Organize output files
% ---------------------------------------------------------------------

if ~isfolder(massif_folder)
    mkdir(massif_folder);
end

movefile(fullfile(TARGET_FOLDER,'*.mat'),massif_folder);

end
