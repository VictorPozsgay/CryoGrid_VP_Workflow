function interpolate_ERA5_to_massifs(era5_path, safran_path)
%INTERPOLATE_ERA5_TO_MASSIFS Interpolate ERA5 TOA radiation to SAFRAN massifs.
%
% DESCRIPTION
%   Performs bilinear interpolation of ERA5 top-of-atmosphere (TOA)
%   incoming shortwave radiation (S_TOA) onto the centroid of each SAFRAN
%   massif.
%
%   ERA5 TOA data are loaded from the merged ERA5 dataset and interpolated
%   spatially using MATLAB griddedInterpolant.
%
%   The ERA5 variable used here is:
%
%       S_TOA : W m^-2
%
%   obtained previously from ERA5 accumulated total incoming solar radiation
%   (tisr, J m^-2) divided by the hourly timestep (3600 s).
%
%   The resulting time series are stored for each SAFRAN massif in:
%
%       ERA5/per_massif/TOA_per_massif.mat
%
%   Each structure element contains:
%
%       • SAFRAN massif metadata
%       • interpolated ERA5 TOA radiation
%       • ERA5 time vector
%
%
% INPUTS
%   era5_path
%       Path to:
%
%           ERA5/
%
%       containing:
%
%           merged/
%               ERA5_TOA_all.mat
%
%           per_massif/
%
%   safran_path
%       Path to SAFRAN directory containing massif information.
%
%
% OUTPUT
%   Creates:
%
%       ERA5/per_massif/TOA_per_massif.mat
%
%   containing one ERA5 TOA time series per SAFRAN massif.
%
%
% NOTES
%   - ERA5 longitude/latitude coordinates are assumed to be regular.
%   - Latitude ordering is corrected if ERA5 latitude is decreasing.
%
%
% SEE ALSO
%   PREPARE_FORCING, BUILD_ERA5_TOA, READ_SAFRAN_MASSIFS.


%% ========================================================================
% Paths
% ========================================================================

input_file = fullfile(era5_path,...
    "merged","ERA5_TOA_all.mat");

output_folder = fullfile(era5_path,...
    "per_massif");

output_file = fullfile(output_folder,...
    "TOA_per_massif.mat");


if ~isfile(input_file)
    error("Missing ERA5 merged file: %s",input_file)
end

if ~isfolder(output_folder)
    mkdir(output_folder)
end


if isfile(output_file)
    fprintf('ERA5 TOA per massif file already exists.\n')
    fprintf('Skipping interpolate_ERA5_to_massifs().\n')
    return
end


%% ========================================================================
% Read SAFRAN massif coordinates
% ========================================================================

S = read_SAFRAN_massifs(safran_path);

lat_p = [S.lat]';
lon_p = [S.lon]';

Np = numel(lat_p);


%% ========================================================================
% Load ERA5 TOA dataset
% ========================================================================

data = load(input_file,'ERA5');

ERA5 = data.ERA5;


%% ========================================================================
% Prepare interpolation grid
% ========================================================================

% ERA5 latitude is sometimes decreasing.
% griddedInterpolant requires monotonic coordinates.

[lat,idx_lat] = sort(ERA5.lat);

lon = ERA5.lon;

Nt = size(ERA5.S_TOA,3);


%% ========================================================================
% Interpolate all time steps
% ========================================================================

fprintf('Interpolating ERA5 TOA (%d time steps) onto %d massifs.\n',...
    Nt,Np)


out = zeros(Np,Nt,'single');


F = griddedInterpolant( ...
    {lon,lat}, ...
    ERA5.S_TOA(:,idx_lat,1), ...
    'linear');


for t = 1:Nt

    field = ERA5.S_TOA(:,:,t);

    % Reorder latitude dimension
    F.Values = field(:,idx_lat);

    out(:,t) = single(F(lon_p,lat_p));

end


%% ========================================================================
% Store results
% ========================================================================

for i = 1:Np

    % Keep field name for compatibility with merge_SAFRAN_ERA5_individual
    S(i).TOA = out(i,:)';

    S(i).TOA_time = ERA5.time;

end


save(output_file,'S','-v7.3')

fprintf('Saved: %s\n',output_file)

end