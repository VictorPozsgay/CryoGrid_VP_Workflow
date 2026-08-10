function prepare_geology(geology_path,dem_path,varargin)
%PREPARE_GEOLOGY Build BRGM geology products for CryoGrid workflows.
%
% PREPARE_GEOLOGY(GEOLOGY_PATH,DEM_FOLDER,VARARGIN) executes the complete
% BRGM GEO050K_HARM preparation workflow.
%
%   The workflow is restartable: individual functions check whether their
%   output already exists and skip processing when possible.
%
%   The DEM directory follows the same convention as prepare_dem():
%
%       dem_path/
%           LiDAR_HD_DEM_XXm/
%               DEM/
%                   DEM_massif_XX.tif
%
%
% WORKFLOW
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
%   4. Rasterize geology on the CryoGrid DEM grids
%      Creates:
%          processed/raster/GEOLOGY_massif_XX.tif
%
%      Raster values correspond to the original BRGM inventory IDs.
%      NoData pixels are stored as -9999.
%
%   5. Build raster-domain geological inventory
%      Creates:
%          processed/BRGM_GEO050K_HARM_raster_inventory.mat
%
%      This reduced inventory contains only geological units actually
%      represented inside the CryoGrid DEM domain.
%
%   6. Build final CryoGrid mask
%      Creates:
%          LiDAR_HD_DEM_XXm/
%              MASK/
%                  MASK_massif_XX.tif
%
%      The final mask retains only pixels with valid:
%
%          - DEM elevation
%          - slope
%          - aspect
%          - geology
%
%      A masking log is also created in:
%
%          LiDAR_HD_DEM_XXm/
%              MASK/
%                  masking_log.mat
%
%
% INPUT
%
%   geology_path
%       Root geology directory containing:
%
%           geology_path/
%               BRGM_GEO050K_HARM/
%                   raw/
%                   processed/
%
%
%   dem_path
%       Root DEM directory containing the resolution-specific DEM
%       product folder:
%
%           dem_path/
%               LiDAR_HD_DEM_XXm/
%                   DEM/
%                       DEM_massif_XX.tif
%
%
% OPTIONS
%
%   "Resolution"
%       DEM resolution in metres.
%
%       Default = 10
%
%
% EXAMPLE
%
%   prepare_geology( ...
%       "CryoGridCommunity_forcing/geology", ...
%       "CryoGridCommunity_forcing/DEM")
%
%   For a different DEM resolution:
%
%   prepare_geology( ...
%       "CryoGridCommunity_forcing/geology", ...
%       "CryoGridCommunity_forcing/DEM", ...
%       "Resolution",20)
%
%
% SEE ALSO
%
%   prepare_dem
%   rasterize_BRGM_geology
%   build_BRGM_raster_inventory
%   build_final_mask
%


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
% STEP 5 - Build raster inventory
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 5 - BRGM raster inventory\n")
fprintf("================================================\n")

build_BRGM_raster_inventory(brgm_path)


%% ============================================================
% STEP 6 - Build final mask
% =============================================================

fprintf("\n================================================\n")
fprintf("STEP 6 - Building final mask\n")
fprintf("================================================\n")

build_final_mask(brgm_path,dem_folder)


%% Complete

fprintf("\n================================================\n")
fprintf("prepare_geology completed\n")
fprintf("================================================\n")

end