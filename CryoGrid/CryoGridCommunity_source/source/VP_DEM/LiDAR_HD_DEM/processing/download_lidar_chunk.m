function [Z,R] = download_lidar_chunk( ...
    bbox,...
    resolution,...
    outfile)
%DOWNLOAD_LIDAR_CHUNK Download one IGN LiDAR HD DEM chunk.
%
% Downloads directly to cache.
%
% Includes:
%   - timeout handling
%   - retry mechanism
%   - corrupted download detection


url = make_wms_url(bbox,resolution);


tmpfile = [tempname,'.tif'];


options = weboptions( ...
    "Timeout",120);


success = false;


for attempt = 1:5


    try

        fprintf("  downloading attempt %d\n",attempt)


        if exist(tmpfile,"file")
            delete(tmpfile)
        end


        websave(tmpfile,url,options);


        % Check that file can actually be opened
        [Z,R] = readgeoraster(tmpfile);


        success = true;

        break


    catch ME


        fprintf("  failed: %s\n",ME.message)


        if exist(tmpfile,"file")
            delete(tmpfile)
        end


        pause(5)


    end


end



if ~success

    error("IGN WMS download failed after 5 attempts")

end



%% Save permanent cache copy

copyfile(tmpfile,outfile)

delete(tmpfile)


end