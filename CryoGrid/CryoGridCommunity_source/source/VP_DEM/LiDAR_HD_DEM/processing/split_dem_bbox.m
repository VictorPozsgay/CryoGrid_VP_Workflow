function chunks = split_dem_bbox(...
    xmin,xmax,...
    ymin,ymax,...
    resolution,...
    max_width,...
    max_height)
%SPLIT_DEM_BBOX Split a DEM extent into aligned raster chunks.
%
% The grid convention follows standard GeoTIFF/GDAL practice:
%
%   - Raster cell edges are aligned to multiples of resolution.
%   - Cell centers are offset by resolution/2.
%
% Example for resolution = 10 m:
%
%   Cell edges:
%       ... 973370 973380 973390 ...
%
%   Cell centers:
%       ... 973375 973385 973395 ...
%
%
% INPUTS
%   xmin,xmax,ymin,ymax : requested extent (Lambert-93 meters)
%   resolution          : DEM resolution (m)
%   max_width           : maximum chunk width (pixels)
%   max_height          : maximum chunk height (pixels)
%
%
% OUTPUT
%   chunks : Nx4 matrix
%            [xmin ymin xmax ymax]
%
% Every coordinate in chunks is guaranteed to be:
%
%       coordinate / resolution = integer



%% Align complete requested extent to raster grid

xmin = floor(xmin/resolution)*resolution;
xmax = ceil( xmax/resolution)*resolution;

ymin = floor(ymin/resolution)*resolution;
ymax = ceil( ymax/resolution)*resolution;



%% Number of pixels in complete DEM

nx_total = round((xmax-xmin)/resolution);
ny_total = round((ymax-ymin)/resolution);



%% Number of chunks

nx_chunks = ceil(nx_total/max_width);
ny_chunks = ceil(ny_total/max_height);



chunks = zeros(nx_chunks*ny_chunks,4);

k = 0;



%% Build chunks

for iy = 1:ny_chunks


    row_start = (iy-1)*max_height + 1;

    row_end = min(...
        iy*max_height,...
        ny_total);



    for ix = 1:nx_chunks


        col_start = (ix-1)*max_width + 1;

        col_end = min(...
            ix*max_width,...
            nx_total);



        % Convert cell indices to world edges

        x1 = xmin + (col_start-1)*resolution;

        x2 = xmin + col_end*resolution;


        y1 = ymin + (row_start-1)*resolution;

        y2 = ymin + row_end*resolution;



        k = k+1;

        chunks(k,:) = ...
            [x1 y1 x2 y2];


    end

end



chunks = chunks(1:k,:);



%% Safety checks

if any(mod(chunks(:),resolution) ~= 0)

    error(...
        "Internal error: chunk edges are not aligned to resolution")

end


end