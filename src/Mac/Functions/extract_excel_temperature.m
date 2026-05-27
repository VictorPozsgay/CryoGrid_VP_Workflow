function [dates, temp] = extract_excel_temperature(sensor_data_file)
% extract_excel_temperature
%   Reads an Excel file with two columns: date and temperature
%   Returns the dates and temperature as vectors.
%
% INPUT :
%   - sensor_data_file : full path to the Excel file
%
% OUTPUTS :
%   - dates : datetime vector
%   - temp  : numeric vector of temperature values
%
% Example:
%   [dates, temp] = extract_excel_temperature('sensor_data.xlsx');

    % Read table while preserving column names
    T = readtable(sensor_data_file, 'VariableNamingRule', 'preserve');

    % Basic check
    if width(T) < 2
        error('File must contain at least two columns (Date and Temperature).');
    end

    % Assume first column contains dates
    dates = T{:,1};
    dates = datetime(dates, 'InputFormat', 'dd/MM/yyyy');

    % Second column: temperature
    temp = T{:,2};

    % If temp is a cell of strings with commas
    if iscell(temp)
        temp = strrep(temp, ',', '.');  % replace comma with dot
        temp = str2double(temp);        % convert to numeric
    end

end
