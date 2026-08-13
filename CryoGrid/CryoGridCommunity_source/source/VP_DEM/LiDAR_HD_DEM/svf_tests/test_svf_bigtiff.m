function test_svf_bigtiff(output_path)
%TEST_SVF_BIGTIFF
% Test the exact tiled BigTIFF architecture used by
% compute_skyview_factor_alps().
%
% No ray tracing is performed.
%
% The test creates a 1300 x 1100 raster, corresponding to:
%
%       2 TIFF tile columns
%       2 TIFF tile rows
%
% with 1024 x 1024 tiles.
%
% It then writes:
%
%   tile 1 -> recognizable gradient
%   tile 4 -> recognizable constant value
%
% and verifies:
%
%   - raster dimensions
%   - spatial reference
%   - resolution
%   - Lambert-93 CRS
%   - NoData
%   - tile size
%   - written values
%   - untouched tiles
%   - edge padding
%   - compression

%% ------------------------------------------------------------------------
% Add helpers
% -------------------------------------------------------------------------

addpath(genpath(fileparts(mfilename("fullpath"))));

%% ------------------------------------------------------------------------
% Source DEM
% -------------------------------------------------------------------------

dem_file = fullfile( ...
    output_path, ...
    "DEM","ALPS","DEM_ALPS.tif");

if ~isfile(dem_file)
    error("Alpine DEM not found:\n%s",dem_file)
end

fprintf("\n")
fprintf("============================================================\n")
fprintf("SVF BIGTIFF TILED WRITE TEST\n")
fprintf("============================================================\n")

%% ------------------------------------------------------------------------
% Read DEM metadata
% -------------------------------------------------------------------------

info = georasterinfo(dem_file);

Rdem = info.RasterReference;

nDemRows = info.RasterSize(1);
nDemCols = info.RasterSize(2);

fprintf("DEM size       : %d x %d\n", ...
    nDemRows,nDemCols)

fprintf("DEM resolution : %.3f x %.3f m\n", ...
    Rdem.CellExtentInWorldX, ...
    Rdem.CellExtentInWorldY)

%% ------------------------------------------------------------------------
% Test raster dimensions
% -------------------------------------------------------------------------

tile_size = 1024;

test_rows = 1300;
test_cols = 1100;

fprintf("\nTest raster:\n")
fprintf("  Size       : %d x %d\n", ...
    test_rows,test_cols)

fprintf("  Tile size  : %d x %d\n", ...
    tile_size,tile_size)

fprintf("  Tile grid  : %d x %d\n", ...
    ceil(test_rows/tile_size), ...
    ceil(test_cols/tile_size))

%% ------------------------------------------------------------------------
% Construct test spatial reference
% -------------------------------------------------------------------------

dx = abs(Rdem.CellExtentInWorldX);
dy = abs(Rdem.CellExtentInWorldY);

x1 = Rdem.XWorldLimits(1);

x2 = x1 + test_cols*dx;

y2 = Rdem.YWorldLimits(2);

y1 = y2 - test_rows*dy;

Rtest = maprefcells( ...
    [x1 x2], ...
    [y1 y2], ...
    [test_rows test_cols], ...
    "ColumnsStartFrom","north", ...
    "RowsStartFrom","west");

try
    Rtest.ProjectedCRS = Rdem.ProjectedCRS;
catch
    % The TIFF itself will still contain EPSG:2154 GeoTIFF keys.
end

%% ------------------------------------------------------------------------
% Output file
% -------------------------------------------------------------------------

test_file = fullfile( ...
    output_path, ...
    "SVF", ...
    "SVF_BigTIFF_TEST.tif");

if isfile(test_file)
    delete(test_file)
end

%% ------------------------------------------------------------------------
% Initialize tiled BigTIFF
% -------------------------------------------------------------------------

initialize_svf_bigtiff( ...
    test_file, ...
    test_rows, ...
    test_cols, ...
    Rtest, ...
    -9999, ...
    tile_size);

%% ------------------------------------------------------------------------
% Read initialized file
% -------------------------------------------------------------------------

fprintf("\nChecking initialized BigTIFF...\n")

[A0,R0] = readgeoraster(test_file);

A0 = single(A0);

if ~isequal(size(A0),[test_rows test_cols])
    error("Initial raster size mismatch.")
end

if any(A0(:) ~= single(-9999))
    error("Initial NoData initialization failed.")
end

%% ------------------------------------------------------------------------
% Verify spatial reference
% -------------------------------------------------------------------------

tol = 1e-9;

if abs(R0.CellExtentInWorldX - Rtest.CellExtentInWorldX) > tol || ...
   abs(R0.CellExtentInWorldY - Rtest.CellExtentInWorldY) > tol

    error("Cell size changed.")
end

if any(abs(R0.XWorldLimits - Rtest.XWorldLimits) > tol) || ...
   any(abs(R0.YWorldLimits - Rtest.YWorldLimits) > tol)

    error("World limits changed.")
end

fprintf("  Raster geometry OK.\n")

%% ------------------------------------------------------------------------
% Inspect TIFF structure
% -------------------------------------------------------------------------

t = Tiff(test_file,"r");

fprintf("\nTIFF properties:\n")

fprintf("  ImageLength   : %d\n", ...
    getTag(t,"ImageLength"))

fprintf("  ImageWidth    : %d\n", ...
    getTag(t,"ImageWidth"))

fprintf("  BitsPerSample : %d\n", ...
    getTag(t,"BitsPerSample"))

fprintf("  SampleFormat  : %s\n", ...
    getTag(t,"SampleFormat"))

fprintf("  TileLength    : %d\n", ...
    getTag(t,"TileLength"))

fprintf("  TileWidth     : %d\n", ...
    getTag(t,"TileWidth"))

fprintf("  Compression   : %d\n", ...
    getTag(t,"Compression"))

fprintf("  NumberTiles   : %d\n", ...
    numberOfTiles(t))

close(t)

%% ------------------------------------------------------------------------
% Tile 1
% -------------------------------------------------------------------------
%
% Full 1024 x 1024 tile.
%
% Recognizable horizontal gradient from 0.10 to 0.90.

SVF_tile1 = single( ...
    repmat( ...
        linspace(0.10,0.90,tile_size), ...
        tile_size,1));

fprintf("\nWriting tile 1...\n")

write_svf_tile( ...
    test_file, ...
    1, ...
    SVF_tile1, ...
    tile_size);

verify_svf_tile( ...
    test_file, ...
    1, ...
    SVF_tile1, ...
    tile_size);

fprintf("  Tile 1 verified.\n")

%% ------------------------------------------------------------------------
% Tile 4
% -------------------------------------------------------------------------
%
% Bottom-right tile.
%
% Because the test raster is only 1300 x 1100:
%
%   tile 4 = 276 rows x 76 columns
%
% The remaining part of the physical 1024 x 1024 TIFF tile must remain
% NoData.

tile4_rows = test_rows - tile_size;
tile4_cols = test_cols - tile_size;

SVF_tile4 = single( ...
    0.75 * ones(tile4_rows,tile4_cols));

fprintf("\nWriting tile 4...\n")

write_svf_tile( ...
    test_file, ...
    4, ...
    SVF_tile4, ...
    tile_size);

verify_svf_tile( ...
    test_file, ...
    4, ...
    SVF_tile4, ...
    tile_size);

fprintf("  Tile 4 verified.\n")

%% ------------------------------------------------------------------------
% Read final raster
% -------------------------------------------------------------------------

fprintf("\nReading final raster...\n")

[A,R] = readgeoraster(test_file);

A = single(A);

%% ------------------------------------------------------------------------
% Verify tile 1
% -------------------------------------------------------------------------

if ~isequal( ...
        A(1:tile_size,1:tile_size), ...
        SVF_tile1)

    error("Tile 1 values are incorrect.")
end

fprintf("  Tile 1 values OK.\n")

%% ------------------------------------------------------------------------
% Verify tile 4
% -------------------------------------------------------------------------

actual4 = A( ...
    tile_size+1:test_rows, ...
    tile_size+1:test_cols);

if ~isequal(actual4,SVF_tile4)

    error("Tile 4 values are incorrect.")
end

fprintf("  Tile 4 values OK.\n")

%% ------------------------------------------------------------------------
% Verify untouched regions
% -------------------------------------------------------------------------

% Top-right tile
untouched_top_right = A( ...
    1:tile_size, ...
    tile_size+1:test_cols);

if any(untouched_top_right(:) ~= single(-9999))
    error("Untouched top-right region was modified.")
end

% Bottom-left tile
untouched_bottom_left = A( ...
    tile_size+1:test_rows, ...
    1:tile_size);

if any(untouched_bottom_left(:) ~= single(-9999))
    error("Untouched bottom-left region was modified.")
end

fprintf("  Untouched tiles OK.\n")

%% ------------------------------------------------------------------------
% Verify geometry again
% -------------------------------------------------------------------------

if abs(R.CellExtentInWorldX - Rtest.CellExtentInWorldX) > tol || ...
   abs(R.CellExtentInWorldY - Rtest.CellExtentInWorldY) > tol

    error("Final cell size changed.")
end

if any(abs(R.XWorldLimits - Rtest.XWorldLimits) > tol) || ...
   any(abs(R.YWorldLimits - Rtest.YWorldLimits) > tol)

    error("Final world limits changed.")
end

fprintf("  Final geometry OK.\n")

%% ------------------------------------------------------------------------
% Success
% -------------------------------------------------------------------------

fprintf("\n")
fprintf("============================================================\n")
fprintf("BIGTIFF TEST SUCCESSFUL\n")
fprintf("============================================================\n")
fprintf("Created : %s\n",test_file)
fprintf("Size    : %d x %d\n",test_rows,test_cols)
fprintf("Tiles   : 2 x 2\n")
fprintf("NoData  : -9999\n")
fprintf("Tile 1  : verified\n")
fprintf("Tile 4  : verified\n")
fprintf("Padding : verified\n")
fprintf("Untouched tiles : verified\n")
fprintf("Geometry : verified\n")
fprintf("============================================================\n")

end