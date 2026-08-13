function Rchunk = make_chunk_reference( ...
    R,row1,row2,col1,col2)
%MAKE_CHUNK_REFERENCE Create the spatial reference for one SVF chunk.
%
% PURPOSE
%   Constructs a map raster reference corresponding exactly to the pixel
%   extent of one Alpine SVF processing chunk.
%
% INPUTS
%   R             - spatial reference of the full Alpine raster
%   row1,row2     - first and last raster rows of the chunk
%   col1,col2     - first and last raster columns of the chunk
%
% OUTPUT
%   Rchunk        - spatial reference for the chunk raster
%
% GRID CONSISTENCY
%   The chunk reference preserves:
%     - the original pixel dimensions
%     - the original north-up raster orientation
%     - the exact world-coordinate extent of the selected pixels
%     - the projected CRS, when available
%
% WORKFLOW ROLE
%   Used when writing and validating temporary SVF chunk GeoTIFFs.
%   It ensures that each temporary chunk is spatially aligned with the
%   corresponding region of the full Alpine raster.

x1 = R.XWorldLimits(1) + (col1-1)*R.CellExtentInWorldX;
x2 = R.XWorldLimits(1) + col2*R.CellExtentInWorldX;

y2 = R.YWorldLimits(2) - (row1-1)*R.CellExtentInWorldY;
y1 = R.YWorldLimits(2) - row2*R.CellExtentInWorldY;

Rchunk = maprefcells( ...
    [x1 x2], ...
    [y1 y2], ...
    [row2-row1+1,col2-col1+1], ...
    "ColumnsStartFrom","north", ...
    "RowsStartFrom","west");

try
    Rchunk.ProjectedCRS = R.ProjectedCRS;
catch
end

end
