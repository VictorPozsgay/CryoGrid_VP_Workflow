function SVF_values = compute_svf_target_chunk( ...
    Z,row,col,z0, ...
    slope_rad,slope_deg, ...
    aspect_rad,aspect_deg, ...
    dx,dy, ...
    azimuths,azimuth_rad, ...
    nSteps,max_distance)
%COMPUTE_SVF_TARGET_CHUNK
% Compute SVF for one vectorized block of target pixels.
%
% The azimuth integral is accumulated directly.
% No target x azimuth qIntegrand matrix is created.
%
% Output:
%   SVF_values - nTarget x 1 single-precision SVF vector

%% =========================================================================
% Force all target vectors to column orientation
% =========================================================================

row        = row(:);
col        = col(:);
z0         = z0(:);

slope_rad  = slope_rad(:);
slope_deg  = slope_deg(:);

aspect_rad = aspect_rad(:);
aspect_deg = aspect_deg(:);

nTarget = numel(z0);
nBins   = numel(azimuths);

%% =========================================================================
% Validate target-vector dimensions
% =========================================================================

if numel(row) ~= nTarget || ...
   numel(col) ~= nTarget || ...
   numel(slope_rad) ~= nTarget || ...
   numel(slope_deg) ~= nTarget || ...
   numel(aspect_rad) ~= nTarget || ...
   numel(aspect_deg) ~= nTarget

    error( ...
        "Target-vector dimensions are inconsistent in " + ...
        "compute_svf_target_chunk().")

end

%% =========================================================================
% Accumulated azimuth integral
% =========================================================================

integral_q = zeros(nTarget,1);

%% =========================================================================
% Loop over azimuths
% =========================================================================

for ib = 1:nBins

    azimuth = azimuths(ib);

    % ---------------------------------------------------------------------
    % Terrain horizon
    % ---------------------------------------------------------------------

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

    % Force horizon to target-vector orientation.
    horizon = double(horizon(:));

    if numel(horizon) ~= nTarget

        error( ...
            "compute_target_horizon returned %d values for %d " + ...
            "target pixels.", ...
            numel(horizon),nTarget)

    end

    % ---------------------------------------------------------------------
    % Convert horizon elevation angle to sky opening angle
    % ---------------------------------------------------------------------

    H = deg2rad(90 - horizon);

    % ---------------------------------------------------------------------
    % Azimuth difference relative to surface aspect
    % ---------------------------------------------------------------------

    daz = azimuth_rad(ib) - aspect_rad;

    % ---------------------------------------------------------------------
    % Limit visible sky for a sloping surface
    % ---------------------------------------------------------------------

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

    % ---------------------------------------------------------------------
    % CryoGrid/GIS SVF integrand
    % ---------------------------------------------------------------------

    q = ( ...
        cos(slope_rad).*sin(H).^2 + ...
        sin(slope_rad).*cos(daz).* ...
        (H - cos(H).*sin(H)) ...
        ) ./ 2;

    % Force q to column orientation.
    q = q(:);

    % ---------------------------------------------------------------------
    % Validate q dimensions
    % ---------------------------------------------------------------------

    if numel(q) ~= nTarget

        error( ...
            "SVF integrand has %d values for %d target pixels.", ...
            numel(q),nTarget)

    end

    % ---------------------------------------------------------------------
    % Invalid pixels
    % ---------------------------------------------------------------------

    q( ...
        ~isfinite(slope_deg) | ...
        ~isfinite(aspect_deg) | ...
        ~isfinite(H)) = NaN;

    % ---------------------------------------------------------------------
    % Accumulate trapezoidal azimuth integral
    %
    % For a periodic grid:
    %
    %   integral ≈ sum((q_i + q_{i+1})/2 * dAz)
    %
    % with the last azimuth connected back to the first.
    % ---------------------------------------------------------------------

    if ib == 1

        q_first = q;

    else

        dAz = azimuth_rad(ib) - azimuth_rad(ib-1);

        integral_q = integral_q + ...
            0.5 .* (q_previous + q) .* dAz;

    end

    q_previous = q;

end

%% =========================================================================
% Close the periodic azimuth interval
% =========================================================================

dAz = 2*pi - azimuth_rad(end);

integral_q = integral_q + ...
    0.5 .* (q_previous + q_first) .* dAz;

%% =========================================================================
% Normalize by pi
% =========================================================================

SVF_values = integral_q ./ pi;

% Guarantee required output orientation and type.
SVF_values = single(SVF_values(:));

end