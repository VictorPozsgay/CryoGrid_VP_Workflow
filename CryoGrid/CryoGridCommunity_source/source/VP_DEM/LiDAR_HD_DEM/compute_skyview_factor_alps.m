function compute_skyview_factor_alps(output_path,varargin)
%COMPUTE_SKYVIEW_FACTOR_ALPS
% Restartable full-Alps terrain-based sky-view factor calculation.
%
% DESCRIPTION
%   Computes a terrain-based sky-view factor (SVF) over the complete
%   Alpine DEM using horizon ray tracing.
%
%   The full Alpine DEM is processed in regular target chunks. Each target
%   chunk is surrounded by a calculation buffer corresponding to
%   MaxDistance, so that terrain outside the target chunk contributes to
%   the horizon calculation.
%
%   The final Alpine SVF product follows the standard LiDAR HD product
%   directory convention:
%
%       SVF/
%       └── ALPS/
%           ├── SVF_ALPS.tif
%           └── SVF_ALPS_index.mat
%
%   SVF_ALPS.tif is a tiled BigTIFF. Each completed calculation chunk is
%   written directly into its corresponding TIFF tile after validation.
%
%   Restartability is controlled by the chunk index:
%
%       SVF/ALPS/SVF_ALPS_index.mat
%
%   A chunk is marked DONE only after its temporary GeoTIFF has been
%   validated, inserted into the final BigTIFF, and verified.
%
%   Temporary chunk GeoTIFFs are deleted after successful insertion.
%
% DEFAULT PARAMETERS
%
%   NumBins       = 36
%   MaxDistance   = 1000 m
%   ChunkSize     = 1024 pixels
%   UseParallel   = true
%   Overwrite     = false
%   TestChunk     = 0
%
%   TestChunk can be used to process a single chunk while preserving the
%   same restart/index logic as the full-Alps calculation.
%
% NODATA
%
%   DEM/SLOPE/ASPECT NoData = -9999
%   SVF NoData              = -9999
%
% INPUT
%
%   output_path
%       Root LiDAR HD DEM product folder.
%
%       Expected input products:
%
%           DEM/ALPS/DEM_ALPS.tif
%           SLOPE/ALPS/SLOPE_ALPS.tif
%           ASPECT/ALPS/ASPECT_ALPS.tif
%
%       The SVF product is written to:
%
%           SVF/ALPS/SVF_ALPS.tif
%
%   varargin
%       Optional name-value parameters listed above.
%
% OUTPUT
%
%   No MATLAB output is returned.
%
%   The function creates or updates:
%
%       SVF/ALPS/SVF_ALPS.tif
%       SVF/ALPS/SVF_ALPS_index.mat
%
% SEE ALSO
%
%   compute_svf_target_window
%   compute_svf_target_chunk
%   compute_target_horizon
%   create_svf_alps_geotiff
%   initialize_svf_index
%   read_dem_window
%   validate_svf_chunk
%   verify_svf_tile
%   write_svf_geotiff
%   write_svf_tile
%

addpath(genpath(fileparts(mfilename('fullpath'))));

%% =========================================================================
% Options
% =========================================================================

p = inputParser;

addParameter(p,"NumBins",36)
addParameter(p,"MaxDistance",1000)
addParameter(p,"ChunkSize",1024)
addParameter(p,"UseParallel",true)
addParameter(p,"Overwrite",false)
addParameter(p,"TestChunk",0)

parse(p,varargin{:})

nBins        = p.Results.NumBins;
max_distance = p.Results.MaxDistance;
chunk_size   = p.Results.ChunkSize;
use_parallel = p.Results.UseParallel;
overwrite    = p.Results.Overwrite;
test_chunk   = p.Results.TestChunk;

nodata = -9999;

%% =========================================================================
% Validate inputs
% =========================================================================

if ~isfolder(output_path)
    error("Output directory not found: %s",output_path)
end

dem_file = fullfile(output_path,"DEM","ALPS","DEM_ALPS.tif");
slope_file = fullfile(output_path,"SLOPE","ALPS","SLOPE_ALPS.tif");
aspect_file = fullfile(output_path,"ASPECT","ALPS","ASPECT_ALPS.tif");

if ~isfile(dem_file)
    error("Alpine DEM not found:\n%s",dem_file)
end

if ~isfile(slope_file)
    error("Alpine slope not found:\n%s",slope_file)
end

if ~isfile(aspect_file)
    error("Alpine aspect not found:\n%s",aspect_file)
end

if ~isscalar(nBins) || ...
   ~isfinite(nBins) || ...
   nBins < 4 || ...
   nBins ~= round(nBins)
    error("NumBins must be an integer >= 4.")
end

if ~isscalar(max_distance) || ...
   ~isfinite(max_distance) || ...
   max_distance <= 0
    error("MaxDistance must be a positive finite scalar.")
end

if ~isscalar(chunk_size) || ...
   ~isfinite(chunk_size) || ...
   chunk_size < 16 || ...
   chunk_size ~= round(chunk_size)
    error("ChunkSize must be an integer >= 16.")
end

%% =========================================================================
% Read DEM metadata
% =========================================================================

fprintf("\n")
fprintf("============================================================\n")
fprintf("FULL-ALPS SVF RAY TRACING\n")
fprintf("============================================================\n")

fprintf("Reading Alpine DEM metadata:\n")
fprintf("  %s\n",dem_file)

info = georasterinfo(dem_file);
R    = info.RasterReference;

raster_size = info.RasterSize;

nRows = raster_size(1);
nCols = raster_size(2);

dx = abs(R.CellExtentInWorldX);
dy = abs(R.CellExtentInWorldY);

buffer_pixels_x = ceil(max_distance/dx);
buffer_pixels_y = ceil(max_distance/dy);

fprintf("\n")
fprintf("DEM size          : %d x %d pixels\n",nRows,nCols)
fprintf("Resolution        : %.3f x %.3f m\n",dx,dy)
fprintf("Azimuth bins      : %d\n",nBins)
fprintf("Azimuth spacing   : %.3f degrees\n",360/nBins)
fprintf("Maximum distance  : %.1f m\n",max_distance)
fprintf("Ray buffer        : %d x %d pixels\n", ...
    buffer_pixels_y,buffer_pixels_x)
fprintf("Target chunk      : %d x %d pixels\n", ...
    chunk_size,chunk_size)
fprintf("NoData            : %d\n",nodata)

%% =========================================================================
% Output directory
% =========================================================================

svf_path = fullfile(output_path,"SVF","ALPS");

if ~isfolder(svf_path)
    mkdir(svf_path)
end

final_file = fullfile(svf_path,"SVF_ALPS.tif");
index_file = fullfile(svf_path,"SVF_ALPS_index.mat");

%% =========================================================================
% Determine chunk grid
% =========================================================================

nChunkRows = ceil(nRows/chunk_size);
nChunkCols = ceil(nCols/chunk_size);

nChunks = nChunkRows*nChunkCols;

if ~isscalar(test_chunk) || ...
   ~isfinite(test_chunk) || ...
   test_chunk ~= round(test_chunk) || ...
   test_chunk < 0 || ...
   test_chunk > nChunks

    error( ...
        "TestChunk must be 0 or an integer between 1 and %d.", ...
        nChunks)
end

fprintf("\n")
fprintf("Chunk grid:\n")
fprintf("  %d rows x %d columns\n",nChunkRows,nChunkCols)
fprintf("  Total chunks: %d\n",nChunks)

%% =========================================================================
% Initialize or load index
% =========================================================================

if overwrite && test_chunk > 0
    error( ...
        "Overwrite=true cannot be used together with TestChunk. " + ...
        "Use Overwrite=false for chunk testing.")
end

if overwrite

    if isfile(index_file)
        delete(index_file)
    end

    if isfile(final_file)
        delete(final_file)
    end

end

if isfile(index_file)
    fprintf("\nLoading existing SVF chunk index...\n")
    load(index_file,"index")
    if ~isfield(index,"nRows") || ...
       index.nRows ~= nRows || ...
       index.nCols ~= nCols || ...
       index.chunk_size ~= chunk_size || ...
       abs(index.max_distance-max_distance) > 1e-9 || ...
       index.nBins ~= nBins
        error([ ...
            "Existing SVF index is incompatible with the current " ...
            "calculation settings. Use Overwrite=true to start again."])
    end
else
    fprintf("\nCreating SVF chunk index...\n")
    index = initialize_svf_index( ...
        nRows,nCols,chunk_size, ...
        nBins,max_distance);
    save(index_file,"index","-v7.3")
end

%% =========================================================================
% Initialize final BigTIFF
% =========================================================================

if ~isfile(final_file)
    fprintf("\nCreating final Alpine SVF BigTIFF...\n")
    create_svf_alps_geotiff( ...
        final_file, ...
        nRows,nCols, ...
        R, ...
        nodata, ...
        chunk_size);
    fprintf("Final SVF raster created.\n")
else
    fprintf("\nExisting final SVF raster found.\n")
end

%% =========================================================================
% Determine current progress
% =========================================================================

status = [index.chunk.status];
nDone  = sum(status == "DONE");

fprintf("\n")
fprintf("============================================================\n")
fprintf("SVF ALPS PROGRESS\n")
fprintf("============================================================\n")
fprintf("Chunks DONE      : %d / %d\n",nDone,nChunks)
fprintf("Chunks remaining : %d\n",nChunks-nDone)
fprintf("============================================================\n")

if nDone == nChunks
    fprintf("\nAll Alpine SVF chunks are already DONE.\n")
    fprintf("Final product:\n  %s\n",final_file)
    return
end

%% =========================================================================
% TestChunk restart check
% =========================================================================

if test_chunk > 0 && strcmp(index.chunk(test_chunk).status,"DONE")
    fprintf("Chunk %d is already DONE. Skipping.\n",test_chunk)
    fprintf("\n")
    fprintf("============================================================\n")
    fprintf("FULL-ALPS SVF COMPLETE\n")
    fprintf("============================================================\n")
    fprintf("Chunks DONE: %d / %d\n",nDone,nChunks)
    fprintf("Output:\n  %s\n",final_file)
    fprintf("============================================================\n")
    return
end

%% =========================================================================
% Parallel pool
% =========================================================================

parallel_enabled = false;
pool_created = false;

%% =========================================================================
% Azimuths
% =========================================================================

azimuths = (0:nBins-1) * 360/nBins;

%% =========================================================================
% Main chunk loop
% =========================================================================
%
% IMPORTANT:
% We deliberately process chunks serially at this outer level.
% Each chunk itself uses the validated ray-tracing parallelization.
% This guarantees:
%   one chunk -> one temporary file -> one final tile -> DONE
% and therefore keeps restartability completely deterministic.
%
% =========================================================================

for ichunk = 1:nChunks
    % Test mode: consider only the requested chunk.
    if test_chunk > 0 && ichunk ~= test_chunk
        continue
    end
    % Always respect the restart index.
    % This applies both in normal mode and TestChunk mode.
    if strcmp(index.chunk(ichunk).status,"DONE")
        fprintf("Chunk %d is already DONE. Skipping.\n",ichunk)
        continue
    end
    row1 = index.chunk(ichunk).row1;
    row2 = index.chunk(ichunk).row2;
    col1 = index.chunk(ichunk).col1;
    col2 = index.chunk(ichunk).col2;

    fprintf("\n")
    fprintf( ...
        "SVF Alps: %d/%d DONE | processing chunk %d\n", ...
        nDone, ...
        nChunks, ...
        ichunk)

    fprintf("  Target rows %d:%d, cols %d:%d\n",row1,row2,col1,col2)

    %% ---------------------------------------------------------------------
    % Determine buffered calculation window
    % ----------------------------------------------------------------------

    calc_row1 = max(1,row1-buffer_pixels_y);
    calc_row2 = min(nRows,row2+buffer_pixels_y);

    calc_col1 = max(1,col1-buffer_pixels_x);
    calc_col2 = min(nCols,col2+buffer_pixels_x);

    fprintf( ...
        "  Calculation window: rows %d:%d, cols %d:%d\n", ...
        calc_row1,calc_row2,calc_col1,calc_col2)

    %% ---------------------------------------------------------------------
    % Read DEM / slope / aspect
    % ----------------------------------------------------------------------

    [Z,~] = read_dem_window( ...
        dem_file,R, ...
        calc_row1,calc_row2, ...
        calc_col1,calc_col2);

    [SLOPE,~] = read_dem_window( ...
        slope_file,R, ...
        calc_row1,calc_row2, ...
        calc_col1,calc_col2);

    [ASPECT,~] = read_dem_window( ...
        aspect_file,R, ...
        calc_row1,calc_row2, ...
        calc_col1,calc_col2);

    %% ---------------------------------------------------------------------
    % Convert NoData to NaN internally
    % ----------------------------------------------------------------------

    Z(Z <= -9000) = NaN;
    SLOPE(SLOPE <= -9000) = NaN;
    ASPECT(ASPECT <= -9000) = NaN;

    %% ---------------------------------------------------------------------
    % Target region inside local calculation window
    % ----------------------------------------------------------------------

    target_local_row1 = row1-calc_row1+1;
    target_local_row2 = row2-calc_row1+1;

    target_local_col1 = col1-calc_col1+1;
    target_local_col2 = col2-calc_col1+1;

    target_mask = false(size(Z));

    target_mask( ...
        target_local_row1:target_local_row2, ...
        target_local_col1:target_local_col2) = true;

    % Only DEM pixels with valid elevation are actual targets.
    target_mask = target_mask & isfinite(Z);

    nTarget = nnz(target_mask);

    fprintf("  Valid target pixels: %d\n",nTarget)

    %% ---------------------------------------------------------------------
    % Empty chunk
    % ----------------------------------------------------------------------

    if nTarget == 0
        fprintf("  No valid DEM pixels. Marking chunk DONE.\n")

        % The corresponding final TIFF tile remains entirely -9999.
        index.chunk(ichunk).status = "DONE";
        index.chunk(ichunk).valid_pixels = 0;
        index.chunk(ichunk).timestamp = datetime("now");

        save_index(index,index_file)
        nDone = nDone + 1;

        continue
    end

    %% ---------------------------------------------------------------------
    % Start parallel pool only when actual computation is required
    % ---------------------------------------------------------------------

    if use_parallel && ~parallel_enabled
        try
            pool = gcp("nocreate");
            if isempty(pool)
                fprintf( ...
                    "Starting parallel pool (parpool) using the 'Processes' profile ...\n")
                pool = parpool("Processes");
                pool_created = true;
            end
            parallel_enabled = pool.NumWorkers > 1;
            fprintf("Parallel workers: %d\n",pool.NumWorkers)
        catch ME
            warning( ...
                "Could not start parallel pool. Using serial computation.\n%s", ...
                ME.message)
            parallel_enabled = false;
        end
    end

    %% ---------------------------------------------------------------------
    % Compute SVF for target pixels
    % ----------------------------------------------------------------------

    tic

    SVF_local = compute_svf_target_window( ...
        Z, ...
        target_mask, ...
        SLOPE, ...
        ASPECT, ...
        dx, ...
        dy, ...
        azimuths, ...
        max_distance, ...
        parallel_enabled);

    elapsed = toc;

    fprintf("  Ray tracing: %.2f min\n",elapsed/60)

    %% ---------------------------------------------------------------------
    % Extract target chunk
    % ----------------------------------------------------------------------

    SVF_chunk = ...
        SVF_local( ...
            target_local_row1:target_local_row2, ...
            target_local_col1:target_local_col2);

    % Convert internal NaN representation to final NoData.
    SVF_chunk(~isfinite(SVF_chunk)) = nodata;

    % Enforce physical range while preserving NoData.
    valid = SVF_chunk ~= nodata;
    SVF_chunk(valid & SVF_chunk < 0) = 0;
    SVF_chunk(valid & SVF_chunk > 1) = 1;

    %% ---------------------------------------------------------------------
    % Temporary chunk GeoTIFF
    % ----------------------------------------------------------------------

    temp_file = fullfile(svf_path,sprintf("SVF_chunk_%04d.tif",ichunk));

    % If a previous interrupted run left a temporary file, remove it.
    if isfile(temp_file)
        delete(temp_file)
    end

    % Construct exact target-grid reference.
    Rchunk = make_chunk_reference(R,row1,row2,col1,col2);
    fprintf("  Writing temporary chunk...\n")
    write_svf_geotiff(temp_file,single(SVF_chunk),Rchunk);

    %% ---------------------------------------------------------------------
    % Validate temporary chunk
    % ----------------------------------------------------------------------

    validate_svf_chunk(temp_file,SVF_chunk,Rchunk,nodata);

    %% ---------------------------------------------------------------------
    % Insert into final Alpine BigTIFF
    % ----------------------------------------------------------------------

    fprintf("  Writing final Alpine tile...\n")
    write_svf_tile(final_file,ichunk,single(SVF_chunk),chunk_size);

    %% ---------------------------------------------------------------------
    % Verify final tile
    % ----------------------------------------------------------------------

    verify_svf_tile(final_file,ichunk,single(SVF_chunk),chunk_size);

    %% ---------------------------------------------------------------------
    % Mark chunk DONE only after everything succeeded
    % ----------------------------------------------------------------------

    index.chunk(ichunk).status = "DONE";
    index.chunk(ichunk).valid_pixels = nTarget;
    index.chunk(ichunk).timestamp = datetime("now");

    save_index(index,index_file)
    nDone = nDone + 1;

    %% ---------------------------------------------------------------------
    % Delete temporary chunk
    % ----------------------------------------------------------------------

    delete(temp_file)
    fprintf("  DONE: %d/%d chunks\n",nDone,nChunks)
    
    if test_chunk > 0
        fprintf("\n")
        fprintf( ...
            "TestChunk mode: chunk %d completed successfully.\n", ...
            test_chunk)
        break
    end
end

%% =========================================================================
% Final GeoTIFF metadata alignment
% =========================================================================

if nDone == nChunks
    align_svf_geotiff_to_dem(final_file,dem_file);
else
    fprintf("\n")
    fprintf( ...
        "SVF computation incomplete (%d / %d chunks DONE).\n", ...
        nDone,nChunks)
    fprintf( ...
        "GeoTIFF metadata alignment will be performed after all chunks are complete.\n")
end

%% =========================================================================
% Final validation
% =========================================================================

fprintf("\n")
fprintf("============================================================\n")
fprintf("FULL-ALPS SVF COMPLETE\n")
fprintf("============================================================\n")
fprintf("Chunks DONE: %d / %d\n",nDone,nChunks)
fprintf("Output:\n  %s\n",final_file)
fprintf("============================================================\n")

%% =========================================================================
% Close parallel pool if created by this function
% =========================================================================

if pool_created
    fprintf("\nClosing parallel pool...\n")
    delete(pool)
end

end