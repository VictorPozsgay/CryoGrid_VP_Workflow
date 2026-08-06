function prepare_dem(dem_path,path_shapefile,varargin)
%PREPARE_DEM Build CryoGrid-ready DEM products from IGN LiDAR HD.
%
% DESCRIPTION
%   Runs the complete DEM preparation workflow required to generate
%   CryoGrid-compatible topographic inputs from IGN LiDAR HD data.
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
%       3. Compute terrain derivatives:
%           - slope
%           - aspect
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
%
%       default = 10
%
%   'Overwrite'
%       Recompute existing massif DEMs.
%
%       default = false
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
%               cache/
%                   Cached IGN WMS chunks
%
%  NOTE
%       IGN LiDAR HD WMS requests become unreliable for very large
%       images. A value of 4000 pixels provides a good compromise between
%       request size and efficiency while keeping a safety margin. The
%       default WMS limits are
%           max_width  = 4000;
%           max_height = 4000;
%
%


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
        output_path,...
        cache_path,...
        max_width,...
        max_height,...
        resolution,...
        overwrite);
end


%% Step 3

print_step(3,"Compute terrain derivatives")
% compute_slope_aspect(...)

end