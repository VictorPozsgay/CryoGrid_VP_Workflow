function full_path = find_measure_file(folder, sensor_name)
% FIND_MEASUREMENT_FILE : searches for a file like 'ID_daily_mean.csv' or '.xlsx'
% Recursive search in all subfolders
%
% INPUTS:
%   - folder : path to the main folder
%   - sensor_name : sensor identifier to search for (e.g., '108D30' or 'Lau_W')
%
% OUTPUT:
%   - full_path : full path of the found file

    extensions = {'.csv', '.xlsx'};
    sensor_name = string(sensor_name);

    for ext = extensions
        files = dir(fullfile(folder, '**', ['*' ext{1}])); % recursive search
        for i = 1:length(files)
            file_name = files(i).name;
            % Check if sensor_name appears anywhere in the file name
            if contains(file_name, sensor_name) && contains(file_name, '_daily_mean') ...
                    && endsWith(file_name, ext{1})
                full_path = fullfile(files(i).folder, file_name);
                return;
            end
        end
    end

    error('❌ No .csv or .xlsx measurement file found for sensor "%s".', sensor_name);
end
