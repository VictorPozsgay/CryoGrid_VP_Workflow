function compare_svf_test_window(base_path)
%COMPARE_SVF_TEST_WINDOW Compare DEM, terrain derivatives and SVF methods.
%
% Displays the same test window for:
%   1. DEM
%   2. Slope
%   3. Aspect
%   4. Naive CryoGrid SVF = cos(slope/2)^2
%   5. Ray-traced SVF, 1 km horizon
%   6. Ray-traced SVF, 5 km horizon
%
% Example:
%
%   base_path = ...
%       "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\CryoGrid\CryoGridCommunity_forcing\DEM\LiDAR_HD_DEM_10m";
%
%   compare_svf_test_window(base_path);

%% ------------------------------------------------------------------------
% Paths
% -------------------------------------------------------------------------

dem_file = fullfile(base_path, ...
    "DEM","ALPS","DEM_ALPS.tif");

slope_file = fullfile(base_path, ...
    "SLOPE","ALPS","SLOPE_ALPS.tif");

aspect_file = fullfile(base_path, ...
    "ASPECT","ALPS","ASPECT_ALPS.tif");

svf_1km_file = fullfile(base_path, ...
    "SVF","SVF_massif_12_1km.tif");

svf_5km_file = fullfile(base_path, ...
    "SVF","SVF_massif_12_5km.tif");

%% ------------------------------------------------------------------------
% Read rasters
% -------------------------------------------------------------------------

fprintf("Reading DEM...\n");
[DEM,Rdem] = readgeoraster(dem_file,"OutputType","double");

fprintf("Reading slope...\n");
[SLOPE,Rslope] = readgeoraster(slope_file,"OutputType","double");

fprintf("Reading aspect...\n");
[ASPECT,Raspect] = readgeoraster(aspect_file,"OutputType","double");

fprintf("Reading 1 km SVF...\n");
[SVF1,R1] = readgeoraster(svf_1km_file,"OutputType","double");

fprintf("Reading 5 km SVF...\n");
[SVF5,R5] = readgeoraster(svf_5km_file,"OutputType","double");

%% ------------------------------------------------------------------------
% Check raster grids
% -------------------------------------------------------------------------

assert(isequal(size(SVF1),size(SVF5)), ...
    "1 km and 5 km SVF rasters have different sizes.");

assert(abs(R1.CellExtentInWorldX - R5.CellExtentInWorldX) < 1e-6 && ...
       abs(R1.CellExtentInWorldY - R5.CellExtentInWorldY) < 1e-6, ...
    "SVF resolutions differ.");

assert(isequal(size(DEM),size(SLOPE)) && ...
       isequal(size(DEM),size(ASPECT)), ...
    "DEM, slope and aspect raster sizes differ.");

%% ------------------------------------------------------------------------
% Find common valid SVF test window
% -------------------------------------------------------------------------

valid = isfinite(SVF1) & isfinite(SVF5);

[row,col] = find(valid);

assert(~isempty(row), ...
    "No common valid SVF pixels found.");

rmin = min(row);
rmax = max(row);
cmin = min(col);
cmax = max(col);

SVF1_test = SVF1(rmin:rmax,cmin:cmax);
SVF5_test = SVF5(rmin:rmax,cmin:cmax);

%% ------------------------------------------------------------------------
% Geographic extent of the SVF test window
% -------------------------------------------------------------------------

x_sv = R1.XWorldLimits(1) + ...
       (0:size(SVF1,2)-1)*R1.CellExtentInWorldX + ...
       R1.CellExtentInWorldX/2;

y_sv = R1.YWorldLimits(2) - ...
       (0:size(SVF1,1)-1)*R1.CellExtentInWorldY - ...
       R1.CellExtentInWorldY/2;

xmin = min(x_sv(cmin),x_sv(cmax));
xmax = max(x_sv(cmin),x_sv(cmax));

ymin = min(y_sv(rmin),y_sv(rmax));
ymax = max(y_sv(rmin),y_sv(rmax));

%% ------------------------------------------------------------------------
% Extract corresponding DEM / slope / aspect window
% -------------------------------------------------------------------------

x_dem = Rdem.XWorldLimits(1) + ...
        (0:size(DEM,2)-1)*Rdem.CellExtentInWorldX + ...
        Rdem.CellExtentInWorldX/2;

y_dem = Rdem.YWorldLimits(2) - ...
        (0:size(DEM,1)-1)*Rdem.CellExtentInWorldY - ...
        Rdem.CellExtentInWorldY/2;

dem_cols = find(x_dem >= xmin & x_dem <= xmax);
dem_rows = find(y_dem >= ymin & y_dem <= ymax);

assert(~isempty(dem_rows) && ~isempty(dem_cols), ...
    "Could not find corresponding DEM window.");

DEM_test    = DEM(dem_rows,dem_cols);
SLOPE_test  = SLOPE(dem_rows,dem_cols);
ASPECT_test = ASPECT(dem_rows,dem_cols);

%% ------------------------------------------------------------------------
% Naive CryoGrid SVF
%
% CryoGrid baseline:
%
%       SVF = cos(slope/2)^2
%
% Slope is assumed to be in degrees.
% -------------------------------------------------------------------------

SVF_naive = cosd(SLOPE_test/2).^2;

%% ------------------------------------------------------------------------
% Mask NoData
% -------------------------------------------------------------------------

valid_dem = isfinite(DEM_test) & DEM_test > 0;

DEM_plot = DEM_test;
DEM_plot(~valid_dem) = NaN;

SLOPE_plot = SLOPE_test;
SLOPE_plot(~valid_dem) = NaN;

ASPECT_plot = ASPECT_test;
ASPECT_plot(~valid_dem) = NaN;

SVF_naive(~valid_dem) = NaN;
SVF1_test(~valid_dem) = NaN;
SVF5_test(~valid_dem) = NaN;

%% ------------------------------------------------------------------------
% Difference statistics
% -------------------------------------------------------------------------

valid_compare = isfinite(SVF1_test) & ...
                isfinite(SVF5_test);

D_1km_5km = SVF1_test - SVF5_test;

d = D_1km_5km(valid_compare);

fprintf("\n");
fprintf("========================================\n");
fprintf("SVF comparison: 1 km vs 5 km\n");
fprintf("========================================\n");

fprintf("Test window      : %d x %d pixels\n", ...
    size(SVF1_test,1),size(SVF1_test,2));

fprintf("Valid pixels     : %d\n",numel(d));

fprintf("Mean difference  : %.6f\n",mean(d));
fprintf("Median difference: %.6f\n",median(d));
fprintf("Mean |difference|: %.6f\n",mean(abs(d)));
fprintf("Max |difference| : %.6f\n",max(abs(d)));

fprintf("95th percentile  : %.6f\n", ...
    prctile(abs(d),95));

fprintf("99th percentile  : %.6f\n", ...
    prctile(abs(d),99));

fprintf("|difference| > .01 : %.2f %%\n", ...
    100*mean(abs(d)>0.01));

fprintf("|difference| > .02 : %.2f %%\n", ...
    100*mean(abs(d)>0.02));

fprintf("|difference| > .05 : %.2f %%\n", ...
    100*mean(abs(d)>0.05));

fprintf("========================================\n");

%% ------------------------------------------------------------------------
% Difference relative to naive CryoGrid SVF
% -------------------------------------------------------------------------

valid_naive = isfinite(SVF_naive) & ...
              isfinite(SVF1_test);

D_1km_naive = SVF1_test - SVF_naive;

d_naive = D_1km_naive(valid_naive);

fprintf("\n");
fprintf("========================================\n");
fprintf("SVF comparison: 1 km ray tracing vs naive\n");
fprintf("========================================\n");

fprintf("Mean difference  : %.6f\n",mean(d_naive));
fprintf("Median difference: %.6f\n",median(d_naive));
fprintf("Mean |difference|: %.6f\n",mean(abs(d_naive)));
fprintf("Max |difference| : %.6f\n",max(abs(d_naive)));

fprintf("95th percentile  : %.6f\n", ...
    prctile(abs(d_naive),95));

fprintf("99th percentile  : %.6f\n", ...
    prctile(abs(d_naive),99));

fprintf("========================================\n");

%% ------------------------------------------------------------------------
% Plot
% -------------------------------------------------------------------------

figure("Name","SVF test-window comparison");

tiledlayout(2,4, ...
    "TileSpacing","compact", ...
    "Padding","compact");

%% DEM

nexttile;

imagesc(DEM_plot);
axis image;
colorbar;

title("DEM");
xlabel("Column");
ylabel("Row");

%% Slope

nexttile;

imagesc(SLOPE_plot);
axis image;
colorbar;

title("Slope (deg)");
xlabel("Column");
ylabel("Row");

%% Aspect

nexttile;

imagesc(ASPECT_plot);
axis image;
colorbar;

title("Aspect (deg)");
xlabel("Column");
ylabel("Row");

%% Naive SVF

nexttile;

imagesc(SVF_naive);
axis image;
colorbar;
clim([0 1]);

title("Naive SVF: cos^2(slope/2)");
xlabel("Column");
ylabel("Row");

%% 1 km SVF

nexttile;

imagesc(SVF1_test);
axis image;
colorbar;
clim([0 1]);

title("Ray-traced SVF — 1 km");
xlabel("Column");
ylabel("Row");

%% 5 km SVF

nexttile;

imagesc(SVF5_test);
axis image;
colorbar;
clim([0 1]);

title("Ray-traced SVF — 5 km");
xlabel("Column");
ylabel("Row");

%% 1 km - 5 km difference

nexttile;

D_1km_5km = SVF1_test - SVF5_test;

% Robust symmetric colour scale using the 99th percentile
scale = prctile(abs(D_1km_5km(:)),99,"all");

imagesc(D_1km_5km);
axis image;
colorbar;
clim([-scale scale]);

title("SVF difference: 1 km - 5 km");
xlabel("Column");
ylabel("Row");

end