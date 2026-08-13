function plot_svf_comparison(dem_path)
%PLOT_SVF_COMPARISON Compare DEM, aspect, slope and two SVF formulations.
%
% Plots exactly the 301 x 301 TestMode region contained in the
% ray-traced SVF raster.
%
% Panels:
%   1. DEM
%   2. Aspect
%   3. Slope
%   4. Naive SVF = (1 + cosd(SLOPE))/2
%   5. Ray-traced SVF
%   6. Ray-traced - Naive SVF
%
% IMPORTANT:
%   No raster is resampled or interpolated.
%   The DEM/SLOPE/ASPECT pixels corresponding to the finite SVF pixels
%   are extracted directly from their native 10 m rasters.
%
% INPUT
%   dem_path : full path to DEM_massif_XX.tif
%
% Example:
%
% plot_svf_comparison( ...
%     "D:\...\LiDAR_HD_DEM_10m\DEM\DEM_massif_12.tif")

%% ------------------------------------------------------------------------
% Paths
% -------------------------------------------------------------------------

[dem_folder,dem_name,~] = fileparts(dem_path);

tok = regexp(dem_name,"DEM_massif_(\d+)","tokens","once");

if isempty(tok)
    error("Could not determine massif number from DEM filename.")
end

massif_id = tok{1};

base_folder = fileparts(dem_folder);

slope_path = fullfile( ...
    base_folder, ...
    "SLOPE", ...
    "SLOPE_massif_" + massif_id + ".tif");

aspect_path = fullfile( ...
    base_folder, ...
    "ASPECT", ...
    "ASPECT_massif_" + massif_id + ".tif");

svf_path = fullfile( ...
    base_folder, ...
    "SVF", ...
    "SVF_massif_" + massif_id + ".tif");

%% ------------------------------------------------------------------------
% Read rasters
% -------------------------------------------------------------------------

fprintf("Reading DEM    : %s\n",dem_path)
[DEM,Rdem] = readgeoraster(dem_path);

fprintf("Reading SLOPE  : %s\n",slope_path)
[SLOPE,Rslope] = readgeoraster(slope_path);

fprintf("Reading ASPECT : %s\n",aspect_path)
[ASPECT,Raspect] = readgeoraster(aspect_path);

fprintf("Reading SVF    : %s\n",svf_path)
[SVF,Rsvf] = readgeoraster(svf_path);

DEM    = double(DEM);
SLOPE  = double(SLOPE);
ASPECT = double(ASPECT);
SVF    = double(SVF);

%% ------------------------------------------------------------------------
% Check native raster sizes
% -------------------------------------------------------------------------

fprintf("\n")
fprintf("Raster sizes:\n")
fprintf("DEM    : %d x %d\n",size(DEM,1),size(DEM,2))
fprintf("SLOPE  : %d x %d\n",size(SLOPE,1),size(SLOPE,2))
fprintf("ASPECT : %d x %d\n",size(ASPECT,1),size(ASPECT,2))
fprintf("SVF    : %d x %d\n",size(SVF,1),size(SVF,2))

%% ------------------------------------------------------------------------
% Find finite ray-traced SVF region
% -------------------------------------------------------------------------

valid_svf = isfinite(SVF);

if ~any(valid_svf(:))
    error("Ray-traced SVF contains no finite pixels.")
end

[row_svf,col_svf] = find(valid_svf);

r1_svf = min(row_svf);
r2_svf = max(row_svf);

c1_svf = min(col_svf);
c2_svf = max(col_svf);

fprintf("\n")
fprintf("Ray-traced SVF finite region:\n")
fprintf("Rows    : %d - %d\n",r1_svf,r2_svf)
fprintf("Columns : %d - %d\n",c1_svf,c2_svf)
fprintf("Size    : %d x %d\n", ...
    r2_svf-r1_svf+1, ...
    c2_svf-c1_svf+1)
fprintf("Finite pixels : %d\n",nnz(valid_svf))

%% ------------------------------------------------------------------------
% Extract SVF test region
% -------------------------------------------------------------------------

SVF_test = SVF( ...
    r1_svf:r2_svf, ...
    c1_svf:c2_svf);

%% ------------------------------------------------------------------------
% Determine world coordinates of SVF test-region centres
% -------------------------------------------------------------------------

x_svf = Rsvf.XWorldLimits(1) + ...
    ((c1_svf:c2_svf)-0.5) .* Rsvf.CellExtentInWorldX;

y_svf = Rsvf.YWorldLimits(2) - ...
    ((r1_svf:r2_svf)-0.5) .* Rsvf.CellExtentInWorldY;

%% ------------------------------------------------------------------------
% Find corresponding native DEM pixels
% -------------------------------------------------------------------------

x1 = x_svf(1);
x2 = x_svf(end);

y1 = y_svf(1);
y2 = y_svf(end);

[c1,r1] = worldToIntrinsic(Rdem,x1,y1);
[c2,r2] = worldToIntrinsic(Rdem,x2,y2);

c1 = round(c1);
c2 = round(c2);

r1 = round(r1);
r2 = round(r2);

cmin = min(c1,c2);
cmax = max(c1,c2);

rmin = min(r1,r2);
rmax = max(r1,r2);

if rmin < 1 || rmax > size(DEM,1) || ...
   cmin < 1 || cmax > size(DEM,2)

    error("SVF test region lies outside the DEM.")
end

%% ------------------------------------------------------------------------
% Extract native DEM/SLOPE/ASPECT
%
% IMPORTANT:
% Direct indexing only.
% No interpolation.
% No resampling.
% No averaging.
% -------------------------------------------------------------------------

DEM_test = DEM(rmin:rmax,cmin:cmax);

SLOPE_test = SLOPE(rmin:rmax,cmin:cmax);

ASPECT_test = ASPECT(rmin:rmax,cmin:cmax);

%% ------------------------------------------------------------------------
% Check dimensions
% -------------------------------------------------------------------------

if ~isequal(size(DEM_test),size(SVF_test))

    error( ...
        "Native DEM region does not match SVF dimensions: " + ...
        "DEM %d x %d, SVF %d x %d", ...
        size(DEM_test,1),size(DEM_test,2), ...
        size(SVF_test,1),size(SVF_test,2));

end

%% ------------------------------------------------------------------------
% Naive slope-based SVF
%
% SVF = (1 + cosd(SLOPE))/2
%     = cosd(SLOPE/2).^2
% -------------------------------------------------------------------------

SVF_naive = (1 + cosd(SLOPE_test)) / 2;

%% ------------------------------------------------------------------------
% Keep exactly the finite ray-traced region
% -------------------------------------------------------------------------

valid = isfinite(SVF_test);

DEM_test(~valid)    = NaN;
SLOPE_test(~valid)  = NaN;
ASPECT_test(~valid) = NaN;
SVF_naive(~valid)   = NaN;

%% ------------------------------------------------------------------------
% Native DEM plotting coordinates
% -------------------------------------------------------------------------

x = Rdem.XWorldLimits(1) + ...
    ((cmin:cmax)-0.5) .* Rdem.CellExtentInWorldX;

y = Rdem.YWorldLimits(2) - ...
    ((rmin:rmax)-0.5) .* Rdem.CellExtentInWorldY;

%% ------------------------------------------------------------------------
% Verify that plotting region really is 301 x 301
% -------------------------------------------------------------------------

fprintf("\n")
fprintf("============================================================\n")
fprintf("SVF PLOTTING REGION\n")
fprintf("============================================================\n")

fprintf("Massif          : %s\n",massif_id)

fprintf("Plot size       : %d x %d pixels\n", ...
    size(SVF_test,1),size(SVF_test,2))

fprintf("DEM resolution  : %.2f x %.2f m\n", ...
    Rdem.CellExtentInWorldX, ...
    Rdem.CellExtentInWorldY)

fprintf("X range         : %.1f - %.1f m\n", ...
    min(x),max(x))

fprintf("Y range         : %.1f - %.1f m\n", ...
    min(y),max(y))

fprintf("Valid SVF pixels: %d\n",nnz(valid))

%% ------------------------------------------------------------------------
% Create figure
% -------------------------------------------------------------------------

figure( ...
    "Name","SVF comparison - Massif " + massif_id, ...
    "Color","w");

tiledlayout(2,3, ...
    "TileSpacing","compact", ...
    "Padding","compact");

%% ------------------------------------------------------------------------
% 1. DEM
% -------------------------------------------------------------------------

nexttile

h = imagesc(x,y,DEM_test);
h.Interpolation = "nearest";

set(gca,"YDir","normal")
axis image

xlabel("Easting (m)")
ylabel("Northing (m)")
title("DEM")

cb = colorbar;
cb.Label.String = "Elevation (m)";

%% ------------------------------------------------------------------------
% 2. Aspect
% -------------------------------------------------------------------------

nexttile

h = imagesc(x,y,ASPECT_test);
h.Interpolation = "nearest";

set(gca,"YDir","normal")
axis image

xlabel("Easting (m)")
ylabel("Northing (m)")
title("Aspect")

cb = colorbar;
cb.Label.String = "Aspect (deg)";

clim([0 360])

%% ------------------------------------------------------------------------
% 3. Slope
% -------------------------------------------------------------------------

nexttile

h = imagesc(x,y,SLOPE_test);
h.Interpolation = "nearest";

set(gca,"YDir","normal")
axis image

xlabel("Easting (m)")
ylabel("Northing (m)")
title("Slope")

cb = colorbar;
cb.Label.String = "Slope (deg)";

%% ------------------------------------------------------------------------
% 4. Naive SVF
% -------------------------------------------------------------------------

nexttile

h = imagesc(x,y,SVF_naive);
h.Interpolation = "nearest";

set(gca,"YDir","normal")
axis image

xlabel("Easting (m)")
ylabel("Northing (m)")
title("Naive SVF")

cb = colorbar;
cb.Label.String = "SVF";

clim([0 1])

%% ------------------------------------------------------------------------
% 5. Ray-traced SVF
% -------------------------------------------------------------------------

nexttile

h = imagesc(x,y,SVF_test);
h.Interpolation = "nearest";

set(gca,"YDir","normal")
axis image

xlabel("Easting (m)")
ylabel("Northing (m)")
title("Ray-traced SVF")

cb = colorbar;
cb.Label.String = "SVF";

clim([0 1])

%% ------------------------------------------------------------------------
% 6. Difference
% -------------------------------------------------------------------------

SVF_difference = SVF_test - SVF_naive;

nexttile

h = imagesc(x,y,SVF_difference);
h.Interpolation = "nearest";

set(gca,"YDir","normal")
axis image

xlabel("Easting (m)")
ylabel("Northing (m)")
title("Ray-traced - Naive SVF")

cb = colorbar;
cb.Label.String = "\Delta SVF";

%% ------------------------------------------------------------------------
% Diagnostics
% -------------------------------------------------------------------------

fprintf("\nNaive SVF:\n")
fprintf("  Mean          : %.6f\n", ...
    mean(SVF_naive(:),"omitnan"))

fprintf("  Min           : %.6f\n", ...
    min(SVF_naive(:),[],"omitnan"))

fprintf("  Max           : %.6f\n", ...
    max(SVF_naive(:),[],"omitnan"))

fprintf("\nRay-traced SVF:\n")
fprintf("  Mean          : %.6f\n", ...
    mean(SVF_test(:),"omitnan"))

fprintf("  Min           : %.6f\n", ...
    min(SVF_test(:),[],"omitnan"))

fprintf("  Max           : %.6f\n", ...
    max(SVF_test(:),[],"omitnan"))

fprintf("\nDEM diagnostics:\n")

fprintf("  Min           : %.2f m\n", ...
    min(DEM_test(:),[],"omitnan"))

fprintf("  Max           : %.2f m\n", ...
    max(DEM_test(:),[],"omitnan"))

fprintf("  Std           : %.2f m\n", ...
    std(DEM_test(:),"omitnan"))

fprintf("  Mean abs dZ   : %.2f m\n", ...
    mean(abs(diff(DEM_test,1,1)), ...
    "all","omitnan"))

fprintf("============================================================\n")

end
