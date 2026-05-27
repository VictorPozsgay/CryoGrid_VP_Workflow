function T_mean = mean_temperature_over_years(T, dates)
%MEAN_TEMPERATURE_OVER_YEARS
%   Computes the mean temperature over complete years.
%
% INPUTS:
%   - T     : vector of temperatures
%   - dates : vector of corresponding datetime values
%
% OUTPUT:
%   - T_mean : mean temperature over full years, or all data if less than a year

    % Check that T and dates have the same length
    if length(T) ~= length(dates)
        error('❌ Vectors T and dates must have the same length.');
    end

    % Total duration in days between first and last date
    total_days = days(dates(end) - dates(1)) + 1;

    % If less than 1 year of data, take the mean over all data
    if total_days < 365
        T_mean = mean(T);
        fprintf('ℹ️ Less than one year of data (%d days) ➤ mean over all data.\n', total_days);
        return;
    end

    % Otherwise, take an integer number of years (blocks of 365 days)
    n_years = floor(total_days / 365);
    n_days_valid = n_years * 365;

    % Take the first n_days_valid values
    T_valid = T(1:n_days_valid);

    % Compute the mean
    T_mean = mean(T_valid);
    fprintf('✅ Mean calculated over %d years (%d days).\n', n_years, n_days_valid);
end
