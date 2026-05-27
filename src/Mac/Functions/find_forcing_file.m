function filename = find_forcing_file(folder, sensor_name)
% find_forcing_file : searches for a FORCING file associated with a given sensor
%
% INPUTS:
%   - folder : path to the folder containing the files
%   - sensor_name : sensor identifier to search for (string or char)
%
% OUTPUT:
%   - filename : name of the file found (without path)

    files = dir(fullfile(folder, 'FORCING*.mat'));
    sensor_name = string(sensor_name); % force string format

    for i = 1:length(files)
        current_name = files(i).name;
        name_no_ext = erase(current_name, '.mat');

        % Check if the name ends exactly with "_<sensor_name>"
        pattern = "_" + sensor_name;
        if endsWith(name_no_ext, pattern)
            filename = files(i).name;
            return;
        end
    end

    error('❌ No FORCING file found for sensor "%s".', sensor_name);
end
