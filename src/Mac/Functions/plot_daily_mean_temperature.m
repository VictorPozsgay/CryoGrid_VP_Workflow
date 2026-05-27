function plot_daily_mean_temperature(file, altitude, sensor_depth, dt, end_date)
% plot_daily_mean_temperature
%   Loads temperature data from a .mat file, finds the row corresponding
%   to the targeted depth (altitude - sensor_depth), computes the daily
%   mean temperature (grouping by days), and plots the daily mean over time.
%
% INPUTS:
%   - file : full path to the .mat file containing OUT_TwaterIce structure
%   - altitude : reference altitude (m)
%   - sensor_depth : depth of the sensor (m)
%   - dt : simulation time step
%   - end_date : simulation end date (datetime format)
%
% Example:
%   plot_daily_mean_temperature('path/to/file.mat', 3530, 0.1, 0.125, datetime(2024,8,1));

    % Load data
    data = load(file);

    % Compute target altitude
    target_alt = altitude - sensor_depth;

    % Extract altitudes
    altitudes = data.OUT_TwaterIce.depths;

    % Find the row closest to target altitude
    [~, row_idx] = min(abs(altitudes - target_alt));

    % Extract temperatures at this row (all time steps)
    temp_row = data.OUT_TwaterIce.T(row_idx, :);

    % Number of values per day
    n_per_day = round(1 / dt);

    % Compute number of complete days
    n_days = floor(length(temp_row) / n_per_day);

    % Truncate to full days
    temp_truncated = temp_row(1:n_days * n_per_day);

    % Reshape into matrix (rows = days, columns = time steps)
    temp_per_day = reshape(temp_truncated, n_per_day, n_days)';

    % Daily mean temperature
    T_mean_cryo = mean(temp_per_day, 2);

    % Build vector of dates starting from end_date
    dates_cryo = end_date - days(n_days-1:-1:0);

    % Display dates (optional)
    disp(dates_cryo);

    % Plot daily mean temperature
    plot(dates_cryo, T_mean_cryo, ':r', 'LineWidth', 0.5);
    xlabel('Date');
    ylabel('Daily Mean Temperature (°C)');
    title('Daily Mean Temperature Evolution at Sensor Depth');
    legend('CryoGrid');
    grid on;
    hold on;

end
