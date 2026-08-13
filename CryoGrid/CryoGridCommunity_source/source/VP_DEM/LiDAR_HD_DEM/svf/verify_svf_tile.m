function verify_svf_tile( ...
    filename, ...
    tile_number, ...
    expected, ...
    tile_size)
%VERIFY_SVF_TILE
% Verify one SVF TIFF tile after in-place writing.
%
% Full interior tiles are expected to be tile_size x tile_size.
%
% Edge tiles may be returned by MATLAB's TIFF reader using their actual
% raster dimensions rather than the nominal TIFF tile dimensions.
%
% Therefore both cases are accepted.

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

    expected_tile = ...
        nodata * ones(tile_size,tile_size,"single");

    expected_tile( ...
        1:nExpectedRows, ...
        1:nExpectedCols) = expected;

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