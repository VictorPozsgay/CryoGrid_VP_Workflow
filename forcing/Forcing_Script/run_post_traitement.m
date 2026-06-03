function run_post_traitement(ttab_filepath,massif_nume, eleva, capteur_name)

% Step 1: Load and interpolate TOA data
load('TOA_ttab.mat');  % loads TT_TOA

% Sort the timetable by time
TT_TOA = sortrows(TT_TOA);

% Remove duplicate times — keep first occurrence
[~, unique_idx] = unique(TT_TOA.time_dt);
TT_TOA = TT_TOA(unique_idx, :);

% Create hourly time vector
time_hourly = (min(TT_TOA.time_dt):hours(1):max(TT_TOA.time_dt))';

% Interpolate to hourly resolution
TOA_hourly = retime(TT_TOA, time_hourly, 'linear');

% Rename variable
TOA_hourly.Properties.VariableNames = {'S_TOA'};


%% Step 2: Load ttab_safran.mat and crop to overlapping time span
load(ttab_filepath);  % loads t_span, Tair, Lin, etc.

% Convert t_span (datetime array) to timetable for easy merging
% ttab_safran = timetable(t_span, Lin, Sin, q, wind, rainfall, snowfall, Tair, p);

% Define crop time range
start_time = min(ttab_safran.t_span);
end_time   = max(ttab_safran.t_span);

% Crop both to common time range
TOA_hourly_crop = TOA_hourly(timerange(start_time, end_time), :);
%ttab_crop = ttab_safran(timerange(start_time, end_time), :);

% Ensure time alignment
ttab_merged = synchronize(ttab_safran, TOA_hourly_crop, 'first', 'nearest');

%% Conserver uniquement les lignes à 3h d'intervalle
time_vec = ttab_merged.t_span;

% Créer un masque logique pour ne garder que les heures multiples de 3
mask_3h = mod(hour(time_vec), 3) == 0;

% Appliquer le filtre
ttab_merged = ttab_merged(mask_3h, :);

%% Step 3: Combine into FORCING structure with required field names
FORCING.data.t_span       = datenum(ttab_merged.t_span);
FORCING.data.Lin          = ttab_merged.Lin;
FORCING.data.q            = ttab_merged.q;
FORCING.data.rainfall     = ttab_merged.rainfall;
FORCING.data.S_TOA        = ttab_merged.S_TOA;
FORCING.data.Sin          = ttab_merged.Sin;
FORCING.data.snowfall     = ttab_merged.snowfall;
FORCING.data.Tair         = ttab_merged.Tair;
FORCING.data.wind         = ttab_merged.wind;
FORCING.data.albedo_foot  = 0.2*ones(size(ttab_merged.t_span));

%% Step 4: Save to .mat

filename = sprintf('FORCING_data_elev_%d_slope_0_aspect_-1_massif_%d_dates_01Aug1958_01Aug2024_%s.mat', ...
    eleva, massif_nume, capteur_name);

save(fullfile('/Users/maximefadel/Documents/Stage_Edytem/Tristan_Forcage/Donnes_Forcage', filename), 'FORCING');