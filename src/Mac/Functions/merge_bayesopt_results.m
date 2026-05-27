function merge_bayesopt_results(temp_folder, sensor_ID, final_file_path)

    % List all temporary result files for this sensor
    temp_files = dir(fullfile(temp_folder, ['temp_result_' sensor_ID '_*.mat']));
    
    if isempty(temp_files)
        error('No files found for sensor %s in folder %s.', sensor_ID, temp_folder);
    end
    
    results = {}; % cell array to store structs

    % Loop through all temporary files and load valid results
    for i = 1:length(temp_files)
        file_path = fullfile(temp_files(i).folder, temp_files(i).name);
        try
            data = load(file_path);

            if isfield(data, 'unique_result')
                r = data.unique_result;
                if isstruct(r)
                    results{end+1} = r;
                else
                    warning("⚠️ 'unique_result' in %s is not a struct. Ignored.", temp_files(i).name);
                end
            else
                warning("⚠️ 'unique_result' missing in %s. Ignored.", temp_files(i).name);
            end

        catch ME
            warning("⚠️ Error loading %s : %s", temp_files(i).name, ME.message);
        end
    end

    if isempty(results)
        error("⚠️ No valid results were loaded.");
    end

    % Save merged results
    save(final_file_path, 'results');
    fprintf("✅ Merged results (%d iterations) saved to: %s\n", ...
        length(results), final_file_path);

    % Display fields of the first result as an example
    if ~isempty(results)
        fprintf("\n📊 Fields available in an example result:\n");
        disp(fieldnames(results{1}));
    end
end
