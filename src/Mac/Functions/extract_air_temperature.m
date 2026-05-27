function [T_air_mean] = extract_air_temperature(file, start_date, end_date)
% extract_air_temperature
%   Robust calculation of the mean air temperature between two dates
%   from a Tair vector containing ~8 measurements per day, without explicit dates.
%
% INPUTS :
%   - file       : path to a .mat file containing FORCING.data.Tair
%   - start_date : start datetime (inclusive)
%   - end_date   : end datetime (inclusive)
%
% OUTPUT :
%   - T_air_mean : mean Tair over the specified period

    % --- Fixed parameters ---
    reference_date = datetime(1958, 8, 1);
    measurements_per_day = 8;

    % Load data
    data = load(file);
    if ~isfield(data, 'FORCING') || ~isfield(data.FORCING, 'data') || ~isfield(data.FORCING.data, 'Tair')
        error('❌ The file does not contain the expected FORCING.data.Tair structure.');
    end

    Tair = data.FORCING.data.Tair(:);  % Ensure column vector
    N = length(Tair);

    % Estimate the total number of days
    estimated_days = ceil(N / measurements_per_day);
    all_days = reference_date + days(0:estimated_days - 1);

    % Repeat each day for the number of measurements
    dates = repelem(all_days, measurements_per_day);
    dates = dates(1:N);  % truncate to match the length of Tair

    % --- Check bounds ---
    if start_date < dates(1) || end_date > dates(end)
        error('❌ Specified dates are outside the available data range.');
    end

    % Select indices corresponding to the requested interval
    indices = (dates >= start_date) & (dates <= end_date);

    if ~any(indices)
        warning('⚠️ No data available in the specified date range.');
        T_air_mean = NaN;
        return;
    end

    % Compute mean temperature over the interval, ignoring NaNs
    T_air_mean = average_temperature_over_years(Tair(indices), dates(indices));

    fprintf('ℹ️ Mean air temperature from %s to %s: %.2f °C\n', ...
        datestr(start_date), datestr(end_date), T_air_mean);
end
