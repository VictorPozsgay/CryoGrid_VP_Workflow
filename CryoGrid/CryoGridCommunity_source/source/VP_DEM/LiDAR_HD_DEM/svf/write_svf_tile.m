function write_svf_tile( ...
    filename, ...
    tile_number, ...
    SVF_chunk, ...
    tile_size)
%WRITE_SVF_TILE Write one SVF processing chunk into a TIFF tile.
%
% Writes an SVF chunk directly into its corresponding tile of the final
% Alpine SVF BigTIFF.
%
% Interior chunks normally have dimensions tile_size x tile_size.
% Edge chunks may be smaller because they can intersect the raster
% boundary. The unused portion of an edge tile is filled with NoData.
%
% Inputs:
%   filename    - Final Alpine SVF BigTIFF.
%   tile_number - TIFF tile number corresponding to the SVF chunk.
%   SVF_chunk   - SVF values for the processing chunk.
%   tile_size   - TIFF tile width and height in pixels.
%
% The function verifies the existing TIFF geometry before writing and
% performs an in-place tile update using MATLAB's Tiff interface.
%
% NoData:
%   Unused portions of edge tiles are filled with -9999.
%
% This function is part of the restartable Alpine SVF production
% workflow. A chunk is marked DONE only after the tile has subsequently
% been verified successfully.

nodata = single(-9999);

%% ------------------------------------------------------------------------
% Validate
% -------------------------------------------------------------------------

if ~isfile(filename)
    error("SVF BigTIFF not found:\n%s",filename)
end

SVF_chunk = single(SVF_chunk);
[nRows,nCols] = size(SVF_chunk);

if nRows > tile_size || nCols > tile_size
    error("SVF chunk exceeds TIFF tile dimensions.")
end

%% ------------------------------------------------------------------------
% Open TIFF
% -------------------------------------------------------------------------

t = Tiff(filename,"r+");
cleanup = onCleanup(@()close(t));

%% ------------------------------------------------------------------------
% Verify TIFF layout
% -------------------------------------------------------------------------

image_length = getTag(t,"ImageLength");
image_width  = getTag(t,"ImageWidth");

tile_length  = getTag(t,"TileLength");
tile_width   = getTag(t,"TileWidth");

if tile_length ~= tile_size || tile_width ~= tile_size
    error( ...
        "TIFF tile size is %d x %d, expected %d x %d.", ...
        tile_length,tile_width,tile_size,tile_size)
end

if nCols > image_width || nRows > image_length
    error("SVF chunk exceeds TIFF raster dimensions.")
end

%% ------------------------------------------------------------------------
% Construct complete tile
% -------------------------------------------------------------------------

tile = nodata * ones(tile_size,tile_size,"single");
tile(1:nRows,1:nCols) = SVF_chunk;

%% ------------------------------------------------------------------------
% Write tile
% -------------------------------------------------------------------------

writeEncodedTile(t,tile_number,tile);
close(t);
clear cleanup

end