function plot_excel_temperature(excel_file, dates)
% plot_excel_temperature
%   Reads an Excel file containing two columns: date and temperature
%   Plots temperature over time in a simple and robust way.
%
% INPUT:
%   - excel_file : full path to the Excel file
%
% Example:
%   plot_excel_temperature('sensor_data.xlsx', dates_vector);

    % Read the table with column names preserved
    T = readtable(excel_file, 'VariableNamingRule', 'preserve');

    % Minimal check
    if width(T) < 2
        error('The file must contain at least two columns (Date and Temperature).');
    end

    % Second column: temperature
    temp = T{:,2};

    % Assume temp is a cell of strings with numbers like '12,5'
    if iscell(temp)
        % Replace comma with dot for str2double
        temp = strrep(temp, ',', '.'); 
        % Convert to double
        temp = str2double(temp);
    end

    % Plot
    plot(dates, temp, '-b', 'LineWidth', 0.5);
    xlabel('Date');
    ylabel('Temperature (°C)');
    title('Temperature over time');
    legend('Sensor');
    grid on;

end
