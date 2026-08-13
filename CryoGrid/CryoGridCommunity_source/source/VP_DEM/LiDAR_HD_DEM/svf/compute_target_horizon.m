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
