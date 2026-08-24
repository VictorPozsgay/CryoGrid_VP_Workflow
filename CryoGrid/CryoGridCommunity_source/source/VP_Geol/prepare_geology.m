function prepare_geology(geology_path,dem_path,varargin)
%PREPARE_GEOLOGY Build BRGM geology products for CryoGrid workflows.
%
% PREPARE_GEOLOGY(GEOLOGY_PATH,DEM_PATH,VARARGIN) executes the complete
% BRGM GEO050K_HARM preparation workflow.
%
% The workflow is restartable: individual functions check whether their
% outputs already exist and skip processing when possible.
%
% WORKFLOW
%   1. Download BRGM GEO050K_HARM geological datasets.
%   2. Merge department shapefiles.
%   3. Build the complete BRGM geological inventory.
%   4. Rasterize geology on the CryoGrid DEM grids.
%      Output values are original BRGM ID_original values.
%   5. Build the raster-domain geological inventory.
%   6. Classify BRGM geological units into CryoGrid classes.
%      Creates:
%          processed/BRGM_CryoGrid_classification_log.txt
%          processed/BRGM_CryoGrid_classification_index.mat
%   7. Convert BRGM geology rasters from ID_original to CryoGrid codes.
%      Creates:
%          processed/raster_CryoGrid/GEOLOGY_massif_XX.tif
%   8. Build the final CryoGrid mask.
%
% INPUT
%   geology_path
%       Root geology directory containing:
%
%           geology_path/
%               BRGM_GEO050K_HARM/
%                   raw/
%                   processed/
%
%   dem_path
%       Root DEM directory containing:
%
%           dem_path/
%               LiDAR_HD_DEM_XXm/
%                   DEM/
%                       DEM_massif_XX.tif
%
% OPTIONS
%   "Resolution"
%       DEM resolution in metres.
%       Default = 10
%
% EXAMPLE
%   prepare_geology( ...
%       "CryoGridCommunity_forcing/geology", ...
%       "CryoGridCommunity_forcing/DEM")
%
%   prepare_geology( ...
%       "CryoGridCommunity_forcing/geology", ...
%       "CryoGridCommunity_forcing/DEM", ...
%       "Resolution",20)
%
% SEE ALSO
%   prepare_dem
%   download_BRGM
%   merge_BRGM_departments
%   build_BRGM_inventory
%   rasterize_BRGM_geology
%   build_BRGM_raster_inventory
%   classify_BRGM_geology
%   raster_conversion
%   build_final_mask

%% Add local functions

addpath(genpath(fileparts(mfilename("fullpath"))))

%% Options

p = inputParser;
addParameter(p,"Resolution",10)
parse(p,varargin{:})
resolution = p.Results.Resolution;

%% Paths

brgm_path  = fullfile(geology_path,"BRGM_GEO050K_HARM");
raw_path   = fullfile(brgm_path,"raw");
dem_folder = fullfile(dem_path,sprintf("LiDAR_HD_DEM_%dm",resolution));

%% Check DEM folder

if ~isfolder(dem_folder)
    error("DEM folder not found: %s",dem_folder)
end

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

merge_BRGM_departments(brgm_path)

%% ============================================================
% STEP 3 - Build geological inventory
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 3 - BRGM inventory\n")
fprintf("================================================\n")

build_BRGM_inventory(brgm_path)

%% ============================================================
% STEP 4 - Rasterize geology
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 4 - BRGM rasterization\n")
fprintf("================================================\n")

rasterize_BRGM_geology(brgm_path,dem_folder)

%% ============================================================
% STEP 5 - Build raster-domain inventory
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 5 - BRGM raster inventory\n")
fprintf("================================================\n")

build_BRGM_raster_inventory(brgm_path)

%% ============================================================
% STEP 6 - Classify BRGM geology
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 6 - BRGM CryoGrid classification\n")
fprintf("================================================\n")

classify_BRGM_geology(brgm_path)

%% ============================================================
% STEP 7 - Convert geology rasters to CryoGrid codes
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 7 - BRGM -> CryoGrid raster conversion\n")
fprintf("================================================\n")

raster_conversion(brgm_path)

%% ============================================================
% STEP 8 - Build final mask
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 8 - Building final mask\n")
fprintf("================================================\n")

build_final_mask(brgm_path,dem_folder)

%% Complete

fprintf("\n================================================\n")
fprintf("prepare_geology completed\n")
fprintf("================================================\n")

end
