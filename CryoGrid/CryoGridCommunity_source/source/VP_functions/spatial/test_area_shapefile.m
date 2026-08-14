% -------------------------------------------------------------------------
% Create test-area shapefile for all massifs having both:
%   1) an entry in the original massif shapefile
%   2) a corresponding DEM_massif_XX.tif
%
% The output retains the original shapefile attributes, but replaces each
% selected massif geometry with a 5 km x 5 km test polygon centered on DEM.
% -------------------------------------------------------------------------

dem_folder = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\CryoGrid\CryoGridCommunity_forcing\DEM\LiDAR_HD_DEM_10m\DEM";
shp_folder = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\CryoGrid\CryoGridCommunity_forcing\meteo\SAFRAN\shapefile";

shapefile  = fullfile(shp_folder, "massifs_alpes_2154.shp");
output_shp = fullfile(shp_folder, "test_areas_all_massifs.shp");

% Read original massif shapefile
S_original = shaperead(shapefile);

% Keep only massifs for which a DEM exists
has_dem = false(size(S_original));

for i = 1:numel(S_original)

    massif_num = S_original(i).massif_num;

    dem_file = fullfile(dem_folder, ...
        sprintf("DEM_massif_%02d.tif", massif_num));

    has_dem(i) = isfile(dem_file);

    if has_dem(i)
        fprintf("Massif %d: DEM found\n", massif_num);
    else
        fprintf("Massif %d: no DEM -> skipped\n", massif_num);
    end
end

% Copy only the matching original records
S_test = S_original(has_dem);

% Remove geometry-dependent attributes from the original shapefile
S_test = rmfield(S_test, {'BoundingBox','superficie','perimetre'});

% Replace geometry with test polygons
for i = 1:numel(S_test)

    massif_num = S_test(i).massif_num;

    dem_file = fullfile(dem_folder, ...
        sprintf("DEM_massif_%02d.tif", massif_num));

    % Read DEM reference only
    [~, R] = readgeoraster(dem_file);

    % Centre of DEM
    x0 = mean(R.XWorldLimits);
    y0 = mean(R.YWorldLimits);

    % 5 km x 5 km test area
    dx = 2500;
    dy = 2500;

    X = [x0-dx x0+dx x0+dx x0-dx x0-dx];
    Y = [y0-dy y0-dy y0+dy y0+dy y0-dy];

    % Replace geometry
    S_test(i).Geometry = 'Polygon';
    S_test(i).X = X;
    S_test(i).Y = Y;

    fprintf("Massif %d: test area created\n", massif_num);
end

% Write output
shapewrite(S_test, output_shp);

fprintf("\nCreated:\n%s\n", output_shp);
fprintf("Number of test areas: %d\n", numel(S_test));