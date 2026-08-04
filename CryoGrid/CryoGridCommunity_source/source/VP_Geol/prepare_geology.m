function prepare_geology(forcing_path)
%PREPARE_GEOLOGY Build the geological dataset required by CryoGrid workflows.
%
% PREPARE_GEOLOGY(FORCING_PATH) executes the complete prepare_geology workflow.
%
% The workflow is restartable: each step checks whether the required
% output already exists and skips processing when possible.
%
% Current workflow:
%
%   1. Download BRGM GEO050K_HARM geological datasets
%
% Future steps:
%
%   2. Read and harmonize geological vectors
%   3. Convert geological units to raster grids
%   4. Project geology onto DEM grids
%   5. Clip to massif masks
%
%
% INPUT
%
%   forcing_path
%       Root CryoGridCommunity_forcing directory.
%
%       Example:
%
%       "D:\...\CryoGridCommunity_forcing"
%
%

%% Paths

addpath(genpath(fileparts(mfilename('fullpath'))))

raw_path = fullfile(forcing_path,"raw");

%% ============================================================
%  STEP 1 - Download BRGM data
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 1 - BRGM download\n")
fprintf("================================================\n")

download_BRGM(raw_path)

%% Future steps

% prepare_geology_process(...)
% prepare_geology_rasterize(...)
% prepare_geology_project(...)


fprintf("\nprepare_geology completed.\n")

end