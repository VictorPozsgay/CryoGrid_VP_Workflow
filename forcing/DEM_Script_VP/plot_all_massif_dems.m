function plot_all_massif_dems(dem_folder, shapefile_folder, outfile)
%PLOT_ALL_MASSIF_DEMS Plot all massif DEMs together for quality control.
%
% Downsamples DEMs for plotting.
% Uses fixed elevation colour scale:
% 0-5000 m a.s.l.

%% Files

files = dir(fullfile(dem_folder,"massif","massif_*.mat"));

% Remove raw checkpoint files
files = files(arrayfun(@(x) ...
    isempty(regexp(x.name,"_raw\.mat$","once")), files));

massifs = shaperead(fullfile(shapefile_folder,...
    "massifs_alpes_2154.shp"));


%% Plot settings

factor = 50;   % 5 m -> 250 m

zmin = 0;
zmax = 5000;


%% Figure

fig = figure("Visible","off",...
    "Position",[100 100 1800 1400]);

hold on
axis equal
grid on


%% Plot DEMs

for k = 1:numel(files)
    fprintf("%02d/%02d\n",k,numel(files))
    load(fullfile(files(k).folder,files(k).name),"DEM")
    [Zsmall,Rsmall] = downsample_dem(DEM.Z,DEM.R,factor);

    %% Coordinates of pixel centres (same as plot_dem_preview)

    x = Rsmall.XWorldLimits(1) + ...
        Rsmall.CellExtentInWorldX/2 + ...
        (0:size(Zsmall,2)-1)*Rsmall.CellExtentInWorldX;

    y = Rsmall.YWorldLimits(2) - ...
        Rsmall.CellExtentInWorldY/2 - ...
        (0:size(Zsmall,1)-1)*Rsmall.CellExtentInWorldY;

    %% NaN handling

    nan_mask = isnan(Zsmall);
    Zplot = Zsmall;

    % Replace NaN by a valid elevation
    Zplot(nan_mask) = zmin;


    %% Plot
    h = imagesc(x,y,Zplot);
    set(h,"AlphaData",~nan_mask)
end


%% Formatting

set(gca,"YDir","normal")
axis equal tight

% Fixed elevation scale

demcmap([zmin zmax])
clim([zmin zmax])

% Background for transparent NaNs

ax = gca;
ax.Color = [0.9 0.9 0.9];

%% Overlay SAFRAN massif boundaries

for k = 1:numel(massifs)
    mapshow(massifs(k),...
        "FaceColor","none",...
        "EdgeColor","r",...
        "LineWidth",0.5)
end


%% Labels

xlabel("Lambert-93 Easting (m)")
ylabel("Lambert-93 Northing (m)")

cb = colorbar;
cb.Label.String = "Elevation (m a.s.l.)";

title("All SAFRAN massif DEMs", "Interpreter","none")


%% Save

exportgraphics(fig,outfile,"Resolution",300)
close(fig)

end