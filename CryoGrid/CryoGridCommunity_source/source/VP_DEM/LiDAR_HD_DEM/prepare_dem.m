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
%       - one continuous merged Alpine DEM
%       - full-Alps terrain derivatives
%       - full-Alps terrain-based sky-view factor (SVF)
%       - massif-scale topographic products clipped from the Alpine products
%       - CryoGrid-compatible aspect products
%       - massif-scale naive slope-based SVF reference products
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
%       - clip to the massif boundary
%       - save DEM and mask GeoTIFF files
%
%   3. Merge all massif DEMs into one continuous Alpine DEM:
%
%       DEM/ALPS/
%           DEM_ALPS.tif
%           DEM_ALPS_mask.tif
%
%   4. Compute Alpine terrain derivatives from the continuous Alpine DEM:
%
%       SLOPE/ALPS/
%           SLOPE_ALPS.tif
%
%       ASPECT/ALPS/
%           ASPECT_ALPS.tif
%
%   5. Compute the full-Alps terrain-based sky-view factor:
%
%       SVF/ALPS/
%           SVF_ALPS.tif
%
%       The SVF is calculated by horizon ray tracing over the continuous
%       Alpine DEM. The calculation is performed before massif clipping
%       so that surrounding terrain outside individual SAFRAN massifs is
%       included in the horizon calculation.
%
%   6. Clip Alpine topographic products back to the SAFRAN massifs:
%
%       DEM/
%           DEM_massif_XX.tif
%
%       SLOPE/
%           SLOPE_massif_XX.tif
%
%       ASPECT/
%           ASPECT_massif_XX.tif
%
%       SVF/
%           SVF_massif_XX.tif
%
%       Products are extracted from the exact Alpine grid. No resampling
%       or reprojection is performed.
%
%   7. Convert standard GIS aspect to the CryoGrid aspect convention:
%
%       ASPECT_CryoGrid/
%           ASPECT_CryoGrid_massif_XX.tif
%
%   8. Compute a naive slope-based sky-view factor for each massif:
%
%       SVF_naive/
%           SVF_naive_massif_XX.tif
%
%       The naive SVF is calculated as:
%
%           SVF_naive = (1 + cos(slope)) / 2
%                     = cos²(slope / 2)
%
%       This is a purely local self-shading approximation and does not
%       account for surrounding terrain or terrain horizons. It is
%       provided as a reference product for comparison with the
%       terrain-based ray-traced SVF.
%
%   9. Optionally run LiDAR quality-control diagnostics.
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
%       Recompute existing products where supported.
%
%       Default = false
%
%       This option is propagated to the SVF and naive SVF workflows.
%
%   "Diagnostics"
%       Run run_lidar_diagnostics() after product generation.
%
%       Default = false
%
%   "SVFNumBins"
%       Number of azimuth bins used for the full-Alps ray-traced SVF.
%
%       Default = 36
%
%   "SVFMaxDistance"
%       Maximum terrain distance considered by the SVF ray tracing,
%       in metres.
%
%       Default = 1000
%
%
% OUTPUT
%
%   Creates a directory:
%
%       LiDAR_HD_DEM_XXm/
%
%   containing:
%
%       DEM/
%           DEM_massif_XX.tif
%           DEM_mask_massif_XX.tif
%
%           ALPS/
%               DEM_ALPS.tif
%               DEM_ALPS_mask.tif
%
%           cache/
%               Cached IGN WMS chunks
%
%       SLOPE/
%           SLOPE_massif_XX.tif
%
%           ALPS/
%               SLOPE_ALPS.tif
%
%       ASPECT/
%           ASPECT_massif_XX.tif
%
%           ALPS/
%               ASPECT_ALPS.tif
%
%       ASPECT_CryoGrid/
%           ASPECT_CryoGrid_massif_XX.tif
%
%       SVF/
%           SVF_massif_XX.tif
%
%           ALPS/
%               SVF_ALPS.tif
%
%       SVF_naive/
%           SVF_naive_massif_XX.tif
%
%       diagnostics/
%           Generated quality-control figures and tables
%           (if Diagnostics=true)
%
%
% DIAGNOSTICS
%
%   When Diagnostics=true, run_lidar_diagnostics() performs quality-control
%   checks and generates visualization products.
%
%   The diagnostic plotting functions and their visualization-specific
%   helper functions are maintained separately in the source-code
%   plotting/ directory.
%
%   Generated diagnostic outputs are written to:
%
%       diagnostics/
%
%   including:
%
%       - Alpine topography overview maps
%       - massif topography overview maps
%       - DEM missing-pixel maps
%       - DEM validation tables
%       - derivative validation products
%
%
% NOTES
%
%   Terrain derivatives and the ray-traced SVF are computed from the
%   continuous merged Alpine DEM before clipping to SAFRAN massifs.
%   This avoids artificial discontinuities at massif boundaries and
%   allows the SVF ray tracing to account for surrounding terrain.
%
%   Massif-scale products are extracted from the exact Alpine grid and
%   clipped using the SAFRAN massif geometry and DEM validity mask.
%   No resampling or reprojection is performed.
%
%   The original GIS aspect products are preserved. The separate
%   ASPECT_CryoGrid products use the aspect convention expected by
%   CryoGrid.
%
%   The SVF products are terrain-horizon-based sky-view factors computed
%   by ray tracing over the full Alpine DEM.
%
%   The SVF_naive products are slope-only reference values and do not
%   represent surrounding terrain obstruction.
%
%   All topographic products use:
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
%   compute_skyview_factor_alps
%   clip_topography_products
%   convert_aspect_to_cryogrid
%   compute_naive_svf
%   run_lidar_diagnostics
%

addpath(genpath(fileparts(mfilename('fullpath'))));

%% Options

p = inputParser;

addParameter(p,"Resolution",10)
addParameter(p,"Overwrite",false)
addParameter(p,"Diagnostics",false)
addParameter(p,"SVFNumBins",36)
addParameter(p,"SVFMaxDistance",1000)

parse(p,varargin{:})

resolution       = p.Results.Resolution;
overwrite        = p.Results.Overwrite;
diagnostics      = p.Results.Diagnostics;
svf_num_bins     = p.Results.SVFNumBins;
svf_max_distance = p.Results.SVFMaxDistance;

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

print_step(5,"Compute full-Alps skyview factor (SVF)")
compute_skyview_factor_alps( ...
    output_path, ...
    "NumBins",svf_num_bins, ...
    "MaxDistance",svf_max_distance, ...
    "Overwrite",overwrite)


%% Step 6

print_step(6,"Clip topography products to massifs")
clip_topography_products(output_path)


%% Step 7

print_step(7,"Convert aspect to CryoGrid convention")
convert_aspect_to_cryogrid(output_path)


%% Step 8

print_step(8,"Compute naive slope-based skyview factor")
compute_naive_svf(output_path,"Overwrite",overwrite)


%% Step 9

if diagnostics
    print_step(9,"Run LiDAR diagnostics")
    run_lidar_diagnostics(output_path,path_shapefile,1);
end

%% Complete

fprintf("\n================================================\n")
fprintf("prepare_dem() completed\n")
fprintf("================================================\n")

end