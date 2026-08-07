function process_single_massif(Ssingle,result_path,cache_path,max_width,max_height,resolution,overwrite)
%PROCESS_SINGLE_MASSIF Generate one SAFRAN massif DEM from IGN LiDAR HD.
%
% DESCRIPTION
%   Downloads, processes, merges and clips IGN LiDAR HD elevation data
%   for a single SAFRAN massif.
%
%   The processing chain is:
%
%       1. Extract massif bounding box
%       2. Split large requests into WMS-compatible chunks
%       3. Download IGN LiDAR HD tiles
%       4. Reuse cached chunks when available
%       5. Remove invalid WMS resampling artefacts
%       6. Merge chunks into a continuous DEM
%       7. Clip DEM to SAFRAN polygon
%       8. Save DEM and binary massif mask
%
% INPUT
%   Ssingle
%       Single SAFRAN massif structure returned by shaperead().
%       Must contain:
%
%           massif_num
%           nom
%           BoundingBox
%
%   result_path
%       Directory where DEM GeoTIFF products are saved.
%
%   cache_path
%       Directory used for persistent WMS tile caching.
%       Cached chunks allow restarting interrupted processing without
%       redownloading completed requests.
%
%   max_width, max_height
%       Maximum WMS request size in pixels.
%
%       IGN LiDAR HD requests become unreliable for larger images.
%       4000 x 4000 pixels was found to provide the best compromise
%       between efficiency and robustness while keeping some margin.
%
%   resolution
%       DEM resolution in metres.
%
%   overwrite
%       If true, rebuild existing DEM products.
%
% OUTPUT
%   Creates:
%
%       DEM_massif_XX.tif
%           Clipped elevation model.
%
%       DEM_mask_massif_XX.tif
%           Binary mask:
%
%               1 = inside SAFRAN massif
%               0 = outside SAFRAN massif
%

massif = Ssingle.massif_num;
massif_name = Ssingle.nom;

outfile = fullfile(...
    result_path,...
    sprintf("DEM_massif_%02d.tif",massif));

maskfile = fullfile(result_path,...
    sprintf("DEM_mask_massif_%02d.tif",massif));

if exist(outfile,"file") && exist(maskfile,"file") && ~overwrite
    fprintf("\nSkipping massif %d: %s\n",massif,massif_name)
    return
end

fprintf("\n============================\n")
fprintf("Massif %d: %s\n",massif,massif_name)
fprintf("============================\n")


%% Bounding box

bbox = Ssingle.BoundingBox;

xmin = bbox(1,1);
ymin = bbox(1,2);

xmax = bbox(2,1);
ymax = bbox(2,2);

fprintf("%.1f x %.1f km\n",(xmax-xmin)/1000,(ymax-ymin)/1000)

%% Split

chunks = split_dem_bbox(...
    xmin,xmax,ymin,ymax,...
    resolution,max_width,max_height);

fprintf("Chunks: %d\n",size(chunks,1))


%% Cache

massif_cache = fullfile(cache_path,sprintf("massif_%02d",massif));
if ~exist(massif_cache,"dir")
    mkdir(massif_cache)
end


%% Download chunks

DEM = [];
R = [];

% Internal mask tracking invalid pixels during chunk merging
valid_mask = [];

for c = 1:size(chunks,1)
    fprintf("Chunk %d/%d\n",c,size(chunks,1))
    chunk_file = fullfile(massif_cache,sprintf("chunk_%03d.tif",c));

    if exist(chunk_file,"file")
        fprintf("  using cache\n")
        [Z,Rz] = readgeoraster(chunk_file);
    else
        [Z,Rz] = download_lidar_chunk(chunks(c,:),resolution,chunk_file);
    end

    %% Clean IGN WMS resampling artefacts

    [Z,no_valid] = clean_lidar_chunk(Z,resolution);

    %% Merge into massif DEM

    [DEM,valid_mask,R] = merge_dem_chunks( ...
        DEM,valid_mask,R,Z,no_valid,Rz);

end


%% Clip

[DEM,R,mask] = clip_dem_polygon(DEM,R,Ssingle);

%% Save DEM

write_dem_geotiff(outfile,DEM,R);
fprintf("Saved %s\n",outfile)

%% Save massif mask

write_dem_geotiff(maskfile,uint8(mask),R);

end