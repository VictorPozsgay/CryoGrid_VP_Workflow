function url = make_wms_url(bbox,resolution)
%MAKE_WMS_URL Create IGN LiDAR-HD WMS request.
%
% Input bbox:
%   [xmin ymin xmax ymax]
%
% The bbox must already be aligned to the raster grid.


xmin = bbox(1);
ymin = bbox(2);

xmax = bbox(3);
ymax = bbox(4);



%% Pixel dimensions

width = round((xmax-xmin)/resolution);

height = round((ymax-ymin)/resolution);



%% Safety

if mod(xmax-xmin,resolution) ~= 0 || ...
   mod(ymax-ymin,resolution) ~= 0

    error(...
        "WMS bbox dimensions are not divisible by resolution")

end



%% URL

url = sprintf(...
"https://data.geopf.fr/wms-r?" + ...
"SERVICE=WMS&" + ...
"VERSION=1.3.0&" + ...
"REQUEST=GetMap&" + ...
"LAYERS=IGNF_LIDAR-HD_MNT_ELEVATION.ELEVATIONGRIDCOVERAGE.LAMB93&" + ...
"FORMAT=image/geotiff&" + ...
"STYLES=&" + ...
"CRS=EPSG:2154&" + ...
"BBOX=%.0f,%.0f,%.0f,%.0f&" + ...
"WIDTH=%d&HEIGHT=%d",...
xmin,ymin,xmax,ymax,...
width,height);


end