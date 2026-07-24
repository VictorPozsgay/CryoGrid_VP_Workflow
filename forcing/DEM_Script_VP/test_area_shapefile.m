% Load DEM reference
massif_num = 3;
dem_folder = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\forcing\Forcing_Data\DEM_10m\massifs\";
[~,R] = readgeoraster(fullfile(dem_folder,sprintf("DEM_massif_%02d.tif",massif_num)));

% Choose a small region in projected coordinates
x0 = mean(R.XWorldLimits);
y0 = mean(R.YWorldLimits);

dx = 2500; % 2.5 km
dy = 2500;

X = [x0-dx x0+dx x0+dx x0-dx x0-dx];
Y = [y0-dy y0-dy y0+dy y0+dy y0-dy];

S.Geometry = 'Polygon';
S.X = X;
S.Y = Y;
S.massif_num = massif_num;
S.nom = 'test';

shapewrite(S,fullfile(dem_folder,sprintf('test_area_massif_%02d.shp',massif_num)))