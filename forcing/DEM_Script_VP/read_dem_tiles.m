function [Z,R] = read_dem_tiles(tiles)
%READ_DEM_TILES Read and mosaic IGN RGE ALTI ASCII DEM tiles.
%
% Reads selected IGN RGE ALTI 5 m ASCII tiles and mosaics them into a
% Lambert-93 raster.
%
% INPUT
%   tiles
%       Table returned by find_massif_tiles().
%
% OUTPUT
%   Z
%       DEM elevation matrix (single precision, metres).
%
%   R
%       MapCellsReference object (Lambert-93 EPSG:2154).
%


%% Constants

cellsize = tiles.cellsize(1);


%% Mosaic extent

xmin = min(tiles.xmin);
xmax = max(tiles.xmax);

ymin = min(tiles.ymin);
ymax = max(tiles.ymax);


ncols = round((xmax-xmin)/cellsize);
nrows = round((ymax-ymin)/cellsize);


Z = nan(nrows,ncols,'single');


%% Read and insert tiles

for k = 1:height(tiles)

    fprintf("Reading DEM tile %d/%d\n",k,height(tiles));


    filename = fullfile( ...
        tiles.folder(k), ...
        tiles.filename(k));


    [A,~] = readgeoraster(filename);

    A = single(A);


    % Remove IGN no-data values

    A(A < -9000) = NaN;


    %% Tile position in mosaic
    %
    % Matrix row 1 corresponds to ymax (north)
    %

    col_start = round( ...
        (tiles.xmin(k)-xmin)/cellsize ) + 1;


    row_start = round( ...
        (ymax-tiles.ymax(k))/cellsize ) + 1;


    rows = row_start : row_start + size(A,1)-1;

    cols = col_start : col_start + size(A,2)-1;


    Z(rows,cols) = A;

end

%% Create spatial reference

R = maprefcells( ...
    [xmin xmax], ...
    [ymin ymax], ...
    size(Z));

% The matrix Z is stored north -> south (IGN ASCII convention)
% so the raster reference must start from the north.
R.ColumnsStartFrom = "north";

% CRS
R.ProjectedCRS = projcrs(2154);


end
