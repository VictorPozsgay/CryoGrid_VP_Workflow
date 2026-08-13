function [Z,Rlocal] = read_dem_window(filename,R,r1,r2,c1,c2)
%READ_DEM_WINDOW Read a spatial window from an Alpine raster.
%
% PURPOSE
%   Reads only the requested pixel window from a DEM, slope or aspect
%   GeoTIFF and constructs the corresponding local spatial reference.
%
% INPUTS
%   filename      - input raster filename
%   R             - spatial reference of the full raster
%   r1,r2         - first and last raster rows to read
%   c1,c2         - first and last raster columns to read
%
% OUTPUTS
%   Z             - requested raster window as double precision
%   Rlocal        - spatial reference corresponding to the returned
%                   window
%
% METHOD
%   The function uses MATLAB's imread() with PixelRegion so that only the
%   requested raster window is loaded into memory.
%
% WORKFLOW ROLE
%   Used by compute_skyview_factor_alps() to read the DEM, slope and
%   aspect calculation windows required for each target chunk.
%
%   The calculation window may include a ray-tracing buffer around the
%   target chunk. The returned Rlocal therefore describes the complete
%   buffered window, not only the target region.
%
% MEMORY
%   Only the requested raster window is loaded. The full Alpine raster is
%   never read by this function.

fprintf("  Reading raster window: %s\n",filename)

% -------------------------------------------------------------------------
% Read only requested pixels
% -------------------------------------------------------------------------

Z = imread(filename,"PixelRegion",{[r1 r2],[c1 c2]});

% Preserve floating-point representation
Z = double(Z);
fprintf("  Window read: %d x %d\n",size(Z,1),size(Z,2))

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
