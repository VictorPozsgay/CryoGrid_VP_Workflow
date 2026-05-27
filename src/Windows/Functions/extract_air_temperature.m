function [T_air_mean] = extract_air_temperature(file, start_date, end_date)
%EXTRACT_AIR_TEMPERATURE (robust version)
%   Computes the mean air temperature between two given dates from a
%   Tair vector containing ~8 measurements per day, without explicit dates
%   but with a known start date.
%
% INPUTS :
%   - file : path to the .mat file containing the variable Tair
%   - start_date : datetime for the start (inclusive)
%   - end_date   : datetime for the end (inclusive)
%
% OUTPUT :
%   - T_air_mean : mean Tair over the specified period

    % --- Fixed parameters ---
    start_reference = datetime(1958, 8, 1);
    measurements_per_day = 8;

    % Load data
    data = load(file);
    if ~isfield(data, 'FORCING') || ~isfield(data.FORCING, 'data') || ~isfield(data.FORCING.data, 'Tair')
        error('❌ The file does not contain the expected structure FORCING.data.Tair.');
    end

    Tair = data.FORCING.data.Tair(:);  % Ensure column vector
    N = length(Tair);

    % Estimate total number of days
    n_days_estimated = ceil(N / measurements_per_day);
    days_vector = start_reference + days(0:n_days_estimated - 1);

    % Create repeated dates vector, truncated to N elements
    dates = repelem(days_vector, measurements_per_day);
    dates = dates(1:N);

    % --- Check bounds ---
    if start_date < dates(1) || end_date > dates(end)
        error('❌ The specified dates are outside the data range.');
    end

    % Select indices corresponding to the requested interval
    indices = (dates >= start_date) & (dates <= end_date);

    if ~any(indices)
        warning('⚠️ No data in the specified date range.');
        T_air_mean = NaN;
        return;
    end

    % Robust mean
    T_air_mean = average_temperature_over_years(Tair(indices), dates(indices));
end
