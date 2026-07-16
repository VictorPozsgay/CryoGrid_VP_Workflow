function DEM = compute_dem_metrics(DEM)
%COMPUTE_DEM_METRICS Compute terrain parameters from DEM.
%
% Adds:
%   DEM.slope_deg
%   DEM.aspect_deg
%
%
% INPUT
%   DEM
%       DEM structure containing:
%           Z
%           R
%
% OUTPUT
%   DEM
%       Updated DEM structure
% 


%% Extract DEM

Z = double(DEM.Z);
R = DEM.R;

%% Grid spacing

dx = R.CellExtentInWorldX;
dy = R.CellExtentInWorldY;

%% Compute gradients

[dZdy,dZdx] = gradient(Z,dy,dx);

%% Slope

slope_rad = atan(sqrt(dZdx.^2 + dZdy.^2));
DEM.slope_deg = single(rad2deg(slope_rad));

%% Aspect

aspect_rad = atan2(dZdx,-dZdy);
aspect_deg = rad2deg(aspect_rad);
aspect_deg(aspect_deg < 0) = aspect_deg(aspect_deg < 0) + 360;
DEM.aspect_deg = single(aspect_deg);

%% Mask outside massif

outside = isnan(DEM.Z);

DEM.slope_deg(outside) = NaN;
DEM.aspect_deg(outside) = NaN;

%% Metadata

DEM.metrics_computed = true;
DEM.metrics_date = datetime("now");
DEM.metrics_version = "v1";

end