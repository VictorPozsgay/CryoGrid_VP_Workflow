function run_forcing_safran(massif_nume, eleva, capteur_name)


%% PARAMÈTRES
addpath(genpath('/Users/maximefadel/Documents/Stage_Edytem/Tristan_Forcage/')) % chemin du code
nc_data_folder = '/Users/maximefadel/Documents/Stage_Edytem/Tristan_Forcage/meteo'; % dossier netCDF
table_out_folder = '/Users/maximefadel/Documents/Stage_Edytem/Tristan_Forcage/Donnes_Forcage'; % sortie tables

% files_list = dir([nc_data_folder '*.nc']); pour l'i

files_list = [
    dir(fullfile(nc_data_folder, '*.NC')); ...
];

% vérification 

if isempty(files_list)
    warning('Aucun fichier .nc trouvé dans le dossier : %s', nc_data_folder);
else
    disp('Premier fichier détecté :');
    disp(files_list(1));
end

% vérification 

files_names = string({files_list.name});

% vérification 

disp(files_names);

% vérification 

%% PARAMÈTRES DE STATION

massif_num = massif_nume;   % !!!!!!!!! À modifier 
elev = eleva; % % !!!!!!!!! À modifier 
slope_ind = 0;
aspect_ind = -1;

disp(length(files_names));


for i = 1:length(files_names)
    filepath = fullfile(nc_data_folder, files_names(i));
    info = ncinfo(filepath);

    % Lecture variables
    massif = ncread(filepath, 'massif_number');
    zs = ncread(filepath, 'ZS');
    slope = ncread(filepath, 'slope');
    aspect = ncread(filepath, 'aspect');
    time = ncread(filepath, 'time');

    % Météo
    Tair = ncread(filepath, 'Tair');
    LWdown = ncread(filepath, 'LWdown');
    DIR_SWdown = ncread(filepath, 'DIR_SWdown');
    SCA_SWdown = ncread(filepath, 'SCA_SWdown');
    Qair = ncread(filepath, 'Qair');
    Wind = ncread(filepath, 'Wind');
    Rainf = ncread(filepath, 'Rainf');
    Snowf = ncread(filepath, 'Snowf');
    PSurf = ncread(filepath, 'PSurf');

    % Unités
    at_names = {info.Attributes.Name};
    starttime = datetime(info.Attributes(1, strcmp(at_names, 'time_coverage_start')).Value, 'Format', 'uuuu-MM-dd''T''HH:mm:ss');
    finishtime = datetime(info.Attributes(1, strcmp(at_names, 'time_coverage_end')).Value, 'Format', 'uuuu-MM-dd''T''HH:mm:ss');
    TIME = starttime + hours(time);

    if TIME(end) ~= finishtime
        disp('Incohérence sur le temps de fin')
    end

    TAIR = Tair - 273.15;
    WIND = Wind;
    WIND(Wind < 0.1) = 0.1;

    ro_rain = 1000;
    RAINF = Rainf * (1 / ro_rain) * 1000 * (24 * 60 * 60);
    SNOWF = Snowf * (1 / ro_rain) * 1000 * (24 * 60 * 60);
    SWIN = DIR_SWdown + SCA_SWdown;

    % INTERPOLATION ALTITUDE
    z_low = floor(elev / 300) * 300;
    z_high = ceil(elev / 300) * 300;

    if z_low == z_high
        % Pas d'interpolation
        ind = massif == massif_num & zs == elev & slope == slope_ind & aspect == aspect_ind;

        if ~any(ind)
            warning('Pas de données pour elev = %d m dans %s', elev, files_names(i));
            continue
        end

        Tair_interp = TAIR(ind, :);
        Lin_interp  = LWdown(ind, :);
        Sin_interp  = SWIN(ind, :);
        q_interp    = Qair(ind, :);
        wind_interp = WIND(ind, :);
        rain_interp = RAINF(ind, :);
        snow_interp = SNOWF(ind, :);
        p_interp    = PSurf(ind, :);

    else
        % Interpolation linéaire
        ind_low = massif == massif_num & zs == z_low & slope == slope_ind & aspect == aspect_ind;
        ind_high = massif == massif_num & zs == z_high & slope == slope_ind & aspect == aspect_ind;

        if ~any(ind_low) || ~any(ind_high)
            warning('Interpolation impossible pour elev = %d m dans %s', elev, files_names(i));
            continue
        end

        w = (elev - z_low) / (z_high - z_low);

        Tair_interp = (1 - w) * TAIR(ind_low, :) + w * TAIR(ind_high, :);
        Lin_interp  = (1 - w) * LWdown(ind_low, :) + w * LWdown(ind_high, :);
        Sin_interp  = (1 - w) * SWIN(ind_low, :) + w * SWIN(ind_high, :);
        q_interp    = (1 - w) * Qair(ind_low, :) + w * Qair(ind_high, :);
        wind_interp = (1 - w) * WIND(ind_low, :) + w * WIND(ind_high, :);
        rain_interp = (1 - w) * RAINF(ind_low, :) + w * RAINF(ind_high, :);
        snow_interp = (1 - w) * SNOWF(ind_low, :) + w * SNOWF(ind_high, :);
        p_interp    = (1 - w) * PSurf(ind_low, :) + w * PSurf(ind_high, :);
    end

    % Création de la table
    tab = table( ...
        TIME(:), ...
        Tair_interp(:), ...
        Lin_interp(:), ...
        Sin_interp(:), ...
        q_interp(:), ...
        wind_interp(:), ...
        rain_interp(:), ...
        snow_interp(:), ...
        p_interp(:), ...
        'VariableNames', {'t_span', 'Tair', 'Lin', 'Sin', 'q', 'wind', 'rainfall', 'snowfall', 'p'} );

    % Sauvegarde dans un timetable
    ttab_temp = table2timetable(tab);

    if i == 1
        ttab = ttab_temp;
    else
        ttab = [ttab; ttab_temp];
    end
    disp(i);
end

% Nettoyage & sauvegarde finale
ttab = clean_data(ttab);

formatOut = 'ddmmmyyyy';
ttab_outname = sprintf('SAFRAN_ttab_elev_%d_slope_%d_aspect_%d_massif_%d_dates_%s_%s_%s', ...
    elev, slope_ind, aspect_ind, massif_num,...
    datestr(ttab.Properties.RowTimes(1), formatOut), ...
    datestr(ttab.Properties.RowTimes(end), formatOut), capteur_name);

ttab_safran = ttab;
save(fullfile(table_out_folder, [ttab_outname '.mat']), 'ttab_safran', 'info');

end