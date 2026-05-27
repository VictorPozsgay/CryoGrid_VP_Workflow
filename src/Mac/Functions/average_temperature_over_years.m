function T_mean = average_temperature_over_years(T, dates)
    if isempty(T)
        T_mean = NaN;
        return;
    end

    total_days = days(dates(end) - dates(1)) + 1;

    if total_days < 365
        % Average over all available days if less than a year
        T_mean = mean(T);
        fprintf('ℹ️ Less than one year of data (%d days) ➤ averaging over all data.\n', total_days);
        return;
    end

    % Otherwise, use integer number of full years
    n_years = floor(total_days / 365);
    n_days_valid = min(length(T), n_years * 365);
    T_valid = T(1:n_days_valid);

    T_mean = mean(T_valid);
    fprintf('✅ Average computed over %d years (%d days).\n', n_years, n_days_valid);
end

