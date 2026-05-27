function [snow_presence, sequences, snow_days, total_days, mean_snow_days_per_year, snow_dates] = detect_snow_presence(file, variation_threshold, min_duration)

    [~, base_name, ext] = fileparts(file);
    ext = lower(ext);

    try
        if strcmp(ext, '.csv')
            % Read without header, columns named Var1, Var2...
            T = readtable(file, 'Delimiter', ';', 'ReadVariableNames', false, 'VariableNamingRule', 'preserve');

            % Extract 1st column (dates) and 2nd column (temperatures)
            dates = T.Var1;
            temp = T.Var2;
        elseif strcmp(ext, '.xlsx')
            % For Excel, same approach, ignore column names
            T = readtable(file, 'ReadVariableNames', false);

            dates = T.Var1;
            temp = T.Var2;
        else
            error("Unsupported file extension: %s", ext);
        end
    catch ME
        fprintf("Error reading file %s: %s\n", file, ME.message);
        snow_presence = 0;
        sequences = {};
        snow_days = 0;
        total_days = 0;
        mean_snow_days_per_year = 0;
        snow_dates = {};
        return;
    end

    % Create a clean table with DATE and TEMP columns
    T = table(dates, temp, 'VariableNames', {'DATE', 'TEMP'});

    % Process dates and temperatures
    T.DATE = datetime(T.DATE, 'InputFormat', '', 'Format', 'dd-MMM-yyyy', 'Locale', 'fr_FR');
    T.TEMP = str2double(strrep(string(T.TEMP), ',', '.'));
    T = rmmissing(T);
    T = sortrows(T, 'DATE');

    % Compute variation
    T.VAR = [NaN; abs(diff(T.TEMP))];
    T.LOW_VAR = T.VAR < variation_threshold;
    T.TEMP_NEAR_ZERO = T.TEMP >= -2 & T.TEMP <= 2;
    T.SNOW_CONDITION = T.LOW_VAR & T.TEMP_NEAR_ZERO;

    % Detect continuous sequences
    sequences = {};
    current_seq = [];
    for i = 1:height(T)
        if T.SNOW_CONDITION(i)
            current_seq = [current_seq i];
        else
            if length(current_seq) >= min_duration
                sequences{end+1} = current_seq; %#ok<AGROW>
            end
            current_seq = [];
        end
    end
    if length(current_seq) >= min_duration
        sequences{end+1} = current_seq;
    end

    % Dates of snow sequences
    snow_dates = {};
    for i = 1:length(sequences)
        idx = sequences{i};
        start_date = T.DATE(idx(1));
        end_date = T.DATE(idx(end));
        snow_dates{end+1} = [start_date, end_date];  % 2-element datetime array
    end

    % Numeric summaries
    snow_presence = ~isempty(sequences);
    snow_days = sum(cellfun(@length, sequences));
    total_days = height(T);
    delta_years = max(days(T.DATE(end) - T.DATE(1)) / 365.25, 1);
    mean_snow_days_per_year = snow_days / delta_years;

    % Console summary
    if snow_presence
        fprintf("❄️ Snow likely detected for %d days (out of %d total days).\n", snow_days, total_days);
        fprintf("➡️ Average snow days per year: %.1f\n", mean_snow_days_per_year);
    else
        fprintf("🌿 No snow cover detected based on the given criteria.\n");
        fprintf("Total days analyzed: %d\n", total_days);
    end

    % Plot
    figure('Visible', 'on'); hold on;
    
    % Global temperature plot (blue)
    h1 = plot(T.DATE, T.TEMP, 'b-', 'DisplayName', 'Temperature');
    
    % Snow sequences plot (red)
    h2 = [];  % first red plot handle only
    for k = 1:length(sequences)
        idx = sequences{k};
        h = plot(T.DATE(idx), T.TEMP(idx), 'r-', 'LineWidth', 2);
        if k == 1
            h2 = h;  % store first for legend
        end
    end
    
    xlabel("Date");
    ylabel("Temperature (°C)");
    title(sprintf("Snow Detection\n%d snow days out of %d total days — %.1f days/year", snow_days, total_days, mean_snow_days_per_year));
    legend([h1, h2], {'Temperature', 'Detected Snow Period'});
    grid on;
    set(gcf, 'Color', 'w');

end
