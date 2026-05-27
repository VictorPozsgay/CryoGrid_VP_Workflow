function [dates, T_daily_mean] = extract_mean_temperature(file, altitude, sensor_depth, dt, end_date)
%EXTRACT_DAILY_MEAN_TEMPERATURE
%   This function loads temperature data from a .mat file,
%   finds the row corresponding to the targeted depth (altitude - sensor_depth),
%   calculates the daily mean temperature (grouping by days),
%   and returns the daily mean temperature vector along with the corresponding dates.
%
% INPUTS :
%   - file : full path to the .mat file containing the OUT_TwaterIce structure
%   - altitude : reference altitude (meters)
%   - sensor_depth : depth of the sensor (meters)
%   - dt : simulation time step (in fraction of day)
%   - end_date : simulation end date (datetime), matching the output in CryoGrid
%
% OUTPUTS :
%   - dates : datetime vector for each day
%   - T_daily_mean : vector of daily mean temperatures

    % Load the data
    data = load(file);

    % Target depth
    target_alt = altitude - sensor_depth;

    % Extract altitudes from the file
    altitudes = data.OUT_TwaterIce.depths;

    % Find the row closest to the target depth
    [~, row_idx] = min(abs(altitudes - target_alt));

    % Extract temperatures at this row (all time steps)
    T_row = data.OUT_TwaterIce.T(row_idx, :);

    % Number of values per day
    n_per_day = round(1 / dt);

    % Compute the number of complete days
    n_days = floor(length(T_row) / n_per_day);

    % Truncate to have an integer number of days
    T_truncated = T_row(1 : n_days * n_per_day);

    % Reshape into a matrix (rows = days, columns = time steps)
    T_per_day = reshape(T_truncated, n_per_day, n_days)';

    % Compute daily mean
    T_daily_mean = mean(T_per_day, 2);

    % Construct the datetime vector starting from the end date
    dates = end_date - days(n_days-1:-1:0);

end
