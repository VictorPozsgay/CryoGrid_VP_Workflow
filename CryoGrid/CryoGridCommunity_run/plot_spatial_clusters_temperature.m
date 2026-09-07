function plot_spatial_clusters_temperature(folder_path,massif_num)

%PLOT_SPATIAL_CLUSTERS_TEMPERATURE
% Plot shallowest ground temperature at the last timestep for each
% CryoGrid cluster within the test area of a SAFRAN massif.
%
%   PLOT_SPATIAL_CLUSTERS_TEMPERATURE(FOLDER_PATH,MASSIF_NUM)
%
%   loads the results of a spatial CryoGrid simulation, extracts the
%   shallowest ground temperature at the last timestep for each cluster,
%   and plots the results over the corresponding DEM.
%
%   Input:
%
%       FOLDER_PATH - Path relative to the CryoGridCommunity_results
%                     directory where the simulation output is stored.
%                     Trailing slashes are optional.
%
%                     Example:
%                         "templates\test_spatial"
%
%       MASSIF_NUM  - Numerical SAFRAN massif number.
%
%                     Example:
%                         5
%
%   Output:
%
%       The figure is saved to:
%
%           CryoGridCommunity_results/FOLDER_PATH/plots/
%
%       with filename:
%
%           massif_XX_clusters_test_area_temperature.png
%
%       where XX is the two-digit SAFRAN massif number.
%
%   Example:
%
%       plot_spatial_clusters_temperature( ...
%           "templates\test_spatial",5);
%
%   See also RUN_SPATIAL, INITIALIZE_CRYOGRID_VP.

% -------------------------------------------------------------------------
% CryoGrid VP workflow
% -------------------------------------------------------------------------

PATHS = initialize_CryoGrid_VP();

CG_FORCING_PATH = PATHS.FORCING.root;
CG_RESULTS_PATH = PATHS.RESULTS.root;

% -------------------------------------------------------------------------
% Prepare output paths
% -------------------------------------------------------------------------

% Remove trailing slashes from the supplied folder path.
folder_path = regexprep(folder_path,'[\\/]+$','');

TARGET_FOLDER = char(fullfile( ...
    CG_RESULTS_PATH, ...
    folder_path));

% Derive result path and run name exactly as in run_spatial.
[result_path,run_name] = fileparts(TARGET_FOLDER);

result_path = char([result_path filesep]);
run_name    = char(run_name);

run_folder = fullfile( ...
    TARGET_FOLDER, ...
    sprintf('massif_%02d',massif_num));

output_folder = fullfile( ...
    TARGET_FOLDER, ...
    "plots");

% -------------------------------------------------------------------------
% Input files
% -------------------------------------------------------------------------

dem_file = fullfile( ...
    CG_FORCING_PATH, ...
    "DEM", ...
    "LiDAR_HD_DEM_10m", ...
    "DEM", ...
    sprintf('DEM_massif_%02d.tif',massif_num));

shapefile_file_box = fullfile( ...
    CG_FORCING_PATH, ...
    "meteo", ...
    "SAFRAN", ...
    "shapefile", ...
    "test_areas_all_massifs.shp");

% -------------------------------------------------------------------------
% Load CryoGrid results
% -------------------------------------------------------------------------

load(fullfile(run_folder,"run_parameters.mat"));

para = run_info.PPROVIDER.CLASSES.OUT_regridded{1,1}.PARA;

if para.relative2surface

    index_depths = int16( ...
        (para.upper_elevation + 0.1) ./ ...
        para.target_grid_size) + 1;

end

% -------------------------------------------------------------------------
% Load DEM
% -------------------------------------------------------------------------

[Z,R] = readgeoraster(dem_file);

step = max(1,ceil(max(size(Z))/1500));

Zp = double(Z(1:step:end,1:step:end));

[X,Y] = worldGrid(R);

X = X(1:step:end,1:step:end);
Y = Y(1:step:end,1:step:end);

% -------------------------------------------------------------------------
% Crop DEM to test area
% -------------------------------------------------------------------------

Sbox = shaperead(shapefile_file_box);

idx = find([Sbox.massif_num] == massif_num);

if isempty(idx)

    error( ...
        'No test area found for massif %02d in %s.', ...
        massif_num, ...
        shapefile_file_box);

end

Sbox = Sbox(idx);

xmin = min(Sbox.X);
xmax = max(Sbox.X);
ymin = min(Sbox.Y);
ymax = max(Sbox.Y);

inside = ...
    X >= xmin & X <= xmax & ...
    Y >= ymin & Y <= ymax;

row = find(any(inside,2));
col = find(any(inside,1));

X_box = X(row,col);
Y_box = Y(row,col);
Z_box = Zp(row,col);

% -------------------------------------------------------------------------
% CryoGrid points
% -------------------------------------------------------------------------

cluster = run_info.CLUSTER.STATVAR.cluster_number;

centroids = ...
    run_info.CLUSTER.STATVAR.sample_centroid_index;

Xc = run_info.SPATIAL.STATVAR.X;
Yc = run_info.SPATIAL.STATVAR.Y;

inside = ...
    Xc >= xmin & Xc <= xmax & ...
    Yc >= ymin & Yc <= ymax;

Xc_box = Xc(inside);
Yc_box = Yc(inside);
cluster_box = cluster(inside);

Nc = numel(centroids);

% -------------------------------------------------------------------------
% Read centroid temperatures
% -------------------------------------------------------------------------

files = dir(fullfile(run_folder,"*.mat"));

T = nan(Nc,1);

for ic = 1:Nc

    key = centroids(ic);

    pattern = sprintf( ...
        "^%s_ground_%d_\\d{8}\\.mat$", ...
        run_name, ...
        key);

    match = files(~cellfun( ...
        'isempty', ...
        regexp({files.name},pattern,'once')));

    if numel(match) ~= 1
        continue
    end

    data = load(fullfile(match.folder,match.name));

    T(ic) = data.CG_ground.T( ...
        index_depths,end);

end

% -------------------------------------------------------------------------
% Check temperature data
% -------------------------------------------------------------------------

if all(isnan(T))

    error( ...
        'No centroid ground temperatures could be read for massif %02d.', ...
        massif_num);

end

% -------------------------------------------------------------------------
% Plot
% -------------------------------------------------------------------------

fig = figure( ...
    'Position',[100 100 1200 500]);

tiledlayout(1,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

% -------------------------------------------------------------------------
% Contour levels
% -------------------------------------------------------------------------

minor_contours = 100:100:4000;
major_contours = 500:500:4000;

% ========================================================================
% DEM
% ========================================================================

ax1 = nexttile;

imagesc( ...
    ax1, ...
    X_box(1,:), ...
    Y_box(:,1), ...
    Z_box);

set(ax1,'YDir','normal')

axis(ax1,'equal')

xlim(ax1,[xmin xmax])
ylim(ax1,[ymin ymax])

colormap(ax1,turbo)

hold(ax1,'on')

plot( ...
    ax1, ...
    Sbox.X, ...
    Sbox.Y, ...
    'k', ...
    'LineWidth',1.5);

contour( ...
    ax1, ...
    X_box, ...
    Y_box, ...
    Z_box, ...
    minor_contours, ...
    'Color',[0.7 0.7 0.7], ...
    'LineWidth',0.25);

[C1,h1] = contour( ...
    ax1, ...
    X_box, ...
    Y_box, ...
    Z_box, ...
    major_contours, ...
    'Color',[0.2 0.2 0.2], ...
    'LineWidth',0.8);

clabel( ...
    C1,h1, ...
    'FontSize',8, ...
    'Color',[0.1 0.1 0.1], ...
    'LabelSpacing',500);

hold(ax1,'off')

cb = colorbar(ax1);

cb.Label.String = 'Elevation (m)';

xlabel(ax1,'Lambert-93 X (m)')
ylabel(ax1,'Lambert-93 Y (m)')

title(ax1, ...
    sprintf('DEM — massif %02d',massif_num));

% ========================================================================
% CryoGrid clusters
% ========================================================================

ax2 = nexttile;

hold(ax2,'on')

% Cluster points
for ic = 1:Nc

    idx = cluster_box == ic;

    scatter( ...
        ax2, ...
        Xc_box(idx), ...
        Yc_box(idx), ...
        4, ...
        T(ic)*ones(sum(idx),1), ...
        'filled', ...
        'MarkerEdgeAlpha',0);

end

% Cluster centroids
for ic = 1:Nc

    scatter( ...
        ax2, ...
        Xc(centroids(ic)), ...
        Yc(centroids(ic)), ...
        70, ...
        T(ic), ...
        'filled', ...
        'MarkerEdgeColor','k', ...
        'LineWidth',1);

end

% Test-area outline
plot( ...
    ax2, ...
    Sbox.X, ...
    Sbox.Y, ...
    'k', ...
    'LineWidth',1.5);

% Minor contours
contour( ...
    ax2, ...
    X_box, ...
    Y_box, ...
    Z_box, ...
    minor_contours, ...
    'Color',[0.7 0.7 0.7], ...
    'LineWidth',0.25);

% Major contours
[C2,h2] = contour( ...
    ax2, ...
    X_box, ...
    Y_box, ...
    Z_box, ...
    major_contours, ...
    'Color',[0.2 0.2 0.2], ...
    'LineWidth',0.8);

clabel( ...
    C2,h2, ...
    'FontSize',8, ...
    'Color',[0.1 0.1 0.1], ...
    'LabelSpacing',500);

hold(ax2,'off')

axis(ax2,'equal')

xlim(ax2,[xmin xmax])
ylim(ax2,[ymin ymax])

colormap(ax2,turbo)

clim(ax2,[min(T) max(T)])

cb = colorbar(ax2);

cb.Label.String = ...
    'Ground temperature (°C)';

xlabel(ax2,'Lambert-93 X (m)')
ylabel(ax2,'Lambert-93 Y (m)')

title(ax2,'CryoGrid clusters')

% -------------------------------------------------------------------------
% Export
% -------------------------------------------------------------------------

if ~isfolder(output_folder)
    mkdir(output_folder)
end

output_file = fullfile( ...
    output_folder, ...
    sprintf( ...
        'massif_%02d_clusters_test_area_temperature.png', ...
        massif_num));

exportgraphics( ...
    fig, ...
    output_file, ...
    'Resolution',200);

close(fig)

end
