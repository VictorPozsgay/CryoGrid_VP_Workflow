function plot_temp_excel(excel_file, dates)
%PLOT_TEMP_EXCEL
%   Reads an Excel file containing two columns: date and temperature,
%   and plots temperature over time in a simple and robust way.
%
% INPUT:
%   - excel_file : full path to the Excel file
%
% Example:
%   plot_temp_excel('sensor_data.xlsx');

    % Read the table while keeping original column names
    T = readtable(excel_file, 'VariableNamingRule', 'preserve');

    % Minimal check
    if width(T) < 2
        error('The file must contain at least two columns (Date and Temperature).');
    end

    % Second column: temperature
    temp = T{:,2};

    % If temp is a cell array of strings like '12,5', convert to numeric
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
