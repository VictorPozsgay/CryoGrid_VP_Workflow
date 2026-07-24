source_path = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\CryoGrid\CryoGridCommunity_source";
addpath(genpath(source_path));

%% Paths

dem_folder = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\forcing\Forcing_Data\DEM_10m";
massif_num = 3;

dem_massifs_folder = fullfile(dem_folder,"massifs");
output_folder      = fullfile(dem_folder,"plots");

dem_file           = fullfile(dem_massifs_folder,sprintf('DEM_massif_%02d.tif',massif_num));
shapefile_file_box = fullfile(dem_massifs_folder,sprintf("test_area_massif_%02d.shp",massif_num));

result_path = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\CryoGrid\CryoGridCommunity_results\templates";
run_name    = "test_spatial";
run_folder  = fullfile(result_path,run_name);

%% Load CryoGrid results

load(fullfile(run_folder,"run_parameters.mat"));

para = run_info.PPROVIDER.CLASSES.OUT_regridded{1,1}.PARA;

if para.relative2surface
    idex_depths = int16((para.upper_elevation + 0.1) ./ ...
        para.target_grid_size) + 1;
end

%% Load DEM

Sbox = shaperead(shapefile_file_box);

[Z,R] = readgeoraster(dem_file);

step = max(1,ceil(max(size(Z))/1500));

Zp = double(Z(1:step:end,1:step:end));

[X,Y] = worldGrid(R);

X = X(1:step:end,1:step:end);
Y = Y(1:step:end,1:step:end);

%% Crop DEM to test box

xmin = min(Sbox.X);
xmax = max(Sbox.X);
ymin = min(Sbox.Y);
ymax = max(Sbox.Y);

inside = X>=xmin & X<=xmax & ...
         Y>=ymin & Y<=ymax;

row = find(any(inside,2));
col = find(any(inside,1));

X_box = X(row,col);
Y_box = Y(row,col);
Z_box = Zp(row,col);

%% CryoGrid points

cluster   = run_info.CLUSTER.STATVAR.cluster_number;
centroids = run_info.CLUSTER.STATVAR.sample_centroid_index;

Xc = run_info.SPATIAL.STATVAR.X;
Yc = run_info.SPATIAL.STATVAR.Y;

inside = Xc>=xmin & Xc<=xmax & ...
         Yc>=ymin & Yc<=ymax;

Xc_box       = Xc(inside);
Yc_box       = Yc(inside);
cluster_box  = cluster(inside);

Nc = numel(centroids);

%% Read centroid temperatures

files = dir(fullfile(run_folder,"*.mat"));

T = nan(Nc,1);

for ic = 1:Nc

    key = centroids(ic);

    pattern = sprintf("^%s_ground_%d_\\d{8}\\.mat$", ...
        run_name,key);

    match = files(~cellfun('isempty', ...
        regexp({files.name},pattern,'once')));

    if numel(match) ~= 1
        continue
    end

    data = load(fullfile(match.folder,match.name));

    T(ic) = data.CG_ground.T(idex_depths,end);

end

%% Plot

fig = figure('Position',[100 100 1200 500]);

tiledlayout(1,2,...
    'TileSpacing','compact',...
    'Padding','compact');

%% =====================================================================
% DEM
% ======================================================================

minor_contours = 100:100:4000;
major_contours = 500:500:4000;

ax1 = nexttile;

imagesc(ax1,X_box(1,:),Y_box(:,1),Z_box)
set(ax1,'YDir','normal')

axis(ax1,'equal')
xlim(ax1,[xmin xmax])
ylim(ax1,[ymin ymax])

colormap(ax1,turbo)

hold(ax1,'on')

plot(ax1,...
    Sbox.X,Sbox.Y,...
    'k','LineWidth',1.5)

% Minor contours (100 m)
contour(ax1,...
    X_box,...
    Y_box,...
    Z_box,...
    minor_contours,...
    'Color',[0.7 0.7 0.7],...
    'LineWidth',0.25);

% Major contours (500 m)
[C1,h1] = contour(ax1,...
    X_box,...
    Y_box,...
    Z_box,...
    major_contours,...
    'Color',[0.2 0.2 0.2],...
    'LineWidth',0.8);

clabel(C1,h1,...
    'FontSize',8,...
    'Color',[0.1 0.1 0.1],...
    'LabelSpacing',500);

hold(ax1,'off')

cb = colorbar(ax1);
cb.Label.String = 'Elevation (m)';

xlabel(ax1,'Lambert-93 X (m)')
ylabel(ax1,'Lambert-93 Y (m)')

title(ax1,'DEM')


%% =====================================================================
% CryoGrid clusters
% ======================================================================

ax2 = nexttile;

hold(ax2,'on')

% Cluster points
for ic = 1:Nc

    idx = cluster_box == ic;

    scatter(ax2,...
        Xc_box(idx),...
        Yc_box(idx),...
        4,...
        T(ic)*ones(sum(idx),1),...
        'filled',...
        'MarkerEdgeAlpha',0);

end

% Cluster centroids
for ic = 1:Nc

    scatter(ax2,...
        Xc(centroids(ic)),...
        Yc(centroids(ic)),...
        70,...
        T(ic),...
        'filled',...
        'MarkerEdgeColor','k',...
        'LineWidth',1);

end

% Box outline
plot(ax2,...
    Sbox.X,Sbox.Y,...
    'k','LineWidth',1.5)

% Minor contours (100 m)
contour(ax2,...
    X_box,...
    Y_box,...
    Z_box,...
    minor_contours,...
    'Color',[0.7 0.7 0.7],...
    'LineWidth',0.25);

% Major contours (500 m)
[C2,h2] = contour(ax2,...
    X_box,...
    Y_box,...
    Z_box,...
    major_contours,...
    'Color',[0.2 0.2 0.2],...
    'LineWidth',0.8);

clabel(C2,h2,...
    'FontSize',8,...
    'Color',[0.1 0.1 0.1],...
    'LabelSpacing',500);

hold(ax2,'off')

axis(ax2,'equal')
xlim(ax2,[xmin xmax])
ylim(ax2,[ymin ymax])

colormap(ax2,turbo)
clim(ax2,[min(T) max(T)])

cb = colorbar(ax2);
cb.Label.String = 'Ground temperature (°C)';

xlabel(ax2,'Lambert-93 X (m)')
ylabel(ax2,'Lambert-93 Y (m)')

title(ax2,'CryoGrid clusters')

%% Export

exportgraphics(fig,...
    fullfile(output_folder,...
    sprintf('massif_%02d_clusters_test_area_temperature.png',...
    massif_num)),...
    'Resolution',200)

close(fig)