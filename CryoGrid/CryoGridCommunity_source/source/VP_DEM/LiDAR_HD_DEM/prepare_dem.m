function prepare_dem(dem_path,path_shapefile,varargin)
%PREPARE_DEM Build CryoGrid-ready topographic products from IGN LiDAR HD.
%
% DESCRIPTION
%   Runs the complete workflow required to generate CryoGrid-compatible
%   topographic products from IGN LiDAR HD elevation data.
%
%   The workflow performs:
%
%       1. Read SAFRAN massif polygons
%
%       2. For each massif:
%           - download IGN LiDAR HD elevation data
%           - merge WMS chunks
%           - remove invalid pixels
%           - clip to massif boundary
%           - save DEM and mask GeoTIFF files
%
%       3. Merge massif DEMs into a continuous Alpine DEM
%
%       4. Compute Alpine topography products
%           - slope
%           - aspect
%
%       5. Clip Alpine topography products back to individual
%          SAFRAN massifs
%
%
% INPUT
%
%   dem_path
%       Root directory for generated DEM products.
%
%   path_shapefile
%       SAFRAN massif shapefile (Lambert-93 / EPSG:2154).
%
%
% OPTIONS
%
%   'Resolution'
%       DEM resolution in metres.
%       Default = 10
%
%   'Overwrite'
%       Recompute existing products.
%       Default = false
%
%
% OUTPUT
%
%   Creates a directory:
%       LiDAR_HD_DEM_XXm/
%
%   containing:
%
%       DEM/
%           DEM_massif_XX.tif
%           DEM_mask_massif_XX.tif
%           ALPS/
%               DEM_ALPS.tif
%               DEM_ALPS_mask.tif
%           cache/
%
%       SLOPE/
%           ALPS/
%               SLOPE_ALPS.tif
%           SLOPE_massif_XX.tif
%
%       ASPECT/
%           ALPS/
%               ASPECT_ALPS.tif
%           ASPECT_massif_XX.tif
%
%   Additional topographic products may be added in future releases
%   following the same directory structure.
%
%
% NOTE
%
%   IGN LiDAR HD WMS requests become unreliable for very large images.
%   Requests are therefore limited to:
%
%       max_width  = 4000 pixels
%       max_height = 4000 pixels
%
%   which provides a good compromise between efficiency and robustness.


addpath(genpath(fileparts(mfilename('fullpath'))));


%% Options

p = inputParser;

addParameter(p,"Resolution",10)
addParameter(p,"Overwrite",false)

parse(p,varargin{:})

resolution = p.Results.Resolution;
overwrite  = p.Results.Overwrite;

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

end