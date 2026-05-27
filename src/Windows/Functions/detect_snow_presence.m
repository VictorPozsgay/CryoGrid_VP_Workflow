function [snow_present, sequences, snow_days, total_days, avg_snow_days_per_year, snow_dates] = detect_snow_presence(file, variation_threshold, min_duration)
% detect_snow_presence
%   Detects periods of probable snow based on temperature stability near 0°C.
%
% INPUTS:
%   - file               : path to the CSV or XLSX file containing date and temperature
%   - variation_threshold : maximum daily temperature change to consider 'stable'
%   - min_duration       : minimum number of consecutive days to count as snow
%
% OUTPUTS:
%   - snow_present            : boolean (true if snow sequences detected)
%   - sequences               : cell array of indices of snow sequences
%   - snow_days               : total number of snow days
%   - total_days              : total number of days analyzed
%   - avg_snow_days_per_year  : average snow days per year
%   - snow_dates              : cell array of [start_date, end_date] for each sequence

    [~, base_name, ext] = fileparts(file);
    ext = lower(ext);

    try
        if strcmp(ext, '.csv')
            % Read CSV (no header)
            T = readtable(file, 'Delimiter', ';', 'ReadVariableNames', false, 'VariableNamingRule', 'preserve');
            dates = T.Var1;
            temp = T.Var2;
        elseif strcmp(ext, '.xlsx')
            % Read Excel (ignore column names)
            T = readtable(file, 'ReadVariableNames', false);
            dates = T.Var1;
            temp = T.Var2;
        else
            error('Unsupported file extension: %s', ext);
        end
    catch ME
        fprintf('Error reading file %s: %s\n', file, ME.message);
        snow_present = false;
        sequences = {};
        snow_days = 0;
        total_days = 0;
        avg_snow_days_per_year = 0;
        snow_dates = {};
        return;
    end

    % Clean table and convert data
    T = table(dates, temp, 'VariableNames', {'DATE', 'TEMP'});
    T.DATE = datetime(T.DATE, 'InputFormat', '', 'Format', 'dd-MMM-yyyy', 'Locale', 'fr_FR');
    T.TEMP = str2double(strrep(string(T.TEMP), ',', '.'));
    T = rmmissing(T);
    T = sortrows(T, 'DATE');

    % Compute daily variation and snow condition
    T.VAR = [NaN; abs(diff(T.TEMP))];
    T.LOW_VAR = T.VAR < variation_threshold;
    T.NEAR_ZERO = T.TEMP >= -6 & T.TEMP <= 1;
    T.SNOW_CONDITION = T.LOW_VAR & T.NEAR_ZERO;

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

    % Extract start/end dates of snow sequences
    snow_dates = {};
    for i = 1:length(sequences)
        idx = sequences{i};
        snow_dates{end+1} = [T.DATE(idx(1)), T.DATE(idx(end))];
    end

    % Summary statistics
    snow_present = ~isempty(sequences);
    snow_days = sum(cellfun(@length, sequences));
    total_days = height(T);
    delta_years = max(days(T.DATE(end) - T.DATE(1)) / 365.25, 1);
    avg_snow_days_per_year = snow_days / delta_years;

    % Console summary
    if snow_present
        fprintf('❄️ Probable snow detected on %d days (out of %d days).\n', snow_days, total_days);
        fprintf('➡️ Average snow days per year: %.1f\n', avg_snow_days_per_year);
    else
        fprintf('🌿 No snow coverage detected according to criteria.\n');
        fprintf('Total days analyzed: %d\n', total_days);
    end

    % Plot
    figure('Visible', 'on'); hold on;
    
    % Temperature line (blue)
    h1 = plot(T.DATE, T.TEMP, 'b-', 'DisplayName', 'Temperature');
    
    % Highlight snow sequences (red)
    h2 = [];
    for k = 1:length(sequences)
        idx = sequences{k};
        h = plot(T.DATE(idx), T.TEMP(idx), 'r-', 'LineWidth', 2);
        if k == 1
            h2 = h;  % only first sequence for legend
        end
    end
    
    xlabel('Date');
    ylabel('Temperature (°C)');
    title(sprintf('Snow Detection\n%d snow days out of %d days — %.1f days/year', snow_days, total_days, avg_snow_days_per_year));
    legend([h1, h2], {'Temperature', 'Detected Snow Period'});
    grid on;
    set(gcf, 'Color', 'w');

end
