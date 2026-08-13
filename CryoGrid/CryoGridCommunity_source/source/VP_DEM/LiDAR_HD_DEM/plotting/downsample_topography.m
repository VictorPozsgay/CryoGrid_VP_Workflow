function [Aplot,Rplot] = downsample_topography(A,R,plot_factor)
%DOWNSAMPLE_TOPOGRAPHY Downsample a raster for visualization only.
%
%   [Aplot,Rplot] = downsample_topography(A,R,plot_factor)
%
% The original raster is never modified.
%
% The returned raster reference preserves the original geographic extent
% and orientation while adapting the cell size to the downsampled matrix.

if nargin < 3 || isempty(plot_factor)
    plot_factor = 5;
end

if plot_factor <= 1

    Aplot = A;
    Rplot = R;

    return

end

rows = 1:plot_factor:size(A,1);
cols = 1:plot_factor:size(A,2);

Aplot = A(rows,cols);

Rplot = maprefcells( ...
    R.XWorldLimits, ...
    R.YWorldLimits, ...
    size(Aplot), ...
    "ColumnsStartFrom",R.ColumnsStartFrom, ...
    "RowsStartFrom",R.RowsStartFrom);

end