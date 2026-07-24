dem_folder = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\forcing\Forcing_Data\DEM_10m";
massif_num = 3;

dem_massifs_folder = fullfile(dem_folder,"massifs");
output_folder = fullfile(dem_folder,"plots");
shapefile_file = fullfile(dem_folder,"shapefile_massifs_SAFRAN\massifs_alpes_2154.shp");
shapefile_file_box = fullfile(dem_massifs_folder,sprintf("test_area_massif_%02d.shp",massif_num));

if ~exist(output_folder,'dir')
    mkdir(output_folder)
end

S = shaperead(shapefile_file);
Sbox = shaperead(shapefile_file_box);

%% =====================================================================
% Individual massif plots
% ======================================================================

dem_file = fullfile(dem_massifs_folder,sprintf('DEM_massif_%02d.tif',massif_num));

idx = find([S.massif_num] == massif_num,1);

[Z,R] = readgeoraster(dem_file);

% Downsample for plotting only
step = max(1,ceil(max(size(Z))/1500));

Zp = double(Z(1:step:end,1:step:end));

[X,Y] = worldGrid(R);

X = X(1:step:end,1:step:end);
Y = Y(1:step:end,1:step:end);

fig = figure('Visible','off');

surf(X,Y,Zp,...
    'EdgeColor','none');

view(2)
axis equal tight

colormap(turbo)
cb = colorbar;
cb.Label.String = 'Elevation (m)';

hold on

plot3(S(idx).X,...
      S(idx).Y,...
      max(Zp(:),[],'omitnan')*ones(size(S(idx).X)),...
      'k','LineWidth',1.5)

hold off

hold on

plot3(Sbox.X,Sbox.Y,...
    max(Zp(:),[],'omitnan')*ones(size(Sbox.X)),...
    'k','LineWidth',1.5)

hold off

xlabel('Lambert-93 X (m)')
ylabel('Lambert-93 Y (m)')

title(sprintf('SAFRAN Massif %d - %s',...
    massif_num,...
    string(S(idx).nom)))

exportgraphics(fig,...
    fullfile(output_folder,...
    sprintf('DEM_massif_%02d_with_box.png',massif_num)),...
    'Resolution',200)

close(fig)

