function [final_name, sensor_info] = get_sensor_info(sensor_name, file, forcing_folder, dt)
% get_sensor_info : Retrieves sensor information from an Excel file.
%
% INPUT :
%   - sensor_name : ID to search in the "ID" column (string or numeric)
%
% OUTPUT :
%   - final_name  : actual name found (from 'ID')
%   - sensor_info : structure containing sensor info (coordinates, slope, depth...)

    % Read the full table
    T = readtable(file, 'VariableNamingRule', 'preserve');

    % Check required columns
    required_columns = ["ID", "x", "y", "altitude (m)", ...
        "orientation (°)", "snow", "slope", "Depth (m)", ...
        "first measurement date", "last measurement date", ...
        "Mean Albedo", "Standard Deviation"];

    if ~all(ismember(required_columns, string(T.Properties.VariableNames)))
        error('❌ The Excel file does not contain all required columns.');
    end

    % Robust ID matching (works for numeric or string IDs)
    colID = T.ID;
    if isnumeric(colID)
        sensor_id_num = str2double(sensor_name);
        idx = find(colID == sensor_id_num, 1);
    else
        idx = find(strcmpi(strtrim(string(colID)), string(sensor_name)), 1);
    end

    if isempty(idx)
        error('❌ Sensor "%s" not found in "ID" column.', sensor_name);
    end

    % Use the first matching row
    row = idx(1);

    % Actual name used → fallback to ID
    final_name = string(T.ID(row));

    % Extract values into a structure
    sensor_info.longitude    = T.x(row);
    sensor_info.latitude     = T.y(row);
    sensor_info.altitude     = T.("altitude (m)")(row);
    sensor_info.aspect       = T.("orientation (°)")(row);
    sensor_info.slope_angle  = T.slope(row);
    sensor_info.sensor_depth = T.("Depth (m)")(row);
    sensor_info.start_time   = T.("first measurement date")(row);
    sensor_info.end_time     = T.("last measurement date")(row);
    sensor_info.Mean_Albedo  = T.("Mean Albedo")(row);
    sensor_info.Standard_Deviation = T.("Standard Deviation")(row);

    % Add additional elevations
    sensor_info.upper_elevation = sensor_info.altitude + 2;
    sensor_info.lower_elevation = sensor_info.altitude - 5;

    % Add sky view factor
    sensor_info.skyview_factor = 0.5 * (1 + cosd(sensor_info.slope_angle));

    % Add recording interval (years)
    sensor_info.save_interval = (year(sensor_info.end_time) - year(sensor_info.start_time)) + 1;

    % Add forcing data file
    forcing_file_found = find_forcing_file(forcing_folder, final_name);
    sensor_info.filename = forcing_file_found;

    % Truncate end date if it exceeds SAFRAN data
    max_safran_date = get_last_forcing_date(forcing_file_found);
    if sensor_info.end_time > max_safran_date
        warning("⚠️ Sensor '%s' end date truncated to %s (exceeds SAFRAN data).", ...
            final_name, max_safran_date);
        sensor_info.end_time = max_safran_date;
    end

    % Add step time
    sensor_info.output_timestep = dt;

    % Add forcing path
    sensor_info.forcing_path = fullfile(forcing_folder, '/');
end
