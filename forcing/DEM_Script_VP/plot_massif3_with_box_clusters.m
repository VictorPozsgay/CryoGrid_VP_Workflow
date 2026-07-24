dem_folder = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\forcing\Forcing_Data\DEM_10m";
massif_num = 3;

dem_massifs_folder = fullfile(dem_folder,"massifs");
output_folder = fullfile(dem_folder,"plots");

shapefile_file_box = fullfile(dem_massifs_folder,sprintf("test_area_massif_%02d.shp",massif_num));
dem_file = fullfile(dem_massifs_folder,sprintf('DEM_massif_%02d.tif',massif_num));

Sbox = shaperead(shapefile_file_box);

[Z,R] = readgeoraster(dem_file);
step = max(1,ceil(max(size(Z))/1500));
Zp = double(Z(1:step:end,1:step:end));
[X,Y] = worldGrid(R);
X = X(1:step:end,1:step:end);
Y = Y(1:step:end,1:step:end);


load("D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\CryoGrid\CryoGridCommunity_results\templates\test_spatial\run_parameters.mat");
source_path = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\CryoGrid\CryoGridCommunity_source";
addpath(genpath(source_path));

%% =====================================================================
% Plot DEM and CryoGrid clusters in test box
% ======================================================================

% Box limits
xmin = min(Sbox.X);
xmax = max(Sbox.X);
ymin = min(Sbox.Y);
ymax = max(Sbox.Y);

% Crop DEM to box
inside_dem = X >= xmin & X <= xmax & ...
    Y >= ymin & Y <= ymax;

% indices (rectangular crop)
row = find(any(inside_dem,2));
col = find(any(inside_dem,1));

Z_box = Zp(row,col);
X_box = X(row,col);
Y_box = Y(row,col);


% CryoGrid points inside box
cluster = run_info.CLUSTER.STATVAR.cluster_number;
Xc = run_info.SPATIAL.STATVAR.X;
Yc = run_info.SPATIAL.STATVAR.Y;

inside_cluster = Xc >= xmin & Xc <= xmax & ...
    Yc >= ymin & Yc <= ymax;

Xc_box = Xc(inside_cluster);
Yc_box = Yc(inside_cluster);
cluster_box = cluster(inside_cluster);


% Centroids
centroids = run_info.CLUSTER.STATVAR.sample_centroid_index;

inside_centroid = inside_cluster(centroids);

Xcent = Xc(centroids(inside_centroid));
Ycent = Yc(centroids(inside_centroid));

%% Figure with identical panels

fig = figure('Position',[100 100 1200 500]);

t = tiledlayout(1,2,...
    'TileSpacing','compact',...
    'Padding','compact');


%% ---------------- LEFT: DEM ----------------

ax1 = nexttile;

imagesc(ax1,X_box(1,:),Y_box(:,1),Z_box)
set(ax1,'YDir','normal')

axis(ax1,'equal')
xlim(ax1,[xmin xmax])
ylim(ax1,[ymin ymax])

hold(ax1,'on')

plot(ax1,Sbox.X,Sbox.Y,...
    'k','LineWidth',1.5)

xlabel(ax1,'Lambert-93 X (m)')
ylabel(ax1,'Lambert-93 Y (m)')

title(ax1,'DEM')

colormap(ax1,turbo)
cb = colorbar(ax1);
cb.Label.String = 'Elevation (m)';



%% ---------------- RIGHT: CLUSTERS ----------------

ax2 = nexttile;

hold(ax2,'on')


Nc = max(cluster_box);
colors = lines(Nc);


% cluster points
for ic = 1:Nc

    idxc = cluster_box == ic;

    scatter(ax2,...
        Xc_box(idxc),...
        Yc_box(idxc),...
        2,...                       % SMALL markers
        colors(ic,:),...
        'filled',...
        'MarkerFaceAlpha',1,...
        'MarkerEdgeAlpha',0)

end


% centroids
for ic = 1:Nc

    idxc = cluster == ic;

    % global centroid index
    id_cent = centroids(ic);

    scatter(ax2,...
        Xc(id_cent),...
        Yc(id_cent),...
        80,...
        colors(ic,:),...
        'filled',...
        'MarkerEdgeColor','k',...
        'LineWidth',1.5)

end


plot(ax2,Sbox.X,Sbox.Y,...
    'k',...
    'LineWidth',1.5)


axis(ax2,'equal')
xlim(ax2,[xmin xmax])
ylim(ax2,[ymin ymax])

xlabel(ax2,'Lambert-93 X (m)')
ylabel(ax2,'Lambert-93 Y (m)')

title(ax2,'CryoGrid clusters')


%% Export

exportgraphics(fig,...
    fullfile(output_folder,...
    sprintf('massif_%02d_clusters_test_area.png',massif_num)),...
    'Resolution',200)