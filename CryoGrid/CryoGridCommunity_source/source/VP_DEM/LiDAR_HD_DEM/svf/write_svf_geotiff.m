function write_svf_geotiff(filename,SVF,R)
%WRITE_SVF_GEOTIFF Write an SVF chunk as a georeferenced GeoTIFF.
%
% Writes a temporary SVF chunk using the spatial reference supplied by R.
% The Alpine SVF workflow uses Lambert-93 / EPSG:2154.
%
% Inputs:
%   filename - Output GeoTIFF filename.
%   SVF      - SVF raster values to write.
%   R        - Spatial referencing object for the raster.
%
% The resulting file is used as an intermediate chunk and is subsequently
% validated before being inserted into the final Alpine SVF BigTIFF.

% The Alpine DEM uses Lambert-93 / EPSG:2154.
geotiffwrite( ...
    filename, ...
    SVF, ...
    R, ...
    "CoordRefSysCode",2154);

end
