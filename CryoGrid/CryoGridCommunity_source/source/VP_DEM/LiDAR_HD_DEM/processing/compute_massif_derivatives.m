
function compute_massif_derivatives(dem_folder,massif_num,overwrite)
%COMPUTE_MASSIF_DERIVATIVES Compute slope and aspect for one massif.
%
% INPUT
%   dem_folder  Root LiDAR DEM product folder
%   massif_num  SAFRAN massif number
%   overwrite   Recompute existing products (default: false)

if nargin < 3
    overwrite = false;
end

%% Paths

dem_file = fullfile(dem_folder,"DEM", ...
    sprintf("DEM_massif_%02d.tif",massif_num));

slope_folder = fullfile(dem_folder,"SLOPE");
aspect_folder = fullfile(dem_folder,"ASPECT");

if ~isfolder(slope_folder)
    mkdir(slope_folder)
end

if ~isfolder(aspect_folder)
    mkdir(aspect_folder)
end

slope_file = fullfile(slope_folder, ...
    sprintf("SLOPE_massif_%02d.tif",massif_num));

aspect_file = fullfile(aspect_folder, ...
    sprintf("ASPECT_massif_%02d.tif",massif_num));

%% Restart logic

if isfile(slope_file) && isfile(aspect_file) && ~overwrite
    fprintf("Massif %02d derivatives already exist. Skipping.\n",massif_num)
    return
end

%% Read DEM

fprintf("Reading DEM for massif %02d\n",massif_num)

[Z,R] = readgeoraster(dem_file);
Z = single(Z);
Z(Z <= -9000) = NaN;

%% Compute gradients

fprintf("Computing gradients\n")

dx = R.CellExtentInWorldX;
dy = R.CellExtentInWorldY;

[dzdy,dzdx] = gradient(Z,dy,dx);

%% Slope

fprintf("Computing slope\n")

SLOPE = atan(sqrt(dzdx.^2 + dzdy.^2)) * 180/pi;

%% Aspect

fprintf("Computing aspect\n")

ASPECT = atan2(dzdx,-dzdy) * 180/pi;
ASPECT(ASPECT < 0) = ASPECT(ASPECT < 0) + 360;

%% Restore NoData

SLOPE(isnan(Z)) = -9999;
ASPECT(isnan(Z)) = -9999;

SLOPE = single(SLOPE);
ASPECT = single(ASPECT);

%% Write

fprintf("Writing slope\n")
geotiffwrite(slope_file,SLOPE,R,"CoordRefSysCode",2154);

fprintf("Writing aspect\n")
geotiffwrite(aspect_file,ASPECT,R,"CoordRefSysCode",2154);

fprintf("Completed derivatives for massif %02d\n",massif_num)

end
