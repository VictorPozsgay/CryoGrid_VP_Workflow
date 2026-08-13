function compute_skyview_factor2(output_path,path_shapefile,varargin)
%COMPUTE_SKYVIEW_FACTOR2 Horizon-based sky-view factor.
%
%   Computes SVF from terrain horizons derived from the merged Alpine DEM.
%
%   IMPORTANT:
%   The full Alpine DEM is NOT loaded into memory. For each massif, only
%   the DEM window required for the requested horizon search distance is
%   read.
%
%   The calculation is:
%
%       SVF = mean(cosd(horizon).^2,3)
%
%   where horizon is the maximum terrain elevation angle in each azimuth.
%
%   Example:
%
%       compute_skyview_factor2( ...
%           output_path, ...
%           path_shapefile, ...
%           "Massif",12, ...
%           "NumBins",36, ...
%           "MaxDistance",5000, ...
%           "TestMode",true, ...
%           "Overwrite",true)
%
% OPTIONS
%
%   "NumBins"
%       Number of azimuth bins.
%       Default = [] -> ask interactively.
%
%   "Massif"
%       Massif number(s) to process.
%       Default = [] -> all massifs.
%
%   "MaxDistance"
%       Maximum terrain horizon search distance in metres.
%       Default = 5000 m.
%
%   "Overwrite"
%       Recompute existing products.
%       Default = false.
%
%   "TestMode"
%       Reduce target pixels to a central test region.
%       Default = false.
%
%   "TestSize"
%       Width of the test region in pixels.
%       Default = 300.
%
%   "UseParallel"
%       Use parfor if available.
%       Default = true.
%
% OUTPUT
%
%       SVF/SVF_massif_XX.tif
%
% NOTES
%
%   Azimuth convention:
%
%       0   = North
%       90  = East
%       180 = South
%       270 = West
%
%   The Alpine DEM is used as the terrain source. The SAFRAN massif
%   polygon is only used to define the output region.
%

%% ------------------------------------------------------------------------
% Options
% -------------------------------------------------------------------------

p = inputParser;

addParameter(p,"NumBins",[])
addParameter(p,"Massif",[])
addParameter(p,"MaxDistance",5000)
addParameter(p,"Overwrite",false)
addParameter(p,"TestMode",false)
addParameter(p,"TestSize",300)
addParameter(p,"UseParallel",true)

parse(p,varargin{:})

nBins        = p.Results.NumBins;
massif_req   = p.Results.Massif;
max_distance = p.Results.MaxDistance;
overwrite    = p.Results.Overwrite;
test_mode    = p.Results.TestMode;
test_size    = p.Results.TestSize;
use_parallel = p.Results.UseParallel;

%% ------------------------------------------------------------------------
% Validate inputs
% -------------------------------------------------------------------------

if ~isfolder(output_path)
    error("Output directory not found: %s",output_path)
end

if ~isfile(path_shapefile)
    error("SAFRAN shapefile not found: %s",path_shapefile)
end

dem_file = fullfile(output_path,"DEM","ALPS","DEM_ALPS.tif");

if ~isfile(dem_file)
    error("Alpine DEM not found: %s",dem_file)
end

if ~isscalar(max_distance) || ...
        ~isfinite(max_distance) || max_distance <= 0

    error("MaxDistance must be a positive finite scalar.")

end

%% ------------------------------------------------------------------------
% Number of bins
% -------------------------------------------------------------------------

if isempty(nBins)

    fprintf("\n")
    fprintf("Horizon-based sky-view factor\n")
    fprintf("----------------------------------------\n")
    fprintf("  36  = 10 degree azimuth resolution\n")
    fprintf("  72  = 5 degree azimuth resolution\n")
    fprintf("  180 = 2 degree azimuth resolution\n")
    fprintf("  360 = 1 degree azimuth resolution\n")
    fprintf("\n")

    nBins = input("Number of azimuth bins: ");

end

if isempty(nBins) || ...
        ~isscalar(nBins) || ...
        ~isfinite(nBins) || ...
        nBins < 4 || ...
        nBins ~= round(nBins)

    error("NumBins must be an integer >= 4.")

end

nBins = double(nBins);

%% ------------------------------------------------------------------------
% Read only DEM metadata
% -------------------------------------------------------------------------

fprintf("\n")
fprintf("Reading Alpine DEM metadata:\n")
fprintf("  %s\n",dem_file)

info = georasterinfo(dem_file);

R = info.RasterReference;

raster_size = info.RasterSize;

nRows = raster_size(1);
nCols = raster_size(2);

fprintf("Full DEM size: %d x %d pixels\n",nRows,nCols)

dx = abs(R.CellExtentInWorldX);
dy = abs(R.CellExtentInWorldY);

fprintf("Resolution: %.3f m x %.3f m\n",dx,dy)

fprintf("Maximum horizon distance: %.1f m\n",max_distance)

%% ------------------------------------------------------------------------
% Read SAFRAN massifs
% -------------------------------------------------------------------------

S = shaperead(path_shapefile);

[~,idx] = sort([S.massif_num]);
S = S(idx);

massif_numbers = [S.massif_num];

if isempty(massif_req)

    if test_mode
        massif_req = massif_numbers(1);
    else
        massif_req = massif_numbers;
    end

else

    massif_req = massif_req(:)';

end

for k = 1:numel(massif_req)

    if ~ismember(massif_req(k),massif_numbers)

        error("Massif %d not found in shapefile.",massif_req(k))

    end

end

%% ------------------------------------------------------------------------
% Output directory
% -------------------------------------------------------------------------

svf_path = fullfile(output_path,"SVF");

if ~isfolder(svf_path)
    mkdir(svf_path)
end

%% ------------------------------------------------------------------------
% Parallel pool
% -------------------------------------------------------------------------

parallel_enabled = false;

if use_parallel

    try

        pool = gcp("nocreate");

        if isempty(pool)
            pool = parpool("Processes");
        end

        parallel_enabled = true;

        fprintf("Parallel computation enabled: %d workers\n", ...
            pool.NumWorkers)

    catch ME

        warning( ...
            "Could not start parallel pool. Using serial computation.\n%s", ...
            ME.message)

    end

end

%% ------------------------------------------------------------------------
% Azimuths
% -------------------------------------------------------------------------

azimuths = (0:nBins-1) * 360/nBins;

fprintf("\n")
fprintf("SVF configuration\n")
fprintf("----------------------------------------\n")
fprintf("Azimuth bins       : %d\n",nBins)
fprintf("Azimuth spacing    : %.3f degrees\n",360/nBins)
fprintf("Maximum distance   : %.1f m\n",max_distance)
fprintf("Parallel           : %d\n",parallel_enabled)
fprintf("----------------------------------------\n")

%% ------------------------------------------------------------------------
% Process massifs
% -------------------------------------------------------------------------

for im = 1:numel(massif_req)

    massif_id = massif_req(im);

    % -------------------------------------------------------------------------
    % Massif DEM = authoritative output grid
    % -------------------------------------------------------------------------

    massif_dem_file = fullfile( ...
        output_path, ...
        "DEM", ...
        sprintf("DEM_massif_%02d.tif",massif_id));

    if ~isfile(massif_dem_file)
        error( ...
            "Massif DEM not found for Massif %d:\n%s", ...
            massif_id,massif_dem_file)
    end

    massif_dem_info = georasterinfo(massif_dem_file);
    Rmassif = massif_dem_info.RasterReference;

    massif_raster_size = massif_dem_info.RasterSize;

    fprintf("\nAuthoritative massif DEM grid:\n")
    fprintf("  %d x %d pixels\n", ...
        massif_raster_size(1),massif_raster_size(2))

    fprintf("  X: %.1f -> %.1f m\n", ...
        Rmassif.XWorldLimits(1), ...
        Rmassif.XWorldLimits(2))

    fprintf("  Y: %.1f -> %.1f m\n", ...
        Rmassif.YWorldLimits(1), ...
        Rmassif.YWorldLimits(2))

    fprintf("  Resolution: %.3f x %.3f m\n", ...
        Rmassif.CellExtentInWorldX, ...
        Rmassif.CellExtentInWorldY)

    Sidx = find(massif_numbers == massif_id,1);

    fprintf("\n")
    fprintf("============================================================\n")
    fprintf("Massif %d (%d/%d)\n",massif_id,im,numel(massif_req))
    fprintf("============================================================\n")

    output_file = fullfile( ...
        svf_path, ...
        sprintf("SVF_massif_%02d.tif",massif_id));

    if isfile(output_file) && ~overwrite

        fprintf("Existing SVF found. Skipping:\n")
        fprintf("  %s\n",output_file)

        continue

    end

    %% -------------------------------------------------------------
    % Determine massif bounding box
    % --------------------------------------------------------------

    fprintf("Determining massif extent...\n")

    [xmin,xmax,ymin,ymax] = polygon_extent(S(Sidx));

    fprintf("Massif extent:\n")
    fprintf("  X: %.1f -> %.1f m\n",xmin,xmax)
    fprintf("  Y: %.1f -> %.1f m\n",ymin,ymax)

    % Keep the original massif extent for the final output.
    xmin_massif = xmin;
    xmax_massif = xmax;
    ymin_massif = ymin;
    ymax_massif = ymax;

    %% -------------------------------------------------------------
    % Expand by horizon distance
    % --------------------------------------------------------------

    xmin_dem = xmin - max_distance;
    xmax_dem = xmax + max_distance;
    ymin_dem = ymin - max_distance;
    ymax_dem = ymax + max_distance;

    fprintf("\nDEM calculation window:\n")
    fprintf("  X: %.1f -> %.1f m\n",xmin_dem,xmax_dem)
    fprintf("  Y: %.1f -> %.1f m\n",ymin_dem,ymax_dem)

    %% -------------------------------------------------------------
    % Convert world extent to raster rows/columns
    % --------------------------------------------------------------

    [r1,r2,c1,c2] = world_extent_to_indices( ...
        R, ...
        xmin_dem, ...
        xmax_dem, ...
        ymin_dem, ...
        ymax_dem);

    % Clamp to DEM.
    r1 = max(1,r1);
    r2 = min(nRows,r2);
    c1 = max(1,c1);
    c2 = min(nCols,c2);

    fprintf("\nDEM window:\n")
    fprintf("  Rows: %d -> %d\n",r1,r2)
    fprintf("  Cols: %d -> %d\n",c1,c2)

    local_rows = r2-r1+1;
    local_cols = c2-c1+1;

    fprintf("  Size: %d x %d pixels\n",local_rows,local_cols)

    fprintf("  Memory as single: %.2f GB\n", ...
        local_rows*local_cols*4/1024^3)

    %% -------------------------------------------------------------
    % Read ONLY this DEM window
    % --------------------------------------------------------------

    fprintf("\nReading local DEM window...\n")

    [Z,Rlocal] = read_dem_window( ...
        dem_file, ...
        R, ...
        r1,r2,c1,c2);

    %% Read slope and aspect from the existing Alpine products

    slope_file = fullfile( ...
        output_path, ...
        "SLOPE","ALPS","SLOPE_ALPS.tif");

    aspect_file = fullfile( ...
        output_path, ...
        "ASPECT","ALPS","ASPECT_ALPS.tif");

    fprintf("Reading local slope...\n")

    [SLOPE,~] = read_dem_window( ...
        slope_file, ...
        R, ...
        r1,r2,c1,c2);

    fprintf("Reading local aspect...\n")

    [ASPECT,~] = read_dem_window( ...
        aspect_file, ...
        R, ...
        r1,r2,c1,c2);

    Z(Z <= -9000) = NaN;

    fprintf("Local DEM loaded.\n")

    %% -------------------------------------------------------------
    % Build local massif mask
    % --------------------------------------------------------------

    fprintf("Building local massif mask...\n")

    target_mask = build_massif_mask_local( ...
        S(Sidx), ...
        Rlocal, ...
        size(Z));

    target_mask = target_mask & isfinite(Z);

    fprintf("Target pixels: %d\n",nnz(target_mask))

    %% -------------------------------------------------------------
    % Test mode
    % --------------------------------------------------------------

    if test_mode

        target_mask = reduce_test_mask( ...
            target_mask, ...
            test_size);

        fprintf("TestMode target pixels: %d\n", ...
            nnz(target_mask))

    end

    if ~any(target_mask(:))

        warning("Massif %d has no valid target pixels.",massif_id)
        continue

    end

    %% -------------------------------------------------------------
    % Compute SVF
    % --------------------------------------------------------------

    fprintf("\nComputing horizon-based SVF...\n")

    tic

    SVF = compute_svf_raycast( ...
        Z,target_mask,SLOPE,ASPECT, ...
        dx,dy,azimuths,max_distance,use_parallel);

    elapsed = toc;

    %% -------------------------------------------------------------
    % Diagnostics
    % --------------------------------------------------------------

    valid_svf = SVF(isfinite(SVF));

    fprintf("\n")
    fprintf("SVF diagnostics\n")
    fprintf("----------------------------------------\n")
    fprintf("Elapsed time : %.2f minutes\n",elapsed/60)
    fprintf("Valid pixels : %d\n",numel(valid_svf))

    if ~isempty(valid_svf)

        fprintf("Minimum SVF  : %.5f\n",min(valid_svf))
        fprintf("Maximum SVF  : %.5f\n",max(valid_svf))
        fprintf("Mean SVF     : %.5f\n",mean(valid_svf))
        fprintf("Median SVF   : %.5f\n",median(valid_svf))

    end

    %% -------------------------------------------------------------
    % Extract SVF onto the exact massif DEM grid
    % -------------------------------------------------------------
    
    fprintf("\nExtracting SVF onto exact massif DEM grid...\n")
    
    % Convert the authoritative massif DEM extent into indices
    % of the expanded local ray-tracing raster.
    
    % -------------------------------------------------------------------------
    % Determine exact pixel offset of the massif DEM grid inside Rlocal.
    %
    % Rmassif is the authoritative output grid, so its RasterSize and
    % cell alignment determine the extraction indices exactly.
    % -------------------------------------------------------------------------
    
    tol = 1e-6;
    
    % Check that both rasters have the same resolution.
    if abs(Rlocal.CellExtentInWorldX - Rmassif.CellExtentInWorldX) > tol || ...
       abs(Rlocal.CellExtentInWorldY - Rmassif.CellExtentInWorldY) > tol
    
        error("Local DEM and massif DEM have different resolutions.")
    end
    
    % Column offset:
    % Rlocal.XWorldLimits(1) is the western edge of the calculation window.
    c1 = round( ...
        (Rmassif.XWorldLimits(1) - Rlocal.XWorldLimits(1)) ...
        / Rlocal.CellExtentInWorldX) + 1;
    
    c2 = c1 + massif_raster_size(2) - 1;
    
    % Row offset:
    % Rlocal.YWorldLimits(2) is the northern edge of the calculation window.
    r1 = round( ...
        (Rlocal.YWorldLimits(2) - Rmassif.YWorldLimits(2)) ...
        / Rlocal.CellExtentInWorldY) + 1;
    
    r2 = r1 + massif_raster_size(1) - 1;
    
    % -------------------------------------------------------------------------
    % Verify that the requested region fits inside the local calculation grid.
    % -------------------------------------------------------------------------
    
    if r1 < 1 || r2 > size(SVF,1) || ...
       c1 < 1 || c2 > size(SVF,2)
    
        error( ...
            "Massif DEM grid lies outside the ray-tracing calculation window.")
    end
    
    % -------------------------------------------------------------------------
    % Extract SVF
    % -------------------------------------------------------------------------
    
    SVF_output = SVF(r1:r2,c1:c2);
    
    %% -------------------------------------------------------------
    % HARD GRID VALIDATION
    % -------------------------------------------------------------
    
    fprintf("\nValidating SVF / DEM grid alignment...\n")
    
    % Raster size
    if ~isequal(size(SVF_output),massif_raster_size)
    
        error( ...
            "SVF/DEM RasterSize mismatch: SVF = %d x %d, DEM = %d x %d", ...
            size(SVF_output,1), ...
            size(SVF_output,2), ...
            massif_raster_size(1), ...
            massif_raster_size(2))
    end
    
    % Cell size
    tol = 1e-9;
    
    if abs(Rlocal.CellExtentInWorldX - Rmassif.CellExtentInWorldX) > tol || ...
       abs(Rlocal.CellExtentInWorldY - Rmassif.CellExtentInWorldY) > tol
    
        error("SVF/DEM cell size mismatch.")
    end
    
    % -------------------------------------------------------------------------
    % IMPORTANT:
    % Use the DEM reference object directly.
    %
    % This guarantees that the written SVF has exactly the same:
    %   - RasterSize
    %   - XWorldLimits
    %   - YWorldLimits
    %   - CellExtentInWorldX
    %   - CellExtentInWorldY
    %   - raster alignment
    % -------------------------------------------------------------------------
    
    Routput = Rmassif;
    
    %% -------------------------------------------------------------
    % Final grid diagnostics
    % -------------------------------------------------------------
    
    fprintf("Grid validation successful.\n")
    
    fprintf("  RasterSize : %d x %d\n", ...
        size(SVF_output,1),size(SVF_output,2))
    
    fprintf("  X limits   : %.3f -> %.3f m\n", ...
        Routput.XWorldLimits(1), ...
        Routput.XWorldLimits(2))
    
    fprintf("  Y limits   : %.3f -> %.3f m\n", ...
        Routput.YWorldLimits(1), ...
        Routput.YWorldLimits(2))
    
    fprintf("  Resolution : %.3f x %.3f m\n", ...
        Routput.CellExtentInWorldX, ...
        Routput.CellExtentInWorldY)
    
    %% -------------------------------------------------------------
    % Write output
    % -------------------------------------------------------------
    
    fprintf("\nWriting:\n")
    fprintf("  %s\n",output_file)
    
    write_svf_geotiff( ...
        output_file, ...
        SVF_output, ...
        Routput)
    
    fprintf("Output size: %d x %d pixels\n", ...
        size(SVF_output,1), ...
        size(SVF_output,2))
    
    fprintf("Finished massif %d.\n",massif_id)
    
end

fprintf("\n")
fprintf("Sky-view factor computation finished.\n")

end


%% =========================================================================
function [xmin,xmax,ymin,ymax] = polygon_extent(S)
%POLYGON_EXTENT Return finite polygon extent.

x = S.X(:);
y = S.Y(:);

valid = isfinite(x) & isfinite(y);

x = x(valid);
y = y(valid);

if isempty(x)
    error("Massif polygon contains no valid coordinates.")
end

xmin = min(x);
xmax = max(x);
ymin = min(y);
ymax = max(y);

end


%% =========================================================================
function [r1,r2,c1,c2] = world_extent_to_indices( ...
    R,xmin,xmax,ymin,ymax)
%WORLD_EXTENT_TO_INDICES Convert projected extent to raster indices.

[c1_tmp,r1_tmp] = worldToIntrinsic(R,xmin,ymax);
[c2_tmp,r2_tmp] = worldToIntrinsic(R,xmax,ymin);

c1 = floor(min(c1_tmp,c2_tmp));
c2 = ceil(max(c1_tmp,c2_tmp));

r1 = floor(min(r1_tmp,r2_tmp));
r2 = ceil(max(r1_tmp,r2_tmp));

end


%% =========================================================================
function [Z,Rlocal] = read_dem_window(filename,R,r1,r2,c1,c2)

%READ_DEM_WINDOW Read only the requested raster window.
%
% Uses imread PixelRegion rather than readgeoraster or manual TIFF
% tile decoding. This works with the tiled Alpine GeoTIFF and avoids
% loading the full raster into memory.

fprintf("  Reading raster window: %s\n",filename)

% -------------------------------------------------------------------------
% Read only requested pixels
% -------------------------------------------------------------------------

Z = imread(filename, ...
    "PixelRegion", ...
    {[r1 r2],[c1 c2]});

% Preserve floating-point representation
Z = double(Z);

fprintf("  Window read: %d x %d\n", ...
    size(Z,1),size(Z,2))

% -------------------------------------------------------------------------
% Construct spatial reference for cropped raster
% -------------------------------------------------------------------------

x1 = R.XWorldLimits(1) + (c1-1)*R.CellExtentInWorldX;
x2 = R.XWorldLimits(1) + c2*R.CellExtentInWorldX;

y2 = R.YWorldLimits(2) - (r1-1)*R.CellExtentInWorldY;
y1 = R.YWorldLimits(2) - r2*R.CellExtentInWorldY;

Rlocal = maprefcells( ...
    [x1 x2], ...
    [y1 y2], ...
    size(Z), ...
    "ColumnsStartFrom","north", ...
    "RowsStartFrom","west");

try
    Rlocal.ProjectedCRS = R.ProjectedCRS;
catch
end

end


%% =========================================================================
function mask = build_massif_mask_local(S,R,raster_size)
%BUILD_MASSIF_MASK_LOCAL Rasterize massif polygon on local DEM.

x = S.X;
y = S.Y;

valid = isfinite(x) & isfinite(y);

x = x(valid);
y = y(valid);

[col,row] = worldToIntrinsic(R,x,y);

mask = poly2mask( ...
    col, ...
    row, ...
    raster_size(1), ...
    raster_size(2));

end


%% =========================================================================
function mask_out = reduce_test_mask(mask,test_size)
%REDUCE_TEST_MASK Keep a central test region.

[row,col] = find(mask);

if isempty(row)

    mask_out = mask;
    return

end

r0 = round(median(row));
c0 = round(median(col));

half_size = floor(test_size/2);

r1 = max(1,r0-half_size);
r2 = min(size(mask,1),r0+half_size);

c1 = max(1,c0-half_size);
c2 = min(size(mask,2),c0+half_size);

mask_out = false(size(mask));

mask_out(r1:r2,c1:c2) = ...
    mask(r1:r2,c1:c2);

end


%% =========================================================================
function SVF = compute_svf_raycast( ...
    Z,target_mask,SLOPE,ASPECT, ...
    dx,dy,azimuths,max_distance,use_parallel)
%COMPUTE_SVF_RAYCAST
% Horizon-based SVF calculation.
%
% Parallelization strategy:
%   - Split target pixels into independent blocks.
%   - Each worker processes one complete block.
%   - Azimuths remain serial inside each worker.
%
% This avoids the parfor variable-classification problem associated with
% repeatedly modifying a shared SVF_values array.

% -------------------------------------------------------------------------
% Find valid target pixels
% -------------------------------------------------------------------------

[row,col] = find(target_mask);

target_index = sub2ind(size(Z),row,col);

z0 = Z(target_index);

valid = isfinite(z0) & z0 > -9000;

row = row(valid);
col = col(valid);
z0  = z0(valid);

target_index = target_index(valid);

nTarget = numel(z0);

fprintf("Valid target pixels: %d\n",nTarget)

if nTarget == 0
    error("No valid target pixels.")
end

% -------------------------------------------------------------------------
% Ray settings
% -------------------------------------------------------------------------

ray_step = min(dx,dy);
nSteps   = ceil(max_distance / ray_step);

azimuths = double(azimuths(:));
nBins    = numel(azimuths);

fprintf("\n")
fprintf("============================================================\n")
fprintf("SVF RAY-TRACING PARALLELIZATION\n")
fprintf("============================================================\n")
fprintf("Target pixels : %d\n",nTarget)
fprintf("Azimuth bins  : %d\n",nBins)
fprintf("Azimuth step  : %.1f deg\n",360/nBins)
fprintf("Ray step      : %.1f m\n",ray_step)
fprintf("Ray steps     : %d\n",nSteps)
fprintf("Max distance  : %.1f m\n",max_distance)
fprintf("============================================================\n")

% -------------------------------------------------------------------------
% Slope and aspect
% -------------------------------------------------------------------------

slope_deg  = double(SLOPE(target_index));
aspect_deg = double(ASPECT(target_index));

slope_rad  = deg2rad(slope_deg);
aspect_rad = deg2rad(aspect_deg);

% -------------------------------------------------------------------------
% Number of blocks
% -------------------------------------------------------------------------
%
% We want reasonably large blocks so that workers spend most of their
% time doing ray tracing rather than scheduling tiny jobs.
%
% 6 workers -> approximately 12 blocks gives some load balancing.
% -------------------------------------------------------------------------

if use_parallel

    pool = gcp("nocreate");

    if isempty(pool)
        pool = parpool("Processes");
    end

    nWorkers = pool.NumWorkers;

else

    nWorkers = 1;

end

nBlocks = max( ...
    nWorkers, ...
    min(4*nWorkers,nTarget));

block_edges = round(linspace(0,nTarget,nBlocks+1));

fprintf("Parallel workers: %d\n",nWorkers)
fprintf("Target blocks   : %d\n",nBlocks)

% -------------------------------------------------------------------------
% Preallocate final SVF values
% -------------------------------------------------------------------------

SVF_values = NaN(nTarget,1);

% -------------------------------------------------------------------------
% Process target blocks
% -------------------------------------------------------------------------

tic

if use_parallel && nWorkers > 1

    % Each worker returns one independent result.
    % Nothing is written into SVF_values inside parfor.

    SVF_blocks = cell(nBlocks,1);

    parfor iblock = 1:nBlocks

        i1 = block_edges(iblock) + 1;
        i2 = block_edges(iblock + 1);

        if i2 < i1
            SVF_blocks{iblock} = zeros(0,1);
            continue
        end

        rows_b = row(i1:i2);
        cols_b = col(i1:i2);
        z0_b   = z0(i1:i2);

        slope_b  = slope_rad(i1:i2);
        aspect_b = aspect_rad(i1:i2);

        nBlock = i2-i1+1;

        qIntegrand_b = zeros(nBlock,nBins,"double");

        for iaz = 1:nBins

            azimuth = azimuths(iaz);

            horizon = compute_target_horizon( ...
                Z, ...
                rows_b, ...
                cols_b, ...
                z0_b, ...
                dx, ...
                dy, ...
                azimuth, ...
                nSteps, ...
                max_distance);

            horizon = double(horizon);

            H = deg2rad(90-horizon);

            daz = deg2rad(azimuth)-aspect_b;

            t = cos(daz) < 0;

            if any(t)

                argument = ...
                    1 - 1 ./ ...
                    ( ...
                        1 + ...
                        tan(slope_b(t)).^2 .* ...
                        cos(daz(t)).^2 ...
                    );

                argument = max(0,min(1,argument));

                H(t) = min( ...
                    H(t), ...
                    acos(sqrt(argument)));

            end

            q = ( ...
                cos(slope_b).*sin(H).^2 + ...
                sin(slope_b).*cos(daz).* ...
                (H-cos(H).*sin(H)) ...
                ) ./ 2;

            invalid = ...
                ~isfinite(slope_b) | ...
                ~isfinite(aspect_b) | ...
                ~isfinite(H);

            q(invalid) = NaN;

            qIntegrand_b(:,iaz) = q;

        end

        azimuth_rad = deg2rad(azimuths(:).');

        azimuth_rad_closed = ...
            [azimuth_rad,2*pi];

        q_closed = ...
            [qIntegrand_b,qIntegrand_b(:,1)];

        block_svf = trapz( ...
            azimuth_rad_closed, ...
            q_closed, ...
            2) ./ pi;

        SVF_blocks{iblock} = block_svf;

    end

    % -------------------------------------------------------------
    % Assemble results AFTER parfor
    % -------------------------------------------------------------

    SVF_values = vertcat(SVF_blocks{:});

else

    % ---------------------------------------------------------------------
    % Serial fallback
    % ---------------------------------------------------------------------

    for iblock = 1:nBlocks

        i1 = block_edges(iblock)+1;
        i2 = block_edges(iblock+1);

        rows_b = row(i1:i2);
        cols_b = col(i1:i2);
        z0_b   = z0(i1:i2);

        slope_b  = slope_rad(i1:i2);
        aspect_b = aspect_rad(i1:i2);

        nBlock = i2-i1+1;

        qIntegrand_b = zeros(nBlock,nBins,"double");

        for iaz = 1:nBins

            azimuth = azimuths(iaz);

            horizon = compute_target_horizon( ...
                Z, ...
                rows_b, ...
                cols_b, ...
                z0_b, ...
                dx, ...
                dy, ...
                azimuth, ...
                nSteps, ...
                max_distance);

            horizon = double(horizon);

            H = deg2rad(90-horizon);

            daz = deg2rad(azimuth)-aspect_b;

            t = cos(daz) < 0;

            if any(t)

                argument = ...
                    1 - 1 ./ ...
                    ( ...
                        1 + ...
                        tan(slope_b(t)).^2 .* ...
                        cos(daz(t)).^2 ...
                    );

                argument = max(0,min(1,argument));

                H(t) = min( ...
                    H(t), ...
                    acos(sqrt(argument)));

            end

            q = ( ...
                cos(slope_b).*sin(H).^2 + ...
                sin(slope_b).*cos(daz).* ...
                (H-cos(H).*sin(H)) ...
                ) ./ 2;

            q( ...
                ~isfinite(slope_deg(i1:i2)) | ...
                ~isfinite(aspect_deg(i1:i2)) | ...
                ~isfinite(H)) = NaN;

            qIntegrand_b(:,iaz) = q;

        end

        azimuth_rad = deg2rad(azimuths(:).');

        azimuth_rad_closed = [azimuth_rad,2*pi];

        q_closed = [ ...
            qIntegrand_b, ...
            qIntegrand_b(:,1)];

        SVF_values(i1:i2) = trapz( ...
            azimuth_rad_closed, ...
            q_closed, ...
            2) ./ pi;

    end

end

elapsed_raytrace = toc;

fprintf("\nRay-tracing elapsed time: %.2f minutes\n", ...
    elapsed_raytrace/60)

% -------------------------------------------------------------------------
% Output raster
% -------------------------------------------------------------------------

SVF = NaN(size(Z),"single");

SVF(target_index) = single(SVF_values);

% -------------------------------------------------------------------------
% Physical bounds
% -------------------------------------------------------------------------

SVF(SVF < 0) = 0;
SVF(SVF > 1) = 1;

% -------------------------------------------------------------------------
% Diagnostics
% -------------------------------------------------------------------------

valid_svf = SVF_values(isfinite(SVF_values));

fprintf("\n")
fprintf("## SVF diagnostics\n")
fprintf("\n")
fprintf("Elapsed time : %.2f minutes\n",elapsed_raytrace/60)
fprintf("Valid pixels : %d\n",numel(valid_svf))

if ~isempty(valid_svf)

    fprintf("Minimum SVF  : %.5f\n",min(valid_svf))
    fprintf("Maximum SVF  : %.5f\n",max(valid_svf))
    fprintf("Mean SVF     : %.5f\n",mean(valid_svf))
    fprintf("Median SVF   : %.5f\n",median(valid_svf))

end

end


%% =========================================================================
function SVF_block = compute_svf_block( ...
    Z,row,col,z0, ...
    slope_rad,slope_deg, ...
    aspect_rad,aspect_deg, ...
    dx,dy,azimuths,nSteps,max_distance)
%COMPUTE_SVF_BLOCK Compute SVF for one target-pixel block.
%
% No qIntegrand matrix is stored.
% Azimuth contributions are accumulated directly.

nTarget = numel(z0);
nBins   = numel(azimuths);

% -------------------------------------------------------------------------
% Accumulated azimuth integral
% -------------------------------------------------------------------------

q_sum = zeros(nTarget,1,"double");

% -------------------------------------------------------------------------
% Process azimuths
% -------------------------------------------------------------------------

for ib = 1:nBins

    azimuth = azimuths(ib);

    % -------------------------------------------------------------
    % Terrain horizon
    % -------------------------------------------------------------

    horizon = compute_target_horizon( ...
        Z, ...
        row, ...
        col, ...
        z0, ...
        dx, ...
        dy, ...
        azimuth, ...
        nSteps, ...
        max_distance);

    horizon = double(horizon);

    % -------------------------------------------------------------
    % Horizon opening angle
    % -------------------------------------------------------------

    H = deg2rad(90 - horizon);

    % -------------------------------------------------------------
    % Azimuth difference relative to surface aspect
    % -------------------------------------------------------------

    daz = deg2rad(azimuth) - aspect_rad;

    % -------------------------------------------------------------
    % Limit visible sky for a sloping surface
    % -------------------------------------------------------------

    t = cos(daz) < 0;

    if any(t)

        argument = ...
            1 - 1 ./ ...
            ( ...
                1 + ...
                tan(slope_rad(t)).^2 .* ...
                cos(daz(t)).^2 ...
            );

        argument = max(0,min(1,argument));

        H(t) = min( ...
            H(t), ...
            acos(sqrt(argument)) ...
        );

    end

    % -------------------------------------------------------------
    % CryoGrid/GIS SVF integrand
    % -------------------------------------------------------------

    q = ( ...
        cos(slope_rad).*sin(H).^2 + ...
        sin(slope_rad).*cos(daz).* ...
        (H - cos(H).*sin(H)) ...
        ) ./ 2;

    % -------------------------------------------------------------
    % Invalid pixels
    % -------------------------------------------------------------

    q( ...
        ~isfinite(slope_deg) | ...
        ~isfinite(aspect_deg) | ...
        ~isfinite(H)) = NaN;

    % -------------------------------------------------------------
    % Accumulate
    % -------------------------------------------------------------

    q_sum = q_sum + q;

end

% -------------------------------------------------------------------------
% Periodic trapezoidal integration
%
% For uniformly spaced azimuths with the first point repeated at 360°:
%
%   integral(q dphi) = dphi * sum(q)
%
% and:
%
%   SVF = integral / pi
%
% Since dphi = 2*pi/nBins:
%
%   SVF = 2/nBins * sum(q)
% -------------------------------------------------------------------------

SVF_block = ...
    (2 / nBins) .* q_sum;

% -------------------------------------------------------------------------
% Physical bounds
% -------------------------------------------------------------------------

SVF_block(SVF_block < 0) = 0;
SVF_block(SVF_block > 1) = 1;

end


%% =========================================================================
function SVF_values = compute_svf_target_chunk( ...
    Z,row,col,z0, ...
    slope_rad,slope_deg, ...
    aspect_rad,aspect_deg, ...
    dx,dy, ...
    azimuths,azimuth_rad, ...
    nSteps,max_distance)
%COMPUTE_SVF_TARGET_CHUNK
% Compute SVF for one chunk of target pixels.
%
% The azimuth integral is accumulated directly.
% No target x azimuth qIntegrand matrix is created.

nTarget = numel(z0);
nBins   = numel(azimuths);

% Accumulated azimuth integral.
%
% We will integrate q d(azimuth) using the trapezoidal rule.
integral_q = zeros(nTarget,1);

% -------------------------------------------------------------------------
% Loop over azimuths
% -------------------------------------------------------------------------

for ib = 1:nBins

    azimuth = azimuths(ib);

    % -------------------------------------------------------------
    % Terrain horizon
    % -------------------------------------------------------------

    horizon = compute_target_horizon( ...
        Z, ...
        row, ...
        col, ...
        z0, ...
        dx, ...
        dy, ...
        azimuth, ...
        nSteps, ...
        max_distance);

    horizon = double(horizon);

    % -------------------------------------------------------------
    % Convert horizon elevation angle to sky opening angle
    % -------------------------------------------------------------

    H = deg2rad(90 - horizon);

    % -------------------------------------------------------------
    % Azimuth difference relative to surface aspect
    % -------------------------------------------------------------

    daz = azimuth_rad(ib) - aspect_rad;

    % -------------------------------------------------------------
    % Limit visible sky for a sloping surface
    % -------------------------------------------------------------

    t = cos(daz) < 0;

    if any(t)

        argument = ...
            1 - 1 ./ ...
            ( ...
                1 + ...
                tan(slope_rad(t)).^2 .* ...
                cos(daz(t)).^2 ...
            );

        argument = max(0,min(1,argument));

        H(t) = min( ...
            H(t), ...
            acos(sqrt(argument)) ...
        );

    end

    % -------------------------------------------------------------
    % CryoGrid/GIS SVF integrand
    % -------------------------------------------------------------

    q = ( ...
        cos(slope_rad).*sin(H).^2 + ...
        sin(slope_rad).*cos(daz).* ...
        (H - cos(H).*sin(H)) ...
        ) ./ 2;

    % -------------------------------------------------------------
    % Invalid pixels
    % -------------------------------------------------------------

    q( ...
        ~isfinite(slope_deg) | ...
        ~isfinite(aspect_deg) | ...
        ~isfinite(H)) = NaN;

    % -------------------------------------------------------------
    % Accumulate trapezoidal azimuth integral
    %
    % For a periodic grid:
    %
    %   integral ≈ sum( (q_i + q_{i+1})/2 * dAz )
    %
    % with q_36 connected back to q_1.
    % -------------------------------------------------------------

    if ib == 1

        q_first = q;

    else

        dAz = azimuth_rad(ib) - azimuth_rad(ib-1);

        integral_q = integral_q + ...
            0.5 .* (q_previous + q) .* dAz;

    end

    q_previous = q;

end

% -------------------------------------------------------------------------
% Close the periodic azimuth interval
% -------------------------------------------------------------------------

dAz = 2*pi - azimuth_rad(end);

integral_q = integral_q + ...
    0.5 .* (q_previous + q_first) .* dAz;

% -------------------------------------------------------------------------
% Normalize by pi
% -------------------------------------------------------------------------

SVF_values = integral_q ./ pi;

end

%% =========================================================================
function horizon = compute_target_horizon( ...
    Z,row,col,z0,dx,dy,azimuth,nSteps,max_distance)
%COMPUTE_TARGET_HORIZON
% Ray-trace terrain horizon for all target pixels at one azimuth.
%
% Optimizations:
%   1. Precompute continuous ray offsets.
%   2. Preserve the original rounding operation:
%
%          round(row + continuous_offset)
%
%      rather than:
%
%          row + round(continuous_offset)
%
%   3. Remove consecutive duplicate raster positions along the ray.
%
% The first occurrence of each raster position is retained, so the
% corresponding distance is also retained.

nRows = size(Z,1);
nCols = size(Z,2);

% -------------------------------------------------------------------------
% Azimuth clockwise from North
% -------------------------------------------------------------------------

theta = deg2rad(azimuth);

dx_ray = sin(theta);
dy_ray = cos(theta);

% -------------------------------------------------------------------------
% Ray sampling
% -------------------------------------------------------------------------

step_distance = min(dx,dy);

nSteps = min( ...
    nSteps, ...
    floor(max_distance / step_distance));

distance_all = (1:nSteps)' * step_distance;

% -------------------------------------------------------------------------
% Continuous raster offsets
%
% IMPORTANT:
% These are NOT rounded here.
%
% We must preserve the original operation:
%
%   rr = row - y/dy;
%   cc = col + x/dx;
%   r  = round(rr);
%   c  = round(cc);
%
% -------------------------------------------------------------------------

dRow = -distance_all .* dy_ray ./ dy;
dCol =  distance_all .* dx_ray ./ dx;

% -------------------------------------------------------------------------
% Remove consecutive duplicate offsets
%
% This only removes redundant samples where the ray remains in the same
% raster cell for multiple consecutive 10 m steps.
%
% We retain the FIRST occurrence, therefore retaining the smallest
% distance associated with that raster cell.
% -------------------------------------------------------------------------

r_offset = round(dRow);
c_offset = round(dCol);

keep = true(nSteps,1);

if nSteps > 1

    keep(2:end) = ...
        r_offset(2:end) ~= r_offset(1:end-1) | ...
        c_offset(2:end) ~= c_offset(1:end-1);

end

distance = distance_all(keep);
dRow     = dRow(keep);
dCol     = dCol(keep);

nRay = numel(distance);

% -------------------------------------------------------------------------
% Diagnostics
% -------------------------------------------------------------------------

% Uncomment temporarily if desired:
%
% fprintf("  Ray samples: %d -> %d\n",nSteps,nRay)

% -------------------------------------------------------------------------
% One horizon value for every target pixel
% -------------------------------------------------------------------------

nTarget = numel(row);

horizon = zeros(nTarget,1,"single");

% -------------------------------------------------------------------------
% Ray tracing
% -------------------------------------------------------------------------

for k = 1:nRay

    % -------------------------------------------------------------
    % EXACT ORIGINAL ROUNDING
    %
    % Continuous displacement is added to each target coordinate
    % BEFORE rounding.
    % -------------------------------------------------------------

    r = round(row + dRow(k));
    c = round(col + dCol(k));

    % -------------------------------------------------------------
    % Pixels whose ray is still inside the DEM
    % -------------------------------------------------------------

    inside = ...
        r >= 1 & r <= nRows & ...
        c >= 1 & c <= nCols;

    if ~any(inside)
        break
    end

    target_ids = find(inside);

    r_inside = r(inside);
    c_inside = c(inside);

    % -------------------------------------------------------------
    % DEM lookup
    % -------------------------------------------------------------

    ind = sub2ind( ...
        [nRows,nCols], ...
        r_inside, ...
        c_inside);

    z = Z(ind);

    % -------------------------------------------------------------
    % Valid DEM values
    % -------------------------------------------------------------

    valid = isfinite(z) & z > -9000;

    if ~any(valid)
        continue
    end

    target_ids = target_ids(valid);
    z = z(valid);

    % -------------------------------------------------------------
    % Elevation angle
    % -------------------------------------------------------------

    angle = atan2d( ...
        z - z0(target_ids), ...
        distance(k));

    % -------------------------------------------------------------
    % Update horizon
    % -------------------------------------------------------------

    horizon(target_ids) = max( ...
        horizon(target_ids), ...
        single(angle));

end

end


%% =========================================================================
function write_svf_geotiff(filename,SVF,R)
%WRITE_SVF_GEOTIFF Write SVF raster with projected CRS metadata.

% The Alpine DEM uses Lambert-93 / EPSG:2154.
geotiffwrite( ...
    filename, ...
    SVF, ...
    R, ...
    "CoordRefSysCode",2154);

end


%% =========================================================================
function [horizon,distances,elevations] = debug_target_ray( ...
    Z,row,col,z0,dx,dy,azimuth,nSteps,max_distance)
%DEBUG_TARGET_RAY Inspect one DEM ray used for horizon calculation.

[nRows,nCols] = size(Z);

theta = deg2rad(azimuth);

% DEM orientation:
%   rows    -> west to east
%   columns -> south to north
%
% Azimuth is clockwise from North:
%   0°   = North
%   90°  = East
%   180° = South
%   270° = West

dr = sin(theta);
dc = -cos(theta);

distances = [];
elevations = [];

horizon = 0;

for k = 1:nSteps

    distance = k * min(dx,dy);

    if distance > max_distance
        break
    end

    rr = row + k*dr;
    cc = col + k*dc;

    if rr < 1 || rr > nRows || cc < 1 || cc > nCols
        break
    end

    r0 = floor(rr);
    c0 = floor(cc);

    r1 = min(r0+1,nRows);
    c1 = min(c0+1,nCols);

    wr = rr-r0;
    wc = cc-c0;

    i00 = sub2ind([nRows,nCols],r0,c0);
    i01 = sub2ind([nRows,nCols],r0,c1);
    i10 = sub2ind([nRows,nCols],r1,c0);
    i11 = sub2ind([nRows,nCols],r1,c1);

    z00 = Z(i00);
    z01 = Z(i01);
    z10 = Z(i10);
    z11 = Z(i11);

    z = ...
        (1-wr).*(1-wc).*z00 + ...
        (1-wr).*wc.*z01 + ...
        wr.*(1-wc).*z10 + ...
        wr.*wc.*z11;

    if ~isfinite(z) || z <= -9000
        continue
    end

    distances(end+1,1) = distance;
    elevations(end+1,1) = z;

    angle = atan2d(z-z0,distance);

    horizon = max(horizon,angle);

end

end