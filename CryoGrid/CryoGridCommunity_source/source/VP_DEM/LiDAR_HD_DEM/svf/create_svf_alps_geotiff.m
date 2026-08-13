function create_svf_alps_geotiff( ...
    filename, ...
    nRows, ...
    nCols, ...
    R, ...
    nodata, ...
    tile_size)
%CREATE_SVF_ALPS_GEOTIFF Create the production Alpine SVF BigTIFF.
%
% PURPOSE
%   Creates and initializes the final tiled BigTIFF used by the Alpine
%   SVF ray-tracing workflow.
%
% INPUTS
%   filename     - output BigTIFF filename
%   nRows        - raster height [pixels]
%   nCols        - raster width [pixels]
%   R            - spatial referencing object for the Alpine raster
%   nodata        - NoData value used for unprocessed pixels
%   tile_size    - TIFF tile dimensions [pixels]
%
% OUTPUT
%   None. The function creates the BigTIFF at filename.
%
% OUTPUT RASTER
%   The raster is:
%     - single precision
%     - IEEE floating point
%     - uncompressed
%     - tiled
%     - tile_size x tile_size pixels per tile
%     - initialized entirely to NoData
%
% TILE ORGANIZATION
%   The TIFF tile grid is deliberately identical to the SVF processing
%   chunk grid. Consequently, each completed processing chunk maps
%   directly to one TIFF tile.
%
%   Edge tiles remain full TIFF tiles and are padded with NoData outside
%   the actual Alpine raster extent.
%
% WORKFLOW ROLE
%   This function only creates and initializes the final output raster.
%   It performs no DEM processing or ray tracing.

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

empty_tile = single(nodata * ones(tile_size,tile_size));

for itile = 1:nTiles
    writeEncodedTile(t, itile, empty_tile);
end

fprintf("%d / %d tiles initialized\n",nTiles,nTiles)

%% =========================================================================
% Close
% =========================================================================

close(t)
clear cleanup

fprintf("\n")
fprintf("Final SVF BigTIFF created successfully.\n")

end