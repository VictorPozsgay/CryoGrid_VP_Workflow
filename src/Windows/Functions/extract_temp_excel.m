function [dates, temp] = extract_temp_excel(excel_file)
%EXTRACT_TEMP_EXCEL
%   Reads an Excel file containing two columns: date and temperature.
%   Returns the date vector and temperature vector.
%
% INPUT :
%   - excel_file : full path to the Excel file
%
% Example:
%   [dates, temp] = extract_temp_excel('sensor_data.xlsx');

    % Read the table, preserving column names
    T = readtable(excel_file, 'VariableNamingRule', 'preserve');

    % Basic check
    if width(T) < 2
        error('The file must contain at least two columns (Date and Temperature).');
    end

    % Assume first column contains dates
    dates = T{:,1};
    dates = datetime(dates, 'InputFormat', 'dd/MM/yyyy');

    % Second column: temperature
    temp = T{:,2};

    % Handle case where temperature is stored as cell array of strings, e.g., '12,5'
    if iscell(temp)
        % Replace comma with dot for str2double
        temp = strrep(temp, ',', '.'); 
        % Convert to double
        temp = str2double(temp);
    end

end
