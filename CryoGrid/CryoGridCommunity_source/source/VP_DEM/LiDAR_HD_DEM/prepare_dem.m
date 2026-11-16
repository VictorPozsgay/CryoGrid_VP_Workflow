function prepare_dem(dem_path,path_shapefile,varargin)
%PREPARE_DEM Build CryoGrid-ready topographic products from IGN LiDAR HD.
%
% DESCRIPTION
%   Generates topographic products from IGN LiDAR HD data over the French
%   Alps. Two processing modes are available:
%
%       1. Alps
%          Builds a continuous Alpine DEM, computes terrain derivatives
%          and terrain-based SVF over the full Alps, and subsequently
%          extracts the products for individual SAFRAN massifs.
%
%       2. Independent
%          Processes each SAFRAN massif separately. Computes its DEM,
%          slope and aspect without merging the massifs into a continuous
%          Alpine raster. No SVF is calculated in this mode.
%
%   The default mode is "Alps", preserving the original workflow.
%
%
% COMMON WORKFLOW
%
%   The following steps are performed in both processing modes:
%
%   1. Read and sort SAFRAN massif polygons.
%
%   2. Prepare an individual DEM for each massif:
%       - download IGN LiDAR HD elevation data
%       - split large requests into WMS-compatible chunks
%       - reuse cached WMS downloads when available
%       - clean invalid WMS pixels
%       - merge chunks belonging to the same massif
%       - clip the DEM to the massif boundary
%       - save the DEM and binary mask as GeoTIFF files
%
%
% PROCESSING MODE 1: "Alps"
%
%   Builds continuous topographic products over the full Alpine domain.
%
%   3. Merge all individual massif DEMs into one continuous Alpine DEM:
%
%       DEM/ALPS/
%           DEM_ALPS.tif
%           DEM_ALPS_mask.tif
%
%   4. Compute terrain derivatives from the continuous Alpine DEM:
%
%       SLOPE/ALPS/
%           SLOPE_ALPS.tif
%
%       ASPECT/ALPS/
%           ASPECT_ALPS.tif
%
%   5. Compute the terrain-based sky-view factor (SVF) over the full Alps:
%
%       SVF/ALPS/
%           SVF_ALPS.tif
%
%      The SVF is calculated by horizon ray tracing over the continuous
%      Alpine DEM, before clipping to individual massifs. This allows
%      surrounding terrain outside each massif to contribute to the
%      horizon calculation.
%
%   6. Clip the Alpine topographic products to individual SAFRAN massifs:
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
%      Products are extracted from the Alpine grid. No resampling or
%      reprojection is performed.
%
%   7. Convert standard GIS aspect to the CryoGrid aspect convention:
%
%       ASPECT_CryoGrid/
%           ASPECT_CryoGrid_massif_XX.tif
%
%   8. Compute a naive slope-based SVF reference for each massif:
%
%       SVF_naive/
%           SVF_naive_massif_XX.tif
%
%      Calculated as:
%
%          SVF_naive = (1 + cos(slope)) / 2
%                    = cos^2(slope / 2)
%
%      This is a local self-shading approximation. It does not account
%      for surrounding terrain or terrain horizons.
%
%   9. Optionally run Alpine-wide LiDAR diagnostics.
%
%
% PROCESSING MODE 2: "Independent"
%
%   Processes each massif separately, without constructing a continuous
%   Alpine DEM.
%
%   3. Compute slope and aspect independently from each clipped massif DEM:
%
%       SLOPE/
%           SLOPE_massif_XX.tif
%
%       ASPECT/
%           ASPECT_massif_XX.tif
%
%      Derivatives are calculated using the terrain available within each
%      clipped DEM. Boundary effects may therefore occur near massif edges.
%
%   4. Optionally run diagnostics for all available massifs. Each massif
%      is visualised separately, with its own DEM colour scale.
%
%   The following products are not generated in this mode:
%       - merged Alpine DEM
%       - Alpine-wide terrain derivatives
%       - terrain-based SVF
%       - CryoGrid aspect conversion
%       - naive slope-based SVF
%
%
% INPUTS
%
%   dem_path
%       Parent directory where generated DEM products are stored.
%
%   path_shapefile
%       SAFRAN massif shapefile.
%
%       Requirements:
%           - Lambert-93 projection
%           - EPSG:2154
%           - massif_num attribute
%
%
% OPTIONS
%
%   "ProcessingMode"
%       Selects the processing workflow:
%
%           "Alps"          Full Alpine workflow (default).
%           "Independent"   Process each massif separately.
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
%   "Diagnostics"
%       Run run_lidar_diagnostics() after product generation.
%
%       Default = false
%
%   "SVFNumBins"
%       Number of azimuth bins used for the full-Alps ray-traced SVF.
%
%       Default = 36
%       Only used in "Alps" mode.
%
%   "SVFMaxDistance"
%       Maximum terrain distance considered by the SVF ray tracing,
%       in metres.
%
%       Default = 1000
%       Only used in "Alps" mode.
%
%
% OUTPUT
%
%   Creates a directory:
%
%       LiDAR_HD_DEM_XXm/
%
%   Both modes generate individual massif DEMs and masks:
%
%       DEM/
%           DEM_massif_XX.tif
%           DEM_mask_massif_XX.tif
%           cache/
%               Cached IGN WMS chunks
%
%   Additional products depend on the selected processing mode.
%
%   "Alps":
%       DEM/ALPS/
%       SLOPE/ALPS/
%       ASPECT/ALPS/
%       SVF/ALPS/
%       SLOPE/
%       ASPECT/
%       SVF/
%       ASPECT_CryoGrid/
%       SVF_naive/
%
%   "Independent":
%       SLOPE/
%       ASPECT/
%
%   When Diagnostics=true:
%
%       diagnostics/
%           Generated quality-control figures and tables
%
%
% DIAGNOSTICS
%
%   Diagnostics are performed according to the selected processing mode:
%
%       Alps:
%           Alpine-wide and massif-scale quality-control visualisations.
%
%       Independent:
%           Separate topographic visualisations for each available
%           massif, with individual DEM colour scales.
%
%   Diagnostic plotting functions and their visualisation-specific
%   helper functions are maintained separately in the plotting/ directory.
%
%
% NOTES
%
%   The two processing modes have different approaches to calculating
%   terrain derivatives:
%
%       Alps:
%           Derivatives are calculated from the continuous Alpine DEM
%           before clipping. This avoids artificial discontinuities at
%           massif boundaries.
%
%       Independent:
%           Derivatives are calculated directly from each clipped massif
%           DEM. This avoids the memory and storage requirements of
%           constructing a continuous Alpine raster, but may introduce
%           boundary effects.
%
%   All topographic products use:
%
%       Projection: Lambert-93
%       EPSG:       2154
%
%   IGN LiDAR HD WMS requests are limited to:
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
%   compute_massif_derivatives
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
addParameter(p,"ProcessingMode","Alps")

parse(p,varargin{:})

resolution       = p.Results.Resolution;
overwrite        = p.Results.Overwrite;
diagnostics      = p.Results.Diagnostics;
svf_num_bins     = p.Results.SVFNumBins;
svf_max_distance = p.Results.SVFMaxDistance;
processing_mode  = lower(string(p.Results.ProcessingMode));

if ~ismember(processing_mode,["alps","independent"])
    error('ProcessingMode must be "Alps" or "Independent".')
end

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

if processing_mode == "independent"

    %% Step 3 : Independent massif processing

    print_step(3,"Compute slope and aspect for each massif")

    for i = 1:numel(S)

        massif_num = S(i).massif_num;

        compute_massif_derivatives( ...
            output_path, ...
            massif_num, ...
            overwrite);

    end

    %% Step 4 : Diagnostics (optional)

    if diagnostics
        print_step(4,"Run LiDAR diagnostics")
        run_lidar_diagnostics( ...
            output_path, ...
            path_shapefile, ...
            "Independent");

    end

else

    %% Existing Alpine-wide workflow

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

end


%% Complete

fprintf("\n================================================\n")
fprintf("prepare_dem() completed\n")
fprintf("================================================\n")

end