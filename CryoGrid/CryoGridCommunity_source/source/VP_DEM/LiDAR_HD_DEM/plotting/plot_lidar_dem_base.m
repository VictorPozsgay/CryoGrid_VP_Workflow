function OUT = plot_lidar_dem_base( ...
    dem_folder,...
    safran_shp,...
    dem_bounds)
%PLOT_LIDAR_DEM_BASE Create LiDAR DEM overview figure.
%
% Reads all DEM_massif_XX.tif files, plots them with a common elevation
% scale, overlays SAFRAN massif boundaries, and labels massif numbers.
%
% The figure is created once and returned for additional overlays.
%
% INPUTS
%
% dem_folder
%     Folder containing DEM_massif_XX.tif files
%
% safran_shp
%     SAFRAN massif shapefile (EPSG:2154)
%
%
% OUTPUT
%
% OUT
%     Structure containing:
%       fig
%       ax
%       DEM
%       R
%       files
%       massif_ids
%       global_min
%       global_max


plot_factor = 5;


%% Files

files = dir(fullfile(dem_folder,"DEM_massif_*.tif"));

if isempty(files)
    error("No DEM files found")
end


fprintf("Found %d DEM files\n",numel(files))


%% Read DEMs

DEM = cell(numel(files),1);
R   = cell(numel(files),1);

global_min = inf;
global_max = -inf;

massif_ids = zeros(numel(files),1);


for k = 1:numel(files)


    fprintf("Reading %s\n",files(k).name)


    [Z,R{k}] = readgeoraster( ...
        fullfile(files(k).folder,files(k).name));


    Z = single(Z);

    Z(Z<=-9000)=NaN;


    DEM{k}=Z;


    global_min = min(global_min,...
        min(Z(:),[],'omitnan'));

    global_max = max(global_max,...
        max(Z(:),[],'omitnan'));


    token = regexp( ...
        files(k).name,...
        'DEM_massif_(\d+)',...
        'tokens');


    massif_ids(k)=str2double(token{1}{1});

end



%% Polygons

S = shaperead(safran_shp);

Splot = S(ismember([S.massif_num],massif_ids));


%% Figure

fig = figure( ...
    "Visible","on",...
    "WindowState","minimized");

hold on
axis equal
box on


xmin = inf;
xmax = -inf;
ymin = inf;
ymax = -inf;



%% Plot DEMs

for k = 1:numel(files)


    Z = DEM{k};
    Rk = R{k};


    Zplot = Z( ...
        1:plot_factor:end,...
        1:plot_factor:end);



    Rplot = maprefcells( ...
        Rk.XWorldLimits,...
        Rk.YWorldLimits,...
        size(Zplot),...
        "ColumnsStartFrom","north");



    [x,y] = worldGrid(Rplot);



    h = surface( ...
        x,...
        y,...
        zeros(size(Zplot)),...
        double(Zplot),...
        "EdgeColor","none");


    h.AlphaData = ~isnan(Zplot);
    h.FaceAlpha = "flat";



    xmin=min(xmin,Rk.XWorldLimits(1));
    xmax=max(xmax,Rk.XWorldLimits(2));

    ymin=min(ymin,Rk.YWorldLimits(1));
    ymax=max(ymax,Rk.YWorldLimits(2));

end



%% Color

[cmap,theoretical_clim,label] = ...
    get_topography_colormap("DEM");

colormap(gca,cmap)

if nargin >= 3 && ~isempty(dem_bounds)

    clim(gca,dem_bounds)

else

    clim(gca,theoretical_clim)

end

cb = colorbar;
cb.Label.String = label;



%% Boundaries

for k = 1:numel(Splot)

    mapshow(Splot(k),...
        "FaceColor","none",...
        "EdgeColor","k",...
        "LineWidth",1)

end



%% Labels

for k = 1:numel(Splot)

    x = mean(Splot(k).X(~isnan(Splot(k).X)));
    y = mean(Splot(k).Y(~isnan(Splot(k).Y)));


    text(x,y,...
        string(Splot(k).massif_num),...
        "HorizontalAlignment","center",...
        "FontSize",14,...
        "FontWeight","bold")

end



xlim([xmin xmax])
ylim([ymin ymax])

xlabel("Lambert-93 Easting (m)")
ylabel("Lambert-93 Northing (m)")

title("LiDAR-HD DEMs")



%% Return

OUT.fig = fig;
OUT.ax = gca;

OUT.DEM = DEM;
OUT.R = R;
OUT.files = files;

OUT.massif_ids = massif_ids;

OUT.global_min = global_min;
OUT.global_max = global_max;

end