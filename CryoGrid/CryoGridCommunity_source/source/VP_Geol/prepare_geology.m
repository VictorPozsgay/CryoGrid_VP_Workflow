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

%% Step 1

print_step(1,"Download BRGM data")
download_BRGM(raw_path)

%% Step 2

print_step(2,"Merge departments")
merge_BRGM_departments(brgm_path)

%% Step 3

print_step(3,"Build geological inventory")
build_BRGM_inventory(brgm_path)

%% Step 4

print_step(4,"Rasterize BRGM geology")
rasterize_BRGM_geology(brgm_path,dem_folder)

%% Step 5

print_step(5,"Build raster-domain inventory")
build_BRGM_raster_inventory(brgm_path)

%% Step 6

print_step(6,"Classify BRGM geology for CryoGrid")
classify_BRGM_geology(brgm_path)

%% Step 7

print_step(7,"Convert geology rasters to CryoGrid codes")
raster_conversion(brgm_path)

%% Step 8

print_step(8,"Build final mask")
build_final_mask(brgm_path,dem_folder)

%% Complete

fprintf("\n================================================\n")
fprintf("prepare_geology() completed\n")
fprintf("================================================\n")

end