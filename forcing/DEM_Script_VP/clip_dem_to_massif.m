function [Z,R] = clip_dem_to_massif(Z,R,massif)
%CLIP_DEM_TO_MASSIF Clip DEM raster to SAFRAN massif polygon.
%
% Clips a Lambert-93 DEM mosaic using a SAFRAN massif polygon.
% Pixels outside the polygon are set to NaN.
%
% Uses row-wise polygon testing to avoid allocating large X/Y grids.
%
% INPUT
%   Z
%       DEM elevation matrix.
%
%   R
%       MapCellsReference object.
%
%   massif
%       Polygon structure from shaperead().
%
% OUTPUT
%   Z
%       Clipped DEM.
%
%   R
%       Unchanged raster reference.
%


%% Polygon coordinates

xpoly = massif.X;
ypoly = massif.Y;


% Remove NaNs

valid = ~(isnan(xpoly) | isnan(ypoly));

xpoly = xpoly(valid);
ypoly = ypoly(valid);


%% X coordinates of raster columns

x = R.XWorldLimits(1) + ...
    R.CellExtentInWorldX/2 + ...
    (0:R.RasterSize(2)-1) * R.CellExtentInWorldX;


%% Loop through raster rows

nrows = size(Z,1);

for i = 1:nrows

    % Y coordinate of row i
    y = R.YWorldLimits(2) - ...
        R.CellExtentInWorldY/2 - ...
        (i-1)*R.CellExtentInWorldY;


    inside = inpolygon( ...
        x, ...
        y*ones(size(x)), ...
        xpoly, ...
        ypoly);


    Z(i,~inside) = NaN;

end


end