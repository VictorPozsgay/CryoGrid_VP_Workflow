function plot_dem_tiles_safran_massif_shapes(dem_folder, shapefile_folder, plot_folder)

%% Plot IGN DEM tile footprints + SAFRAN massifs

% Tile index
load(fullfile(dem_folder,"tile_index.mat"),"TILES")

% SAFRAN massif shapefile
massif_path = fullfile(shapefile_folder,"massifs_alpes_2154.shp");

MASSIFS = shaperead(massif_path);

fig = figure("Visible","off");
hold on
axis equal
grid on

%% Plot DEM tile footprints

for k = 1:height(TILES)

    rectangle( ...
        "Position", ...
        [ ...
        TILES.xmin(k), ...
        TILES.ymin(k), ...
        TILES.xmax(k)-TILES.xmin(k), ...
        TILES.ymax(k)-TILES.ymin(k)], ...
        "EdgeColor",[0.7 0.7 0.7]);

end


%% Plot SAFRAN massifs

for k = 1:numel(MASSIFS)

    mapshow( ...
        MASSIFS(k), ...
        "FaceColor","none", ...
        "EdgeColor","r", ...
        "LineWidth",1.5);

end


xlabel("Lambert-93 X (m)")
ylabel("Lambert-93 Y (m)")

title("IGN RGE ALTI 5 m tiles and SAFRAN massifs")


%% Optional: label massifs

for k = 1:numel(MASSIFS)

    massif_num  = MASSIFS(k).massif_num;

    % Polygon centroid
    x = mean(MASSIFS(k).X(~isnan(MASSIFS(k).X)));
    y = mean(MASSIFS(k).Y(~isnan(MASSIFS(k).Y)));

    text(x,y,num2str(massif_num), ...
        "HorizontalAlignment","center", ...
        "FontWeight","bold");

end

%% Save figure

out_fig = fullfile(plot_folder,"plot_dem_tiles_safran_massif_shapes.png");

exportgraphics(fig,out_fig,"Resolution",200);

close(fig)

end
