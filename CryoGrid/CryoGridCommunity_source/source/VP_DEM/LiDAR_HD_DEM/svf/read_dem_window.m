function [Z,Rlocal] = read_dem_window(filename,R,r1,r2,c1,c2)

%READ_DEM_WINDOW Read only the requested raster window.
%
% Uses imread PixelRegion rather than readgeoraster or manual TIFF
% tile decoding. This works with the tiled Alpine GeoTIFF and avoids
% loading the full raster into memory.

fprintf("  Reading raster window: %s\n",filename)

% -------------------------------------------------------------------------
% Read only requested pixels
% -------------------------------------------------------------------------

Z = imread(filename, ...
    "PixelRegion", ...
    {[r1 r2],[c1 c2]});

% Preserve floating-point representation
Z = double(Z);

fprintf("  Window read: %d x %d\n", ...
    size(Z,1),size(Z,2))

% -------------------------------------------------------------------------
% Construct spatial reference for cropped raster
% -------------------------------------------------------------------------

x1 = R.XWorldLimits(1) + (c1-1)*R.CellExtentInWorldX;
x2 = R.XWorldLimits(1) + c2*R.CellExtentInWorldX;

y2 = R.YWorldLimits(2) - (r1-1)*R.CellExtentInWorldY;
y1 = R.YWorldLimits(2) - r2*R.CellExtentInWorldY;

Rlocal = maprefcells( ...
    [x1 x2], ...
    [y1 y2], ...
    size(Z), ...
    "ColumnsStartFrom","north", ...
    "RowsStartFrom","west");

try
    Rlocal.ProjectedCRS = R.ProjectedCRS;
catch
end

end
