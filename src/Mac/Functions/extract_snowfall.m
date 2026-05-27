function [daily_snowfall, daily_dates] = extract_snowfall(file, start_date, end_date)
% extract_snowfall
%   Computes the daily mean snowfall between two dates from a snowfall vector
%   containing ~8 measurements per day.
%
% INPUTS :
%   - file : path to .mat file containing the variable snowfall
%   - start_date : datetime of the first day (inclusive)
%   - end_date   : datetime of the last day (inclusive)
%
% OUTPUTS :
%   - daily_snowfall : vector of daily mean snowfall (mm/day)
%   - daily_dates    : vector of datetime corresponding to each day

    % --- Fixed parameters ---
    start_ref = datetime(1958, 8, 1);
    measurements_per_day = 8;

    % Load data
    data = load(file);
    if ~isfield(data, 'FORCING') || ~isfield(data.FORCING, 'data') || ~isfield(data.FORCING.data, 'snowfall')
        error('❌ File does not contain expected structure FORCING.data.snowfall.');
    end

    snowfall = data.FORCING.data.snowfall(:);  % column vector
    N = length(snowfall);

    % Approximate number of total days
    n_days_estimate = ceil(N / measurements_per_day);
    days_vec = start_ref + days(0:n_days_estimate - 1);

    % Repeat dates for each measurement, truncate to N
    dates = repelem(days_vec, measurements_per_day);
    dates = dates(1:N);

    % --- Check bounds ---
    if start_date < dates(1) || end_date > dates(end)
        error('❌ Specified dates are outside the data range.');
    end

    % Limit data to the specified interval
    idx_interval = (dates >= start_date) & (dates <= end_date);
    dates_interval = dates(idx_interval);
    snowfall_interval = snowfall(idx_interval);

    % Group by day
    unique_days = unique(dateshift(dates_interval, 'start', 'day'));
    daily_snowfall = zeros(length(unique_days), 1);
    daily_dates = unique_days;

    for i = 1:length(unique_days)
        idx_day = (dateshift(dates_interval, 'start', 'day') == unique_days(i));
        daily_snowfall(i) = mean(snowfall_interval(idx_day), 'omitnan');
    end
end
