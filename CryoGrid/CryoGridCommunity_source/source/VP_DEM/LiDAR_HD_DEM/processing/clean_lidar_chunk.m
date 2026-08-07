function [Z,no_valid] = clean_lidar_chunk(Z,resolution)
%CLEAN_LIDAR_CHUNK Identify unreliable LiDAR-HD pixels.
%
% Returns a DEM and a mask of pixels that should be considered invalid.
%
% Rules:
%
% 1) All negative elevations are invalid.
%
% 2) For valid pixels touching nodata, if the elevation difference with
%    neighbouring valid pixels exceeds 10*resolution, the pixel is invalid.
%
% Output:
%   Z         cleaned DEM
%   no_valid  logical mask of invalid pixels
%
% Nodata value is -9999.


%% Convert

Z = single(Z);


%% Rule 1: negative elevations

no_valid = Z < 0;

Z(no_valid)= -9999;



%% Rule 2: edge discontinuity


valid = ~no_valid;


% Pixels touching invalid areas

near_invalid = ...
    circshift(no_valid,[ 1 0]) | ...
    circshift(no_valid,[-1 0]) | ...
    circshift(no_valid,[ 0 1]) | ...
    circshift(no_valid,[ 0 -1]) | ...
    circshift(no_valid,[ 1 1]) | ...
    circshift(no_valid,[ 1 -1]) | ...
    circshift(no_valid,[-1 1]) | ...
    circshift(no_valid,[-1 -1]);


edge = valid & near_invalid;



threshold = 10*resolution;


[r,c] = find(edge);


for k = 1:numel(r)

    i = r(k);
    j = c(k);


    r1=max(1,i-1);
    r2=min(size(Z,1),i+1);

    c1=max(1,j-1);
    c2=min(size(Z,2),j+1);


    local = Z(r1:r2,c1:c2);


    neighbours = local(local>0);


    if any(abs(Z(i,j)-neighbours)>threshold)

        no_valid(i,j)=true;

    end

end


Z(no_valid)=-9999;


end