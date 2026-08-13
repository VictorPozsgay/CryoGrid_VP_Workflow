function create_svf_alps_geotiff( ...
    filename, ...
    nRows, ...
    nCols, ...
    R, ...
    nodata, ...
    tile_size)
%CREATE_SVF_ALPS_GEOTIFF
% Create the final tiled Alpine SVF BigTIFF.
%
% The raster is:
%
%   - single precision
%   - IEEE floating point
%   - uncompressed
%   - tiled
%   - tile size = tile_size x tile_size
%   - initialized entirely to NoData
%
% The TIFF tile grid is deliberately identical to the SVF processing
% chunk grid. Therefore one completed SVF chunk can later be written
% directly into exactly one TIFF tile.
%
% Edge tiles are full TIFF tiles and are padded with NoData outside the
% actual raster extent.
%
% This function creates the BigTIFF only. It does not perform any
% ray-tracing.

%% =========================================================================
% Validate inputs
% =========================================================================

if ~isscalar(nRows) || ...
   ~isscalar(nCols) || ...
   nRows < 1 || ...
   nCols < 1

    error("nRows and nCols must be positive scalars.")
end

if ~isscalar(tile_size) || ...
   ~isfinite(tile_size) || ...
   tile_size < 16 || ...
   tile_size ~= round(tile_size)

    error("tile_size must be an integer >= 16.")
end

if ~isfinite(nodata)

    error("NoData value must be finite.")
end

if isfile(filename)
    error( ...
        "SVF BigTIFF already exists. Refusing to overwrite:\n%s", ...
        filename)
end

output_dir = fileparts(filename);

if ~isempty(output_dir) && ~isfolder(output_dir)
    mkdir(output_dir)
end

%% =========================================================================
% TIFF geometry
% =========================================================================

nTileRows = ceil(nRows/tile_size);
nTileCols = ceil(nCols/tile_size);

nTiles = nTileRows*nTileCols;

%% =========================================================================
% Report
% =========================================================================

fprintf("\n")
fprintf("Creating final Alpine SVF BigTIFF:\n")
fprintf("%s\n",filename)

fprintf("Size       : %d x %d pixels\n", ...
    nRows,nCols)

fprintf("Resolution : %.3f x %.3f m\n", ...
    R.CellExtentInWorldX, ...
    R.CellExtentInWorldY)

fprintf("Tile size  : %d x %d\n", ...
    tile_size,tile_size)

fprintf("Type       : single / IEEE floating point\n")
fprintf("NoData     : %.0f\n",nodata)
fprintf("Compression: None\n")
fprintf("Format     : BigTIFF\n")

fprintf("TIFF tiles : %d x %d = %d\n", ...
    nTileRows,nTileCols,nTiles)

%% =========================================================================
% Create BigTIFF
% =========================================================================

t = Tiff(filename,"w8");

cleanup = onCleanup(@() close(t));

tag.ImageLength = nRows;
tag.ImageWidth = nCols;

tag.Photometric = Tiff.Photometric.MinIsBlack;

tag.BitsPerSample = 32;
tag.SamplesPerPixel = 1;
tag.SampleFormat = Tiff.SampleFormat.IEEEFP;
tag.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;

% IMPORTANT:
%
% MATLAB/Tiff does not allow writeEncodedTile() to modify an existing
% compressed tile. The production BigTIFF is therefore deliberately
% uncompressed.
tag.Compression = Tiff.Compression.None;

tag.TileLength = tile_size;
tag.TileWidth = tile_size;

tag.Software = "CryoGrid VP_DEM SVF";

setTag(t,tag);

%% =========================================================================
% Initialize every TIFF tile
% =========================================================================

fprintf("\n")
fprintf("Writing empty TIFF tiles:\n")

empty_tile = single( ...
    nodata * ones(tile_size,tile_size));

for itile = 1:nTiles

    writeEncodedTile( ...
        t, ...
        itile, ...
        empty_tile);

end

fprintf("%d / %d tiles initialized\n", ...
    nTiles,nTiles)

%% =========================================================================
% Close
% =========================================================================

close(t)
clear cleanup

fprintf("\n")
fprintf("Final SVF BigTIFF created successfully.\n")

end