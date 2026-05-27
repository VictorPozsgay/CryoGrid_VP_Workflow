function [daily_snowfall, daily_dates] = extract_snowfall(file, start_date, end_date)
%EXTRACT_SNOWFALL
%   Computes the daily mean snowfall between two dates from a vector of
%   snowfall measurements (~8 per day).
%
% INPUTS :
%   - file       : path to the .mat file containing the variable 'snowfall'
%   - start_date : datetime of the start (inclusive)
%   - end_date   : datetime of the end (inclusive)
%
% OUTPUTS :
%   - daily_snowfall : vector of mean snowfall per day (mm/day)
%   - daily_dates    : datetime vector corresponding to each daily value

    % --- Fixed parameters ---
    start_ref_date = datetime(1958, 8, 1);
    measurements_per_day = 8;

    % Load the data
    data = load(file);
    if ~isfield(data, 'FORCING') || ~isfield(data.FORCING, 'data') || ~isfield(data.FORCING.data, 'snowfall')
        error('❌ The file does not contain the expected FORCING.data.snowfall structure.');
    end

    snowfall = data.FORCING.data.snowfall(:);  % Column vector
    N = length(snowfall);

    % Estimate total number of days
    n_days_estimated = ceil(N / measurements_per_day);
    days_vector = start_ref_date + days(0:n_days_estimated - 1);

    % Create repeated date vector, truncated to N values
    dates = repelem(days_vector, measurements_per_day);
    dates = dates(1:N);  % Proper truncation if exceeded

    % --- Check bounds ---
    if start_date < dates(1) || end_date > dates(end)
        error('❌ The specified dates are outside the data range.');
    end

    % Restrict data to the specified interval
    interval_idx = (dates >= start_date) & (dates <= end_date);
    dates_interval = dates(interval_idx);
    snowfall_interval = snowfall(interval_idx);

    % Group by day
    unique_days = unique(dateshift(dates_interval, 'start', 'day'));
    daily_snowfall = zeros(length(unique_days), 1);
    daily_dates = unique_days;  % Initialize

    for i = 1:length(unique_days)
        day_idx = (dateshift(dates_interval, 'start', 'day') == unique_days(i));
        daily_snowfall(i) = mean(snowfall_interval(day_idx), 'omitnan');
    end
end
