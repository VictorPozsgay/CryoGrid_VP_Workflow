function fig = plot_alps_topography(dem_folder,product,save_folder)
%PLOT_ALPS_TOPOGRAPHY Plot merged Alpine topography products.
%
% DESCRIPTION
%   Creates an overview figure of an Alpine topographic product generated
%   from the IGN LiDAR HD workflow.
%
%   The function is product-independent and can plot any continuous Alpine
%   raster product stored using the standard structure:
%
%       PRODUCT/
%           ALPS/
%               PRODUCT_ALPS.tif
%
%   Examples:
%
%       DEM
%       SLOPE
%       ASPECT
%
%   The DEM Alpine mask is always used to display the modelling boundary:
%
%       DEM/
%           ALPS/
%               DEM_ALPS_mask.tif
%
%   The input GeoTIFF resolution is preserved. Downsampling is only applied
%   for visualization.
%
%
% INPUTS
%
%   dem_folder
%       Root LiDAR_HD_DEM_xx folder.
%
%   product
%       Name of the topographic product to plot.
%
%       Examples:
%
%           "DEM"
%           "SLOPE"
%           "ASPECT"
%
%   save_folder
%       Output folder where the diagnostic PNG figure is saved.
%
%
% OUTPUT
%
%   fig
%       MATLAB figure handle.
%
%   Creates:
%
%       LiDAR_HD_<PRODUCT>_ALPS_overview.png
%
%
% NOTES
%
%   The function does not discover products automatically.
%   Product availability is checked from the requested input name.
%
%
% SEE ALSO
%
%   merge_massif_DEMs
%   compute_dem_derivatives
%   run_lidar_diagnostics
%


%% Paths

product_folder = fullfile(dem_folder,product,"ALPS");

product_file = fullfile( ...
    product_folder,...
    sprintf("%s_ALPS.tif",product));

if ~isfile(product_file)
    error("Alpine %s product not found: %s",product,product_file)
end


%% DEM mask

mask_file = fullfile(dem_folder,"DEM","ALPS","DEM_ALPS_mask.tif");
if ~isfile(mask_file)
    error("Alpine DEM mask not found: %s",mask_file)
end

%% Read product

fprintf("Reading Alpine %s\n",product)

[Z,R] = readgeoraster(product_file);
Z = single(Z);
Z(Z<=-9000)=NaN;

%% Downsample for plotting only

plot_factor = 5;
Zplot = Z(1:plot_factor:end,1:plot_factor:end);

Rplot = maprefcells( ...
    R.XWorldLimits,...
    R.YWorldLimits,...
    size(Zplot),...
    "ColumnsStartFrom","north");

[x,y] = worldGrid(Rplot);


%% Figure

fig = figure("Visible","on","WindowState","minimized");

hold on
box on
axis equal tight

surface(x,y,Zplot,"EdgeColor","none")

%% Product-dependent display

switch upper(product)
    case "DEM"
        colormap turbo
        label = "Elevation (m)";
    case "SLOPE"
        colormap parula
        label = "Slope (°)";
    case "ASPECT"
        colormap hsv
        label = "Aspect (°)";
    otherwise
        colormap turbo
        label = product;
end

cb = colorbar;
cb.Label.String = label;

xlabel("Lambert-93 Easting (m)")
ylabel("Lambert-93 Northing (m)")

title(sprintf("IGN LiDAR HD Alpine %s",product))

%% Boundary

fprintf("Reading Alpine DEM mask\n")

M = readgeoraster(mask_file);
Mplot = M(1:plot_factor:end,1:plot_factor:end);
contour(x,y,Mplot,[1 1],"k","LineWidth",1);

%% Save

outfile = fullfile( ...
    save_folder,...
    sprintf("LiDAR_HD_%s_ALPS_overview.png",upper(product)));

fig.Visible = "off";
exportgraphics(fig,outfile,"Resolution",300);
fprintf("Saved %s\n",outfile)

end