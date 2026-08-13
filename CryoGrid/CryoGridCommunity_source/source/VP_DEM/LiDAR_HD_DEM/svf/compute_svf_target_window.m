function SVF = compute_svf_target_window( ...
    Z,target_mask,SLOPE,ASPECT, ...
    dx,dy,azimuths,max_distance,use_parallel)
%COMPUTE_SVF_TARGET_WINDOW
% Compute SVF for all valid target pixels in one calculation window.
%
% The target pixels are extracted from target_mask.
% DEM, slope and aspect validity are enforced consistently.
%
% The actual ray tracing is delegated to compute_svf_target_chunk().
%
% The output SVF has the same dimensions as Z.
% Valid target pixels receive SVF values.
% All other pixels remain NaN.

%% =========================================================================
% Find target pixels
% =========================================================================

[row,col] = find(target_mask);

if isempty(row)

    SVF = NaN(size(Z),"single");
    return

end

%% =========================================================================
% Convert target coordinates to linear indices
% =========================================================================

target_index = sub2ind(size(Z),row,col);

z0 = Z(target_index);

slope_deg  = double(SLOPE(target_index));
aspect_deg = double(ASPECT(target_index));

%% =========================================================================
% Keep only physically valid target pixels
% =========================================================================

valid = ...
    isfinite(z0) & ...
    isfinite(slope_deg) & ...
    isfinite(aspect_deg);

% IMPORTANT:
% Filter the target indices themselves here.
%
% Do not keep the original target_index and apply "valid" again later.
target_index = target_index(valid);

row = row(valid);
col = col(valid);

z0 = z0(valid);

slope_deg  = slope_deg(valid);
aspect_deg = aspect_deg(valid);

%% =========================================================================
% No valid pixels
% =========================================================================

if isempty(z0)

    SVF = NaN(size(Z),"single");
    return

end

%% =========================================================================
% Convert terrain angles to radians
% =========================================================================

slope_rad  = deg2rad(slope_deg);
aspect_rad = deg2rad(aspect_deg);

%% =========================================================================
% Number of target pixels
% =========================================================================

nTarget = numel(z0);

%% =========================================================================
% Determine parallel workers
% =========================================================================

if use_parallel

    pool = gcp("nocreate");

    if isempty(pool)

        pool = parpool("Processes");

    end

    nWorkers = pool.NumWorkers;

else

    nWorkers = 1;

end

%% =========================================================================
% Divide target pixels into blocks
% =========================================================================

nBlocks = min(4*nWorkers,nTarget);

nBlocks = max(1,nBlocks);

block_edges = round( ...
    linspace(0,nTarget,nBlocks+1));

%% =========================================================================
% Compute blocks
% =========================================================================

SVF_blocks = cell(nBlocks,1);

if use_parallel && nWorkers > 1

    parfor iblock = 1:nBlocks

        i1 = block_edges(iblock) + 1;
        i2 = block_edges(iblock + 1);

        if i2 < i1

            SVF_blocks{iblock} = zeros(0,1,"single");

        else

            SVF_blocks{iblock} = ...
                compute_svf_target_chunk( ...
                    Z, ...
                    row(i1:i2), ...
                    col(i1:i2), ...
                    z0(i1:i2), ...
                    slope_rad(i1:i2), ...
                    slope_deg(i1:i2), ...
                    aspect_rad(i1:i2), ...
                    aspect_deg(i1:i2), ...
                    dx,dy, ...
                    azimuths, ...
                    deg2rad(azimuths), ...
                    ceil(max_distance/min(dx,dy)), ...
                    max_distance);

        end

    end

else

    for iblock = 1:nBlocks

        i1 = block_edges(iblock) + 1;
        i2 = block_edges(iblock + 1);

        if i2 < i1

            SVF_blocks{iblock} = zeros(0,1,"single");

        else

            SVF_blocks{iblock} = ...
                compute_svf_target_chunk( ...
                    Z, ...
                    row(i1:i2), ...
                    col(i1:i2), ...
                    z0(i1:i2), ...
                    slope_rad(i1:i2), ...
                    slope_deg(i1:i2), ...
                    aspect_rad(i1:i2), ...
                    aspect_deg(i1:i2), ...
                    dx,dy, ...
                    azimuths, ...
                    deg2rad(azimuths), ...
                    ceil(max_distance/min(dx,dy)), ...
                    max_distance);

        end

    end

end

%% =========================================================================
% Assemble target values
% =========================================================================

SVF_values = vertcat(SVF_blocks{:});

%% =========================================================================
% Sanity check
% =========================================================================

if numel(SVF_values) ~= nTarget

    error( ...
        ["SVF target-count mismatch.\n" ...
         "Expected SVF values : %d\n" ...
         "Received SVF values : %d\n" ...
         "Valid target pixels : %d"], ...
        nTarget, ...
        numel(SVF_values), ...
        nTarget)

end

%% =========================================================================
% Insert values into output raster
% =========================================================================

SVF = NaN(size(Z),"single");

SVF(target_index) = single(SVF_values);

end