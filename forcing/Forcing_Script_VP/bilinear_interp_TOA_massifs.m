function bilinear_interp_TOA_massifs(era_path, safran_path)
%BILINEAR_INTERP_TOA_MASSIFS Interpolate ERA5 TOA onto SAFRAN massifs.
%
% DESCRIPTION
%   Performs bilinear interpolation of ERA5 TOA (tisr) onto SAFRAN
%   massif centroids. Latitude is sorted internally to ensure compatibility
%   with griddedInterpolant.
%
%   The result is stored per massif in:
%
%       TOA_per_massif.mat
%
%   Each S(i) contains:
%       S(i).TOA
%       S(i).TOA_time
%       + original SAFRAN spatial metadata
%
% INPUTS
%   era_path    Path containing ERA5_TOA_all.mat
%   safran_path Path used to build massif coordinates
%
% OUTPUT
%   Saves TOA_per_massif.mat in era_path/per_massif/
%
% See also merge_TOA, griddedInterpolant.

if isfile(fullfile(era_path, "per_massif/", 'TOA_per_massif.mat'))
    fprintf('The TOA_per_massif.mat file already exists. Skipping.\n');
    return
end

S = safran_massif_to_coord(safran_path);

data = load(fullfile(era_path, "raw\", "ERA5_TOA_all.mat"));

lat_p = [S.lat]';
lon_p = [S.lon]';
Np = numel(lat_p);

% -------------------------
% SORT GRID (IMPORTANT FIX)
% -------------------------
[lat, idx_lat] = sort(data.ERA5.lat);
lon = data.ERA5.lon;

Nt = size(data.ERA5.tisr,3);
out = zeros(Np, Nt);

% reorder first time slice for initialization
F = griddedInterpolant({lon, lat}, ...
                       data.ERA5.tisr(:,idx_lat,1), ...
                       'linear');

for t = 1:Nt
    field = data.ERA5.tisr(:,:,t);
    % reorder latitude dimension
    F.Values = field(:, idx_lat);
    out(:,t) = F(lon_p, lat_p);
end

% Store directly into the structure
for i = 1:Np
    S(i).TOA = out(i, :)';    % column vector [Nt x 1]
    S(i).TOA_time = data.ERA5.time;
end

save(fullfile(era_path, "per_massif/", 'TOA_per_massif.mat'),'S','-v7.3')

end
