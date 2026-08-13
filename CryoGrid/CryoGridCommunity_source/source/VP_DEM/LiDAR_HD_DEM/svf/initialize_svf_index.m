function index = initialize_svf_index( ...
    nRows,nCols,chunk_size,nBins,max_distance)

nChunkRows = ceil(nRows/chunk_size);
nChunkCols = ceil(nCols/chunk_size);

nChunks = nChunkRows*nChunkCols;

index = struct();

index.version = 1;
index.nRows = nRows;
index.nCols = nCols;
index.chunk_size = chunk_size;
index.nBins = nBins;
index.max_distance = max_distance;

index.nChunkRows = nChunkRows;
index.nChunkCols = nChunkCols;
index.nChunks = nChunks;

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
