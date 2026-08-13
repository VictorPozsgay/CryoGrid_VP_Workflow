function [A,R] = read_downsample_geotiff(filename,factor)
%READ_DOWNSAMPLE_GEOTIFF
% Read a GeoTIFF directly at reduced resolution for visualization.
%
%   [A,R] = read_downsample_geotiff(filename,factor)
%
% Only every FACTOR-th pixel is read from disk.
%
% No full-resolution raster is loaded into memory.
%
% NoData values <= -9000 are converted to NaN here and nowhere else in
% the visualization pipeline.
%
% INPUTS
%
%   filename
%       GeoTIFF filename.
%
%   factor
%       Positive integer sampling factor.
%
%       factor = 1  -> full resolution
%       factor = 5  -> every fifth pixel
%
% OUTPUTS
%
%   A
%       Sampled raster.
%
%   R
%       MapCellsReference corresponding to A.

%% ========================================================================
% Validate input
% ========================================================================

if nargin < 2 || isempty(factor)
    factor = 1;
end

if ~isscalar(factor) || ...
        ~isfinite(factor) || ...
        factor < 1 || ...
        factor ~= round(factor)

    error("factor must be a positive integer.")

end

%% ========================================================================
% Read metadata WITHOUT reading the raster
% ========================================================================

info = imfinfo(filename);

nRows = info.Height;
nCols = info.Width;

%% ========================================================================
% Pixel sampling
% ========================================================================

row_start = 1;
row_step  = factor;
row_end   = nRows;

col_start = 1;
col_step  = factor;
col_end   = nCols;

%% ========================================================================
% Read only sampled pixels
% ========================================================================

A = imread( ...
    filename, ...
    "PixelRegion", ...
    { ...
        [row_start row_step row_end], ...
        [col_start col_step col_end] ...
    });

A = single(A);

%% ========================================================================
% Convert NoData exactly once
% ========================================================================

A(A <= -9000) = NaN;

%% ========================================================================
% Read spatial reference WITHOUT reading raster data
% ========================================================================

info_geo = georasterinfo(filename);

R0 = info_geo.RasterReference;

%% ========================================================================
% Construct reference for sampled raster
% ========================================================================
%
% The sampled raster represents the same geographic extent as the source
% raster. The reference is therefore reconstructed using the sampled
% matrix size.

R = maprefcells( ...
    R0.XWorldLimits, ...
    R0.YWorldLimits, ...
    size(A), ...
    "ColumnsStartFrom",R0.ColumnsStartFrom, ...
    "RowsStartFrom",R0.RowsStartFrom);

end