%% Extract SAFRAN wind-direction statistics from NetCDF
% clear; clc;

input_file = "C:\Users\pozsgayv\Downloads\FORCING_1958080106_1959080106.nc";
output_file = 'SAFRAN_WIND_DIRECTION_STATS.mat';

%% Read variables

time = ncread(input_file, 'time');
z = ncread(input_file, 'ZS');
massif = ncread(input_file, 'massif_number');
wind_dir = ncread(input_file, 'Wind_DIR');
wind_speed = ncread(input_file, 'Wind');

%% Convert time

time_units = ncreadatt(input_file, 'time', 'units');

% Example:
% 'hours since 1958-08-01 06:00:00'
reference_time = erase(time_units, 'hours since ');

reference_date = datetime(reference_time, ...
    'InputFormat', 'yyyy-MM-dd HH:mm:ss');

dates = reference_date + hours(time);

%% Select winter months (November-April)

winter = month(dates) >= 11 | month(dates) <= 4;

%% Direction sectors

% SAFRAN directions are already quantised to 10-degree increments
direction_bins = 0:10:360;
direction_centres = 0:10:350;

%% Statistics for each massif/elevation band

bands = unique([massif(:), z(:)], 'rows');
n = size(bands, 1);

stats = struct( ...
    'massif_number', num2cell(bands(:,1)), ...
    'elevation', num2cell(bands(:,2)), ...
    'mean_direction_deg', num2cell(nan(n,1)), ...
    'weighted_mean_direction_deg', num2cell(nan(n,1)), ...
    'resultant_length', num2cell(nan(n,1)), ...
    'mean_wind_speed', num2cell(nan(n,1)), ...
    'n_valid', num2cell(zeros(n,1)), ...
    'direction_histogram', cell(n,1), ...
    'direction_histogram_weighted', cell(n,1));

for i = 1:n

    idx = massif == bands(i,1) & z == bands(i,2);

    theta = wind_dir(idx, winter);
    speed = wind_speed(idx, winter);

    theta = theta(:);
    speed = speed(:);

    valid = isfinite(theta) & isfinite(speed) & ...
        theta >= 0 & theta < 360 & speed >= 0;

    theta = theta(valid);
    speed = speed(valid);

    if isempty(theta)
        continue
    end

    %% Unweighted circular mean

    C = mean(cosd(theta));
    S = mean(sind(theta));

    stats(i).mean_direction_deg = mod(atan2d(S, C), 360);
    stats(i).resultant_length = hypot(C, S);

    %% Wind-speed-weighted circular mean

    Cw = sum(speed .* cosd(theta));
    Sw = sum(speed .* sind(theta));

    if hypot(Cw, Sw) > 0
        stats(i).weighted_mean_direction_deg = ...
            mod(atan2d(Sw, Cw), 360);
    end

    %% Wind speed

    stats(i).mean_wind_speed = mean(speed);
    stats(i).n_valid = numel(theta);

    %% Direction histograms

    % Number of observations in each 10-degree sector
    stats(i).direction_histogram = ...
        histcounts(theta, direction_bins);

    % Wind-speed-weighted histogram
    bin = discretize(theta, direction_bins);

    valid_bin = ~isnan(bin);

    stats(i).direction_histogram_weighted = ...
        accumarray(bin(valid_bin), speed(valid_bin), ...
        [numel(direction_centres), 1], @sum, 0)';

end

%% Save statistics

save(output_file, ...
    'stats', ...
    'direction_centres', ...
    'direction_bins');

fprintf('Saved wind-direction statistics to %s\n', output_file);

%% Polar histogram for one massif/elevation band (weighted)

% Select which band to plot
plot_index = 2;

% Extract weighted histogram
hist_weighted = stats(plot_index).direction_histogram_weighted;

% Convert degrees to radians
theta_plot = deg2rad(direction_centres);

% Repeat first value at 360 degrees to close the circle
theta_plot = [theta_plot, 2*pi];
hist_plot = [hist_weighted, hist_weighted(1)];

% Plot
figure;

polarplot(theta_plot, hist_plot, '-o');

title(sprintf( ...
    'Winter (weighted) wind direction - Massif %d, %.0f m', ...
    stats(plot_index).massif_number, ...
    stats(plot_index).elevation));

%% Polar histogram for one massif/elevation band

% Select which band to plot
plot_index = 2;

% Extract histogram
hist = stats(plot_index).direction_histogram;

% Convert degrees to radians
theta_plot = deg2rad(direction_centres);

% Repeat first value at 360 degrees to close the circle
theta_plot = [theta_plot, 2*pi];
hist_plot = [hist, hist(1)];

% Plot
figure;

polarplot(theta_plot, hist_plot, '-o');

title(sprintf( ...
    'Winter wind direction - Massif %d, %.0f m', ...
    stats(plot_index).massif_number, ...
    stats(plot_index).elevation));

%% Print selected band statistics

fprintf('\nSelected band:\n');
fprintf('  Massif: %d\n', stats(plot_index).massif_number);
fprintf('  Elevation: %.0f m\n', stats(plot_index).elevation);
fprintf('  Mean direction: %.1f deg\n', ...
    stats(plot_index).mean_direction_deg);
fprintf('  Wind-speed-weighted direction: %.1f deg\n', ...
    stats(plot_index).weighted_mean_direction_deg);
fprintf('  Resultant length: %.3f\n', ...
    stats(plot_index).resultant_length);
fprintf('  Mean wind speed: %.2f\n', ...
    stats(plot_index).mean_wind_speed);
