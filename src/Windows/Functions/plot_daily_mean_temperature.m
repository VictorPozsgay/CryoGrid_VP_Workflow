function plot_daily_mean_temperature(file, altitude, sensor_depth, dt, end_date)
%PLOT_DAILY_MEAN_TEMPERATURE
%   Loads temperature data from a .mat file, finds the row corresponding to
%   the target depth (altitude - sensor_depth), computes daily mean
%   temperatures (grouped by days), and plots the daily mean temperature
%   over time.
%
% INPUTS:
%   - file : full path to the .mat file containing the structure OUT_TwaterIce
%   - altitude : reference altitude (meters)
%   - sensor_depth : sensor depth (meters)
%   - dt : simulation time step
%   - end_date : simulation end date (datetime, e.g., datetime(2024,8,1))
%
% Example call:
% plot_daily_mean_temperature('path/to/file.mat', 3530, 0.1, 1/8, datetime(2024,8,1));

    % Load data
    data = load(file);

    % Compute target altitude
    target_alt = altitude - sensor_depth;

    % Extract altitudes from the file
    altitudes = data.OUT_TwaterIce.depths;

    % Find the row closest to target altitude
    [~, row_idx] = min(abs(altitudes - target_alt));

    % Extract temperatures at this row (all time steps)
    T_row = data.OUT_TwaterIce.T(row_idx, :);

    % Number of values per day
    n_per_day = round(1 / dt);

    % Compute daily mean temperature
    n_days = floor(length(T_row) / n_per_day);

    % Truncate to have an integer number of days
    T_truncated = T_row(1 : n_days * n_per_day);

    % Reshape into a matrix (rows = days, columns = time steps)
    T_per_day = reshape(T_truncated, n_per_day, n_days)';

    % Daily mean temperature
    T_daily_mean = mean(T_per_day, 2);

    % Build date vector starting from end_date
    dates = end_date - days(n_days-1:-1:0);

    disp(dates);

    % Plot daily mean temperature
    plot(dates, T_daily_mean, ':r', 'LineWidth', 0.5);
    xlabel('Date');
    ylabel('Daily mean temperature (°C)');
    title('Daily temperature evolution at sensor depth');
    legend('CryoGrid');
    grid on;
    hold on;

end
