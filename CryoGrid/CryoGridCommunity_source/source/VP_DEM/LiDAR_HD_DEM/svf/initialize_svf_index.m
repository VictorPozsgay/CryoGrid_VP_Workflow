function index = initialize_svf_index( ...
    nRows,nCols,chunk_size,nBins,max_distance)
%INITIALIZE_SVF_INDEX Initialize the restart index for Alpine SVF chunks.
%
% PURPOSE
%   Creates the persistent processing index used by the Alpine SVF
%   workflow to track the status of every processing chunk.
%
% INPUTS
%   nRows         - full Alpine raster height [pixels]
%   nCols         - full Alpine raster width [pixels]
%   chunk_size    - target processing chunk size [pixels]
%   nBins         - number of azimuth bins used for SVF calculation
%   max_distance  - maximum ray-tracing distance [m]
%
% OUTPUT
%   index         - structure containing:
%                     - raster and processing parameters
%                     - chunk-grid dimensions
%                     - status and metadata for every chunk
%
% CHUNK STATUS
%   Each chunk is initially assigned:
%
%       status = "NOT DONE"
%
%   During processing, completed chunks are changed to:
%
%       status = "DONE"
%
%   Chunks containing no valid DEM pixels are also marked "DONE", since
%   their corresponding final TIFF tile remains entirely NoData.
%
% RESTART WORKFLOW
%   The index is saved by save_index() after each successfully completed
%   chunk. It therefore provides the persistent restart state for
%   compute_skyview_factor_alps().
%
% NOTE
%   Chunk IDs are assigned in row-major order: all column chunks of one
%   chunk row are assigned before proceeding to the next chunk row.

nChunkRows = ceil(nRows/chunk_size);
nChunkCols = ceil(nCols/chunk_size);

nChunks = nChunkRows*nChunkCols;

index = struct();

index.version      = 1;
index.nRows        = nRows;
index.nCols        = nCols;
index.chunk_size   = chunk_size;
index.nBins        = nBins;
index.max_distance = max_distance;

index.nChunkRows = nChunkRows;
index.nChunkCols = nChunkCols;
index.nChunks    = nChunks;

index.chunk = repmat( ...
    struct( ...
    "id",0, ...
    "row1",0, ...
    "row2",0, ...
    "col1",0, ...
    "col2",0, ...
    "status","NOT DONE", ...
    "valid_pixels",0, ...
    "timestamp",NaT), ...
    nChunks,1);

k = 0;

for ir = 1:nChunkRows

    row1 = (ir-1)*chunk_size + 1;
    row2 = min(ir*chunk_size,nRows);

    for ic = 1:nChunkCols

        col1 = (ic-1)*chunk_size + 1;
        col2 = min(ic*chunk_size,nCols);

        k = k + 1;

        index.chunk(k).id = k;
        index.chunk(k).row1 = row1;
        index.chunk(k).row2 = row2;
        index.chunk(k).col1 = col1;
        index.chunk(k).col2 = col2;

    end

end

end
