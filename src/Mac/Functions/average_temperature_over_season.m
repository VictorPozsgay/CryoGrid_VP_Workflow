function T_mean = average_temperature_over_season(T, dates)
    if isempty(T)
        T_mean = NaN;
        return;
    end

    total_days = days(dates(end) - dates(1)) + 1;

    if total_days < 91
        % Average over all available days if less than a season
        T_mean = mean(T);
        fprintf('ℹ️ Less than one season of data (%d days) ➤ averaging over all data.\n', total_days);
        return;
    end

    % Otherwise, use integer number of full season
    n_season = floor(total_days / 91);
    n_days_valid = min(length(T), n_season * 91);
    T_valid = T(1:n_days_valid);

    T_mean = mean(T_valid);
    fprintf('✅ Average computed over %d season (%d days).\n', n_season, n_days_valid);
end