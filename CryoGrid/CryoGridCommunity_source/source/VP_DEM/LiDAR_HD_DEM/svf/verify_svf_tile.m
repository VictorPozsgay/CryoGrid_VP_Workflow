function verify_svf_tile( ...
    filename, ...
    tile_number, ...
    expected, ...
    tile_size)
%VERIFY_SVF_TILE Verify one SVF tile after in-place BigTIFF writing.
%
% Reads the specified TIFF tile from the final Alpine SVF BigTIFF and
% compares it with the expected SVF chunk.
%
% Full interior tiles are expected to have dimensions:
%
%   tile_size x tile_size
%
% Edge tiles may contain only the valid raster portion when returned by
% MATLAB's TIFF reader. Both representations are accepted.
%
% Inputs:
%   filename    - Final Alpine SVF BigTIFF.
%   tile_number - TIFF tile number corresponding to the SVF chunk.
%   expected    - Expected SVF chunk values.
%   tile_size   - TIFF tile width and height in pixels.
%
% The function raises an error if the tile dimensions or values do not
% match the expected result.
%
% This verification is performed before the corresponding processing
% chunk is marked as DONE in the restart index.

nodata = single(-9999);

%% ------------------------------------------------------------------------
% Open TIFF
% -------------------------------------------------------------------------

t = Tiff(filename,"r");
cleanup = onCleanup(@()close(t));

%% ------------------------------------------------------------------------
% Read tile
% -------------------------------------------------------------------------

actual = readEncodedTile(t,tile_number);

close(t);
clear cleanup

actual = single(actual);
expected = single(expected);

%% ------------------------------------------------------------------------
% Expected dimensions
% -------------------------------------------------------------------------

[nExpectedRows,nExpectedCols] = size(expected);
[nActualRows,nActualCols] = size(actual);

%% ------------------------------------------------------------------------
% Case 1: full tile
% -------------------------------------------------------------------------

if nActualRows == tile_size && ...
   nActualCols == tile_size

    expected_tile = nodata * ones(tile_size,tile_size,"single");
    expected_tile(1:nExpectedRows,1:nExpectedCols) = expected;

    if ~isequal(actual,expected_tile)
        error( ...
            "Final TIFF tile verification failed for tile %d.", ...
            tile_number)
    end

    return

end

%% ------------------------------------------------------------------------
% Case 2: edge tile
% -------------------------------------------------------------------------
%
% MATLAB may return only the valid raster portion of an edge tile.

if nActualRows == nExpectedRows && ...
   nActualCols == nExpectedCols

    if ~isequal(actual,expected)
        error( ...
            "Final TIFF edge tile values failed verification for tile %d.", ...
            tile_number)
    end

    return

end

%% ------------------------------------------------------------------------
% Unexpected dimensions
% -------------------------------------------------------------------------

error( ...
    ["Final TIFF tile size mismatch for tile %d.\n" ...
     "Expected chunk: %d x %d\n" ...
     "Actual tile:    %d x %d"], ...
    tile_number, ...
    nExpectedRows, ...
    nExpectedCols, ...
    nActualRows, ...
    nActualCols)

end