function [dates1_sync, temp1_sync, dates2_sync, temp2_sync] = synchronize_data(dates1, temp1, dates2, temp2)
    % Determine the common interval
    date_min = max(min(dates1), min(dates2));
    date_max = min(max(dates1), max(dates2));

    % Truncate both series to common interval
    idx1 = dates1 >= date_min & dates1 <= date_max;
    idx2 = dates2 >= date_min & dates2 <= date_max;

    dates1_sync = dates1(idx1);
    temp1_sync  = temp1(idx1);

    dates2_sync = dates2(idx2);
    temp2_sync  = temp2(idx2);
end

