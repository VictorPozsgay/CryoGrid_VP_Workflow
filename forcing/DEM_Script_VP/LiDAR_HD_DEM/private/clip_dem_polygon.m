function [DEM,R,mask] = clip_dem_polygon(DEM,R,S)
%CLIP_DEM_POLYGON Apply SAFRAN massif mask.
%
% Cells outside the SAFRAN polygon are set to NaN.
%
% Outputs:
%   DEM
%       Clipped DEM.
%
%   R
%       Same spatial reference.
%
%   mask
%       Logical raster:
%           true  = inside SAFRAN massif polygon
%           false = outside polygon
%
% No Image Processing Toolbox required.


%% Raster coordinates

[X,Y] = worldGrid(R);



%% Polygon mask

mask = inpolygon( ...
    X,...
    Y,...
    S.X,...
    S.Y);



%% Apply mask to DEM only

DEM(~mask) = NaN;


end