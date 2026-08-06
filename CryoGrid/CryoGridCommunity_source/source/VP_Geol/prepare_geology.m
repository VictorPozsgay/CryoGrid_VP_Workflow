function prepare_geology(geology_path,dem_folder)
%PREPARE_GEOLOGY Build BRGM geology products for CryoGrid workflows.
%
% PREPARE_GEOLOGY(GEOLOGY_PATH,DEM_FOLDER) executes the complete BRGM
% GEO050K_HARM preparation workflow.
%
% The workflow is restartable: individual functions check whether their
% output already exists and skip processing when possible.
%
% Workflow:
%
%   1. Download BRGM GEO050K_HARM geological datasets
%
%   2. Merge department shapefiles
%      Creates:
%          processed/BRGM_GEO050K_HARM_ALPES.mat
%
%   3. Build complete BRGM geological inventory
%      Creates:
%          processed/BRGM_GEO050K_HARM_inventory.mat
%
%      This inventory contains all geological units present in the merged
%      BRGM Alpine dataset.
%
%   4. Rasterize geology on CryoGrid DEM grids
%      Creates:
%          processed/raster/GEOLOGY_massif_XX.tif
%
%      Raster values correspond to the original BRGM inventory IDs.
%      No-data pixels are stored as -9999.
%
%   5. Build raster-domain geological inventory
%      Creates:
%          processed/BRGM_GEO050K_HARM_raster_inventory.mat
%
%      This reduced inventory contains only geological units actually
%      represented inside the CryoGrid DEM domain.
%
%
% INPUT
%
%   geology_path
%       Root BRGM_GEO050K_HARM directory.
%
%       Expected structure:
%
%       BRGM_GEO050K_HARM/
%           raw/
%           processed/
%
%
%   dem_folder
%       Folder containing DEM_massif_XX.tif files.
%
%
% Example:
%
%   prepare_geology(geology_path,dem_folder)
%


%% Add local functions

addpath(genpath(fileparts(mfilename('fullpath'))))


%% Paths

raw_path = fullfile(geology_path,"raw");


%% ============================================================
% STEP 1 - Download BRGM data
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 1 - BRGM download\n")
fprintf("================================================\n")

download_BRGM(raw_path)


%% ============================================================
% STEP 2 - Merge departments
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 2 - BRGM merge\n")
fprintf("================================================\n")

merge_BRGM_departments(geology_path)


%% ============================================================
% STEP 3 - Build geological inventory
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 3 - BRGM inventory\n")
fprintf("================================================\n")

build_BRGM_inventory(geology_path)


%% ============================================================
% STEP 4 - Rasterize geology
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 4 - BRGM rasterization\n")
fprintf("================================================\n")

rasterize_BRGM_geology(geology_path,dem_folder)


%% ============================================================
% STEP 5 - Build raster inventory
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 5 - BRGM raster inventory\n")
fprintf("================================================\n")

build_BRGM_raster_inventory(geology_path)


fprintf("\n================================================\n")
fprintf("prepare_geology completed\n")
fprintf("================================================\n")


end