function prepare_dem(dem_path,path_shapefile,varargin)
%PREPARE_DEM Build CryoGrid-ready topographic products from IGN LiDAR HD.
%
% DESCRIPTION
%   Runs the complete DEM preparation workflow required to generate
%   CryoGrid-compatible topographic inputs from IGN LiDAR HD data over the
%   French Alps.
%
%   The workflow generates:
%
%       - individual SAFRAN massif DEM products
%       - individual massif binary masks
%       - one merged Alpine DEM
%       - Alpine terrain derivatives
%       - massif-scale terrain products clipped from the Alpine products
%       - CryoGrid-compatible aspect products
%       - slope-based sky-view factor (SVF) products
%
%
% WORKFLOW
%
%   1. Read SAFRAN massif polygons.
%
%   2. For each massif:
%       - download IGN LiDAR HD elevation data
%       - split large requests into WMS-compatible chunks
%       - reuse cached WMS downloads when available
%       - clean invalid WMS pixels
%       - merge chunks
%       - clip to massif boundary
%       - save DEM and mask GeoTIFF files
%
%   3. Merge all massif DEMs into one continuous Alpine DEM:
%
%       DEM/ALPS/
%           DEM_ALPS.tif
%           DEM_ALPS_mask.tif
%
%   4. Compute Alpine terrain derivatives:
%
%       SLOPE/ALPS/
%           SLOPE_ALPS.tif
%
%       ASPECT/ALPS/
%           ASPECT_ALPS.tif
%
%   5. Clip Alpine topographic products back to SAFRAN massifs:
%
%       PRODUCT/
%           PRODUCT_massif_XX.tif
%
%   6. Convert standard GIS aspect to the CryoGrid aspect convention:
%
%       ASPECT_CryoGrid/
%           ASPECT_CryoGrid_massif_XX.tif
%
%   7. Compute slope-based sky-view factor:
%
%       SVF/
%           SVF_massif_XX.tif
%
%       The current SVF is calculated as:
%
%           SVF = cos²(slope / 2)
%
%       It is a local slope-based approximation and does not account for
%       surrounding terrain horizons.
%
%   8. Optionally run quality-control diagnostics.
%
%
% INPUTS
%
%   dem_path
%       Parent directory where generated DEM products are stored.
%
%       Example:
%
%           CryoGridCommunity_forcing/DEM/
%
%
%   path_shapefile
%       SAFRAN massif shapefile.
%
%       Requirements:
%
%           - Lambert-93 projection
%           - EPSG:2154
%           - massif_num attribute
%
%
% OPTIONS
%
%   "Resolution"
%       Output DEM resolution in metres.
%
%       Default = 10
%
%   "Overwrite"
%       Recompute existing massif DEM products.
%
%       Default = false
%
%   "Diagnostics"
%       Run run_lidar_diagnostics() after product generation.
%
%       Default = false
%
%
% OUTPUT
%
%   Creates:
%
%       LiDAR_HD_DEM_XXm/
%
%           DEM/
%               DEM_massif_XX.tif
%               DEM_mask_massif_XX.tif
%
%               ALPS/
%                   DEM_ALPS.tif
%                   DEM_ALPS_mask.tif
%
%           SLOPE/
%               ALPS/
%                   SLOPE_ALPS.tif
%
%               SLOPE_massif_XX.tif
%
%           ASPECT/
%               ALPS/
%                   ASPECT_ALPS.tif
%
%               ASPECT_massif_XX.tif
%
%           ASPECT_CryoGrid/
%               ASPECT_CryoGrid_massif_XX.tif
%
%           SVF/
%               SVF_massif_XX.tif
%
%           DEM/cache/
%               Cached IGN WMS chunks
%
%           diagnostics/
%               Quality-control figures and tables
%               (if Diagnostics=true)
%
%
% NOTES
%
%   Terrain derivatives are computed from the merged Alpine DEM before
%   clipping to SAFRAN massifs. This avoids artificial discontinuities at
%   massif boundaries.
%
%   No resampling is performed when clipping products. Massif products are
%   extracted by matching the exact Alpine grid and applying the DEM mask.
%
%   The original GIS aspect products are preserved. The separate
%   ASPECT_CryoGrid/ products use the aspect convention expected by
%   CryoGrid.
%
%   SVF/ contains a slope-based sky-view factor approximation. It is not
%   a horizon-based SVF and therefore does not account for surrounding
%   topographic obstruction.
%
%   All products use:
%
%       Projection: Lambert-93
%       EPSG:       2154
%
%   IGN LiDAR HD WMS requests become unreliable for very large images.
%   Requests are therefore limited to:
%
%       max_width  = 4000 pixels
%       max_height = 4000 pixels
%
%   Existing cached chunks and generated products are reused unless
%   Overwrite=true.
%
%
% SEE ALSO
%
%   process_single_massif
%   merge_massif_DEMs
%   compute_dem_derivatives
%   clip_topography_products
%   convert_aspect_to_cryogrid
%   compute_skyview_factor
%   run_lidar_diagnostics
%

addpath(genpath(fileparts(mfilename('fullpath'))));

%% Options

p = inputParser;

addParameter(p,"Resolution",10)
addParameter(p,"Overwrite",false)
addParameter(p,"Diagnostics",false)

parse(p,varargin{:})

resolution = p.Results.Resolution;
overwrite  = p.Results.Overwrite;
diagnostics = p.Results.Diagnostics;

%% WMS limits

max_width  = 4000;
max_height = 4000;


%% Paths

output_path = fullfile(dem_path,sprintf("LiDAR_HD_DEM_%dm",resolution));
result_path = fullfile(output_path,"DEM");
cache_path  = fullfile(result_path,"cache");

folders = {
    output_path
    result_path
    cache_path
    };


for i=1:numel(folders)
    if ~isfolder(folders{i})
        mkdir(folders{i})
    end
end


%% Step 1

print_step(1,"Read SAFRAN massif polygons")

if ~isfile(path_shapefile)
    error("SAFRAN shapefile not found: %s",path_shapefile)
end
S = shaperead(path_shapefile);
[~,idx] = sort([S.massif_num]);
S = S(idx);



%% Step 2

print_step(2,"Build DEM products for SAFRAN massifs")

for i = 1:numel(S)
    process_single_massif( ...
        S(i),...
        result_path,...
        cache_path,...
        max_width,...
        max_height,...
        resolution,...
        overwrite);
end



%% Step 3

print_step(3,"Merge massifs DEM into a single Alpine DEM")
merge_massif_DEMs(result_path)



%% Step 4

print_step(4,"Compute terrain derivatives")
compute_dem_derivatives(output_path)


%% Step 5

print_step(5,"Clip topography products to massifs")
clip_topography_products(output_path)


%% Step 6

print_step(6,"Convert aspect to CryoGrid convention")
convert_aspect_to_cryogrid(output_path)


%% Step 7

print_step(7,"Compute skyview factor (SVF) from slope")
compute_skyview_factor(output_path)


%% Step 8

if diagnostics
    print_step(8,"Run LiDAR diagnostics")
    run_lidar_diagnostics(output_path,path_shapefile);
end


end