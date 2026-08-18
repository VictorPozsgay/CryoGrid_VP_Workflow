function prepare_VP()
%PREPARE_VP Prepare all datasets required by the CryoGrid VP workflow.
%
%   PREPARE_VP() initializes the CryoGrid VP workflow, loads the local
%   user configuration, and executes the three main preparation modules:
%
%       1. VP_Meteo  - meteorological forcing
%       2. VP_DEM    - DEM and terrain products
%       3. VP_Geol   - geological products
%
%   Repository paths are determined automatically by
%   INITIALIZE_CRYOGRID_VP(). Machine-specific settings and processing
%   options are read from:
%
%       VP_config.m
%
%   The complete workflow can therefore be started with simply:
%
%       prepare_VP
%
%   Individual preparation modules remain independently usable:
%
%       prepare_forcing(...)
%       prepare_dem(...)
%       prepare_geology(...)
%
%   SEE ALSO
%       VP_CONFIG
%       INITIALIZE_CRYOGRID_VP
%       PREPARE_FORCING
%       PREPARE_DEM
%       PREPARE_GEOLOGY

% =========================================================================
% Initialize workflow
% =========================================================================

PATHS = initialize_CryoGrid_VP();

CONFIG = VP_config();


% =========================================================================
% Validate configuration
% =========================================================================

if CONFIG.meteo.DownloadERA5 && ...
        strlength(string(CONFIG.meteo.PythonExecutable)) == 0

    error(['ERA5 acquisition is enabled, but no Python executable ' ...
           'has been configured in VP_config.m.']);
end

if CONFIG.dem.Resolution ~= CONFIG.geology.Resolution

    error(['DEM and geology resolutions must be identical. ' ...
           'CONFIG.dem.Resolution = %g m, ' ...
           'CONFIG.geology.Resolution = %g m.'], ...
           CONFIG.dem.Resolution, ...
           CONFIG.geology.Resolution);
end


% =========================================================================
% VP_Meteo
% =========================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf(' VP_Meteo\n');
fprintf('============================================================\n');

prepare_forcing( ...
    PATHS.FORCING.meteo, ...
    'DownloadS2M',CONFIG.meteo.DownloadS2M, ...
    'Email',CONFIG.meteo.Email, ...
    'DownloadERA5',CONFIG.meteo.DownloadERA5, ...
    'PythonExecutable',CONFIG.meteo.PythonExecutable);


% =========================================================================
% VP_DEM
% =========================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf(' VP_DEM\n');
fprintf('============================================================\n');

prepare_dem( ...
    PATHS.FORCING.dem, ...
    PATHS.safran_shp, ...
    'Resolution',CONFIG.dem.Resolution, ...
    'Overwrite',CONFIG.dem.Overwrite, ...
    'Diagnostics',CONFIG.dem.Diagnostics, ...
    'SVFNumBins',CONFIG.dem.SVFNumBins, ...
    'SVFMaxDistance',CONFIG.dem.SVFMaxDistance);


% =========================================================================
% VP_Geol
% =========================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf(' VP_Geol\n');
fprintf('============================================================\n');

prepare_geology( ...
    PATHS.FORCING.geology, ...
    PATHS.FORCING.dem, ...
    'Resolution',CONFIG.geology.Resolution);


% =========================================================================
% Complete
% =========================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf(' CryoGrid VP preparation complete\n');
fprintf('============================================================\n\n');

end