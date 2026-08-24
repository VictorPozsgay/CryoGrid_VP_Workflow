function CONFIG = VP_config()
%VP_CONFIG User configuration for the CryoGrid VP workflow.
%
%   Copy this file to:
%
%       CryoGridCommunity_run/VP_config.m
%
%   and edit the values below for the local installation.
%
%   VP_config.m is ignored by Git because it may contain
%   machine-specific information such as the Python executable path
%   and personal information such as the S2M acquisition email address.
%
%   Repository paths are NOT configured here. They are determined
%   automatically by initialize_CryoGrid_VP().
%
%   The configuration controls the three main VP preparation workflows:
%
%       VP_Meteo  -> prepare_forcing()
%       VP_DEM    -> prepare_dem()
%       VP_Geol   -> prepare_geology()
%
%   See also PREPARE_VP, INITIALIZE_CRYOGRID_VP.

% =========================================================================
% VP_Meteo
% =========================================================================

% -------------------------------------------------------------------------
% SAFRAN / S2M acquisition
% -------------------------------------------------------------------------

% Download SAFRAN / S2M forcing automatically.
%
% false = assume that the required S2M data already exist.
% true  = run the S2M acquisition workflow.

CONFIG.meteo.DownloadS2M = false;

% Email address used for the S2M acquisition.
%
% Only used when DownloadS2M = true.
%
% Use 'none' when S2M acquisition is disabled.

CONFIG.meteo.Email = 'none';


% -------------------------------------------------------------------------
% ERA5 TOA acquisition
% -------------------------------------------------------------------------

% Download ERA5 top-of-atmosphere radiation automatically.
%
% false = assume that the required ERA5 NetCDF files already exist.
% true  = run the ERA5 CDS API acquisition workflow.

CONFIG.meteo.DownloadERA5 = false;

% Python executable used for ERA5 acquisition.
%
% Required only when DownloadERA5 = true.
%
% Example:
%
% CONFIG.meteo.python_executable = ...
%     "C:\...\miniconda3\envs\...\python.exe";

CONFIG.meteo.PythonExecutable = "";


% =========================================================================
% VP_DEM
% =========================================================================

% -------------------------------------------------------------------------
% DEM resolution
% -------------------------------------------------------------------------

% Output DEM resolution in metres.
%
% This resolution is also used by the geology preparation because the
% geological products must be rasterized on the same DEM grid.

CONFIG.dem.Resolution = 10;


% -------------------------------------------------------------------------
% Existing-product handling
% -------------------------------------------------------------------------

% Recompute existing DEM products where supported.
%
% false = reuse existing products and cached data.
% true  = overwrite existing products.

CONFIG.dem.Overwrite = false;


% -------------------------------------------------------------------------
% Diagnostics
% -------------------------------------------------------------------------

% Run LiDAR quality-control diagnostics after DEM preparation.
%
% false = do not generate diagnostics.
% true  = run the LiDAR diagnostic workflow.

CONFIG.dem.Diagnostics = false;


% -------------------------------------------------------------------------
% Terrain-based sky-view factor
% -------------------------------------------------------------------------

% Number of azimuth bins used for the full-Alps ray-traced SVF.

CONFIG.dem.SVFNumBins = 36;

% Maximum terrain distance considered by the SVF ray tracing, in metres.

CONFIG.dem.SVFMaxDistance = 1000;


% =========================================================================
% VP_Geol
% =========================================================================

% -------------------------------------------------------------------------
% Geological products
% -------------------------------------------------------------------------

% DEM resolution used by the geological rasterization.
%
% This should normally be identical to CONFIG.dem.Resolution.
%
% Keeping it explicitly configurable here mirrors the prepare_geology()
% API, but prepare_VP() checks that it is consistent with the DEM
% resolution before starting the workflow.

CONFIG.geology.Resolution = CONFIG.dem.Resolution;

% -------------------------------------------------------------------------
% Geological visualization
% -------------------------------------------------------------------------

% Generate PNG maps of the final CryoGrid geological classes.
%
% false = do not generate geological plots.
% true  = generate one PNG map per massif.
%
% Plots are written to:
%
%     processed/plots/
%
% The plotting step uses the already-generated CryoGrid geology rasters
% and does not rerun the geological classification or raster conversion.

CONFIG.geology.PlotGeology = false;

end