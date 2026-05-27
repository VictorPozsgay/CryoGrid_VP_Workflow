function [dates, T_daily_mean] = extract_daily_mean_temperature(file, altitude, sensor_depth, dt, end_date)
% extract_daily_mean_temperature
%   This function loads temperature data from a .mat file,
%   identifies the row corresponding to the target depth (altitude - sensor_depth),
%   computes the daily mean temperature (by grouping time steps per day),
%   and returns the daily temperature curve along with the corresponding dates.
%
% INPUTS:
%   - file : full path to the .mat file containing the OUT_TwaterIce structure
%   - altitude : reference altitude (in meters)
%   - sensor_depth : depth of the sensor (in meters)
%   - dt : simulation time step
%   - end_date : simulation end date (datetime, e.g., datetime(2024,8,1))
%
% OUTPUTS:
%   - dates : vector of datetime values corresponding to daily averages
%   - T_daily_mean : vector of daily mean temperatures
%
% Example:
% [dates, T_daily_mean] = extract_daily_mean_temperature('path/to/file.mat', 3530, 0.1, 0.25, datetime(2024,8,1));

    % Load data
    data = load(file);

    % Compute target depth
    target_depth = altitude - sensor_depth;

    % Extract available depths
    depths = data.OUT_TwaterIce.depths;

    % Find the row closest to the target depth
    [~, row_idx] = min(abs(depths - target_depth));

    % Extract temperature values at this row (all time steps)
    T_row = data.OUT_TwaterIce.T(row_idx, :);

    % Number of values per day
    n_per_day = round(1 / dt);

    % Compute number of complete days
    n_days = floor(length(T_row) / n_per_day);

    % Truncate to full days
    T_truncated = T_row(1 : n_days * n_per_day);

    % Reshape into matrix (rows = days, columns = time steps)
    T_by_day = reshape(T_truncated, n_per_day, n_days)';

    % Compute daily mean
    T_daily_mean = mean(T_by_day, 2);

    % Construct date vector counting backward from end_date
    dates = end_date - days(n_days-1:-1:0);

end
