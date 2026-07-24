function write_dem_geotiff(filename,DEM,R)
%WRITE_DEM_GEOTIFF Save DEM as Lambert-93 GeoTIFF.
%
% Output:
%   EPSG:2154
%   NaN outside massif stored as -9999


nodata = -9999;


DEMout = DEM;

DEMout(isnan(DEMout)) = nodata;



geotiffwrite(...
    filename,...
    DEMout,...
    R,...
    "CoordRefSysCode",2154);


end