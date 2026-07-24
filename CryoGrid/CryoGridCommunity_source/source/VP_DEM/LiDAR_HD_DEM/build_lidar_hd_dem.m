function build_lidar_hd_dem(safran_shp, dem_folder, varargin)
%BUILD_LIDAR_HD_DEM
%
% Build 10 m DEMs from IGN LiDAR HD MNT WMS service.
%
% One GeoTIFF is produced per SAFRAN massif.
%
% Features:
%   - automatic WMS chunking
%   - persistent download cache
%   - restart after interruption
%   - SAFRAN polygon clipping
%   - Lambert-93 output
%
% INPUTS
%
% safran_shp
%   SAFRAN massif shapefile (EPSG:2154)
%
% output_folder
%   output directory
%
%
% OPTIONS
%
% 'Resolution'
%   DEM resolution in meters
%   default = 10
%
% 'Overwrite'
%   rebuild existing DEMs
%   default = false
%
%
% Example:
%
% build_lidar_hd_dem( ...
%   "massifs_alpes_2154.shp", ...
%   "LiDAR_HD_DEM_10m")
%

cache_folder = fullfile(dem_folder,"cache");

if ~exist(cache_folder,"dir")
    mkdir(cache_folder)
end

%% Options

p = inputParser;

addParameter(p,"Resolution",10)
addParameter(p,"Overwrite",false)

parse(p,varargin{:})

resolution = p.Results.Resolution;
overwrite  = p.Results.Overwrite;


%% Folders

if ~exist(dem_folder,"dir")
    mkdir(dem_folder)
end

cache_folder = fullfile(dem_folder,"cache");

if ~exist(cache_folder,"dir")
    mkdir(cache_folder)
end



%% Read SAFRAN polygons

S = shaperead(safran_shp);


[~,idx] = sort([S.massif_num]);

S = S(idx);


fprintf("\nFound %d SAFRAN massifs\n",numel(S))



%% WMS limits

max_width  = 4000;
max_height = 4000;



%% Loop massifs

for i = 1:numel(S)


    massif = S(i).massif_num;


    outfile = fullfile(...
        dem_folder,...
        sprintf("DEM_massif_%02d.tif",massif));



    if exist(outfile,"file") && ~overwrite

        fprintf("\nSkipping massif %d\n",massif)

        continue

    end



    fprintf("\n============================\n")
    fprintf("Massif %d\n",massif)
    fprintf("============================\n")



    %% Bounding box

    bbox = S(i).BoundingBox;

    xmin = bbox(1,1);
    ymin = bbox(1,2);

    xmax = bbox(2,1);
    ymax = bbox(2,2);



    fprintf("%.1f x %.1f km\n",...
        (xmax-xmin)/1000,...
        (ymax-ymin)/1000)



    %% Split

    chunks = split_dem_bbox(...
        xmin,xmax,...
        ymin,ymax,...
        resolution,...
        max_width,...
        max_height);



    fprintf("Chunks: %d\n",size(chunks,1))



    %% Cache

    massif_cache = fullfile(...
        cache_folder,...
        sprintf("massif_%02d",massif));


    if ~exist(massif_cache,"dir")
        mkdir(massif_cache)
    end



    %% Download chunks

    DEM = [];
    R = [];

    % Logical mask of pixels rejected during quality control
    % Created by merge_dem_chunks at first chunk
    valid_mask = [];


    for c = 1:size(chunks,1)


        fprintf("Chunk %d/%d\n",...
            c,size(chunks,1))


        chunk_file = fullfile(...
            massif_cache,...
            sprintf("chunk_%03d.tif",c));



        if exist(chunk_file,"file")

            fprintf("  using cache\n")

            [Z,Rz] = readgeoraster(chunk_file);


        else


            [Z,Rz] = download_lidar_chunk(...
                chunks(c,:),...
                resolution,...
                chunk_file);


        end

        %% Clean IGN WMS resampling artefacts

        [Z,no_valid] = clean_lidar_chunk(Z,resolution);


        %% Merge into massif DEM

        [DEM,valid_mask,R] = merge_dem_chunks( ...
            DEM,valid_mask,R,...
            Z,no_valid,Rz);

    end

    % figure
    % 
    % mapshow(double(DEM),R,'DisplayType','surface')
    % 
    % colorbar
    % title("Before clipping")

    %% Clip

    [DEM,R,mask] = clip_dem_polygon(...
        DEM,R,S(i));



    %% Save DEM

    write_dem_geotiff(...
        outfile,...
        DEM,...
        R);

    fprintf("Saved %s\n",outfile)
    
    
    %% Save massif mask
    
    maskfile = fullfile(...
        dem_folder,...
        sprintf("DEM_mask_massif_%02d.tif",massif));
    
    
    write_dem_geotiff(...
        maskfile,...
        uint8(mask),...
        R);
    
    

end


fprintf("\nCompleted\n")

end