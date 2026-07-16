function tiles = find_massif_tiles(TILES, massif)
%FIND_MASSIF_TILES Find IGN DEM tiles intersecting a SAFRAN massif.
%
% INPUT
%   TILES
%       Table returned by build_dem_tile_index().
%
%   massif
%       One polygon from shaperead().
%
% OUTPUT
%   tiles
%       Subset of TILES intersecting the massif bounding box.
%

%% Remove trailing NaN (if present)

x = massif.X;
y = massif.Y;

valid = ~(isnan(x) | isnan(y));

x = x(valid);
y = y(valid);

%% Bounding box

xmin = min(x);
xmax = max(x);

ymin = min(y);
ymax = max(y);

%% Find intersecting tiles

idx = ...
    (TILES.xmax > xmin) & ...
    (TILES.xmin < xmax) & ...
    (TILES.ymax > ymin) & ...
    (TILES.ymin < ymax);

tiles = TILES(idx,:);

%% Sort for reproducibility
% North -> South
% West  -> East

[~,I] = sortrows([-tiles.ymin, tiles.xmin]);

tiles = tiles(I,:);

end
