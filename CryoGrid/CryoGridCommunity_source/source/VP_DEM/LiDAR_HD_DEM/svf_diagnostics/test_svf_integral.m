%% TEST_SVF_INTEGRAL
%
% Validate the SVF integration independently of the DEM/ray tracer.
%
% Standard GIS convention:
%   North = 0 deg
%   East  = 90 deg
%   South = 180 deg
%   West = 270 deg

clear
clc

%% Azimuth discretization

NumBins = 360;

azimuths = (0:NumBins-1) * 360/NumBins;
azimuth_rad = deg2rad(azimuths);

%% ==============================================================
% TEST 1: FLAT SURFACE, COMPLETELY OPEN SKY
% ==============================================================

slope_deg = zeros(1,NumBins);
aspect_deg = zeros(1,NumBins);
horizon_deg = zeros(1,NumBins);

SVF = compute_test_svf( ...
    slope_deg, ...
    aspect_deg, ...
    horizon_deg, ...
    azimuths);

fprintf("\nTEST 1: Flat + open sky\n")
fprintf("Expected SVF = 1.00000\n")
fprintf("Obtained SVF = %.5f\n",SVF)


%% ==============================================================
% TEST 2: FLAT SURFACE, 15 DEGREE HORIZON EVERYWHERE
% ==============================================================

slope_deg = zeros(1,NumBins);
aspect_deg = zeros(1,NumBins);
horizon_deg = 15*ones(1,NumBins);

SVF = compute_test_svf( ...
    slope_deg, ...
    aspect_deg, ...
    horizon_deg, ...
    azimuths);

fprintf("\nTEST 2: Flat + 15 degree horizon\n")
fprintf("Expected SVF = %.5f\n",sind(75)^2)
fprintf("Obtained SVF = %.5f\n",SVF)


%% ==============================================================
% TEST 3: VERTICAL WALL + OPEN SKY
% ==============================================================

slope_deg = 90*ones(1,NumBins);
aspect_deg = zeros(1,NumBins);
horizon_deg = zeros(1,NumBins);

SVF = compute_test_svf( ...
    slope_deg, ...
    aspect_deg, ...
    horizon_deg, ...
    azimuths);

fprintf("\nTEST 3: Vertical wall + open sky\n")
fprintf("Expected SVF = 0.50000\n")
fprintf("Obtained SVF = %.5f\n",SVF)


%% ==============================================================
% TEST 4: 30 DEGREE SLOPE + OPEN SKY
% ==============================================================

slope_deg = 30*ones(1,NumBins);
aspect_deg = zeros(1,NumBins);
horizon_deg = zeros(1,NumBins);

SVF = compute_test_svf( ...
    slope_deg, ...
    aspect_deg, ...
    horizon_deg, ...
    azimuths);

fprintf("\nTEST 4: 30 degree slope + open sky\n")
fprintf("Expected SVF = %.5f\n",(1+cosd(30))/2)
fprintf("Obtained SVF = %.5f\n",SVF)


%% ==============================================================
% LOCAL FUNCTION
% ==============================================================

function SVF = compute_test_svf( ...
    slope_deg, ...
    aspect_deg, ...
    horizon_deg, ...
    azimuths)

    slope_deg = double(slope_deg);
    aspect_deg = double(aspect_deg);
    horizon_deg = double(horizon_deg);
    azimuths = double(azimuths);

    %% Horizon elevation -> zenith angle

    H = deg2rad(90 - horizon_deg);

    slope_rad = deg2rad(slope_deg);
    aspect_rad = deg2rad(aspect_deg);
    azimuth_rad = deg2rad(azimuths);

    %% Angular difference
    %
    % Standard GIS convention:
    %   aspect = downslope direction
    %   azimuth = direction toward the horizon
    %
    % Both are measured clockwise from North.
    
    daz = azimuth_rad - aspect_rad;
    
    %% Limit the visible sky for a sloping surface
    %
    % For directions toward the upslope side, the terrain surface itself
    % blocks part of the geometrical sky hemisphere.
    %
    % The limiting zenith angle is derived from the intersection of the
    % horizontal sky hemisphere with the inclined receiving plane.
    
    t = cos(daz) < 0;
    
    H(t) = min(H(t), ...
        acos( ...
            sqrt( ...
                1 - 1 ./ ...
                ( ...
                    1 + ...
                    tan(slope_rad(t)).^2 .* cos(daz(t)).^2 ...
                ) ...
            ) ...
        ) ...
    );
    
    %% SVF integrand

    q = ( ...
        cos(slope_rad).*sin(H).^2 + ...
        sin(slope_rad).*cos(daz).* ...
        (H - cos(H).*sin(H)) ...
        ) ./ 2;

    %% No negative contribution

    q(q < 0) = 0;

    %% Integrate over azimuth
    
    azimuth_rad_closed = [azimuth_rad, 2*pi];
    q_closed = [q, q(1)];
    
    SVF = trapz( ...
        azimuth_rad_closed, ...
        q_closed) ./ pi;

end