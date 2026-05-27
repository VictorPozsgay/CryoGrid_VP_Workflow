function varargout = objectiveFunction_parallel(x, excel_file, sensor_data_file, info, snow_dates, mean_snow_days_per_year, season_weights, sourcePath, sensor_ID, forcing_folder, dt, resultsPath, params_config)

    % ===============================
    % Setup structure for parameters to optimize
    % ===============================

    if istable(x)
        x = table2struct(x);
    end
    
    optimized_parameters = x;
    
    
    % Handle snow_fraction default if missing
    if ~isfield(optimized_parameters, 'snow_fraction')
        warning('snow_fraction not present: forced to 0');
        optimized_parameters.snow_fraction = 0;
    end

    disp(optimized_parameters);

    % ===============================
    % Parallelization setup
    % ===============================

    % Unique identifier for the worker
    workerID = feature('getpid');
    run_name_worker = sprintf('CG_single_worker%d', workerID);

    % Global result folder
    result_path_global = fullfile(resultsPath, 'CG_single/');

    % Worker-specific folder
    result_path_worker = fullfile(result_path_global, run_name_worker);
    if ~exist(result_path_worker, 'dir')
        mkdir(result_path_worker);
    end

    % Excel input file for this worker
    excel_file_worker = fullfile(result_path_worker, [run_name_worker '.xlsx']);
    
    % Start from a clean copy of the base Excel file
    copyfile(excel_file, excel_file_worker);

    % Modify Excel file with parameters
    parameter_rows = find_parameter_rows(excel_file_worker, fieldnames(optimized_parameters));
    replace_parameters(excel_file_worker, parameter_rows, optimized_parameters);

    % Copy constants file if needed
    const_excel = fullfile(result_path_worker, 'CONSTANTS_excel.xlsx');
    if ~exist(const_excel, 'file')
        copyfile(fullfile(result_path_global, 'CONSTANTS_excel.xlsx'), const_excel);
    end

    % Save current path to restore later
    oldPath = path;

    % Add source files to launch CryoGrid
    addpath(genpath(sourcePath));

    % Run CryoGrid
    run_CG_from_excel(run_name_worker, 'CONSTANTS_excel', result_path_global, sourcePath);
    pause(3);  % Safety pause

    % Restore path
    path(oldPath);

    % ===============================
    % Read simulated results
    % ===============================

    files = dir(fullfile(result_path_worker, '*.mat'));
    files = files(~[files.isdir]);

    if isempty(files)
        error('❌ No result file found in %s', result_path_worker);
    end

    % Find the most recent file
    [~, idx] = max([files.datenum]);
    file = fullfile(result_path_worker, files(idx).name);

    % Add sensor ID to the filename
    [~, name, ext] = fileparts(file);
    new_name = sprintf('%s_%s%s', name, sensor_ID, ext);
    new_file = fullfile(result_path_worker, new_name);

    % Rename the file
    movefile(file, new_file);
    file = new_file;

    % ===============================
    % Extract reference and model data
    % ===============================
    
    [dates_cryo, temp_cryo] = extract_mean_temperature(file, info.altitude, info.sensor_depth, dt, info.end_time);
    [dates_excel, temp_excel] = extract_excel_temperature(sensor_data_file);

    % Compute mean temperature for initial profile adjustment
    T_mean_cryo = average_temperature_over_years(temp_cryo, dates_cryo);

    % Synchronize data lengths
    [dates_cryo, temp_cryo, dates_excel, temp_excel] = synchronize_data(dates_cryo, temp_cryo, dates_excel, temp_excel);

    % Score model with seasonal weighting
    [seasonal_score, stats_details] = score_model_seasonal(temp_excel, temp_cryo, dates_excel, dates_cryo, 7, season_weights);

    post_score = 0;
    total_score = seasonal_score;

    % Add score for post-snow performance
    if (50 < mean_snow_days_per_year) && ~isempty(snow_dates)
        post_snow = evaluate_post_snow(temp_excel, temp_cryo, dates_excel, snow_dates, 5);
        post_score = max(0, min(100, post_snow));

        during_snow = evaluate_during_snow(temp_excel, temp_cryo, dates_excel, snow_dates);
        during_score = max(0, min(100, during_snow));

        % Weighted: 80% seasonal / 10% post-snow / 10% during-snow
        total_score = 0.8 * seasonal_score + 0.1 * post_score + 0.1 * during_score;
    end

    % ===============================
    % Create temporary folder
    % ===============================
    temp_folder = fullfile(resultsPath, 'CG_single', 'temp_results');
    if ~exist(temp_folder, 'dir')
        mkdir(temp_folder);
    end

    % ===============================
    % Unique identifier for this iteration
    % ===============================
    uuid = char(java.util.UUID.randomUUID);
    temp_file_name = sprintf('temp_result_%s_%s.mat', sensor_ID, uuid);
    temp_file_path = fullfile(temp_folder, temp_file_name);

    % ===============================
    % Handle initial temperature profile
    % ===============================
    best_score_file = fullfile(temp_folder, sprintf('best_score_%s.mat', sensor_ID));
    lock_best_score = [best_score_file, '.lock'];
    timeout = 30;
    t_start = tic;

    while exist(lock_best_score, 'file')
        lock_info = dir(lock_best_score);
        lock_time = datetime(lock_info.datenum, 'ConvertFrom', 'datenum');
        age_lock = seconds(datetime('now') - lock_time);
        if age_lock > 10
            warning('⏱️ Old lock detected (%ds), forcing deletion.', round(age_lock));
            delete(lock_best_score);
            break;
        end
        pause(0.1);
        if toc(t_start) > timeout
            error('⛔ Timeout waiting for lock %s.', lock_best_score);
        end
    end

    fid = fopen(lock_best_score, 'w');
    fprintf(fid, 'Lock created at %s\n', datestr(now));
    fclose(fid);

    cleanup_lock = onCleanup(@() delete(lock_best_score));

    if isfile(best_score_file)
        S = load(best_score_file);
        best_score_global = S.best_score_global;
        previous_score = best_score_global.score;
    else
        previous_score = -inf;
    end

    improved = total_score > previous_score;

    if improved
        % Adjust initial temperature profile
        file = find_forcing_file(forcing_folder, string(sensor_ID));

        T_mean_ref = extract_air_temperature(file, datetime(1991,1,1), datetime(2020,12,31));
        T_mean_sensor = extract_air_temperature(file, info.start_time, info.end_time);

        T_ini = T_mean_cryo - abs(T_mean_sensor - T_mean_ref);

        param_row = find_parameter_rows(excel_file, {'points'});
        replace_initial_temperature(excel_file, param_row.points, T_ini);

        best_score_global.score = total_score;
        best_score_global.T_ini = T_ini;
        save(best_score_file, 'best_score_global');

        fprintf('✅ Initial temperature profile updated: T = %d °C.\n', T_ini);
        pause(3);
    else
        if isfield(best_score_global, 'T_ini')
            T_ini = best_score_global.T_ini;
        else
            T_ini = 0;
        end
    end

    % ===============================
    % Secure iteration counter
    % ===============================
    counter_file = fullfile(temp_folder, 'iteration_counter.mat');
    counter_lock = [counter_file, '.lock'];
    timeout = 30;
    t_start = tic;
    
    % Create lock
    while exist(counter_lock, 'file')
        pause(0.05);
        if toc(t_start) > timeout
            error('Timeout waiting for iteration lock.');
        end
    end
    fid = fopen(counter_lock,'w'); fclose(fid);
    cleanup_lock_counter = onCleanup(@() delete(counter_lock));
    
    % Load counter and increment
    if isfile(counter_file)
        S = load(counter_file, 'current_iter');
        current_iter = S.current_iter + 1;
    else
        current_iter = 1;
    end
    save(counter_file, 'current_iter');

    % ===============================
    % Save results
    % ===============================
    unique_result = struct( ...
        'iteration', current_iter, ...
        'score', total_score, ...
        'params', optimized_parameters, ...
        'stats', stats_details, ...
        'T_sim', temp_cryo, ...
        'dates', dates_excel, ...
        'T_obs', temp_excel, ...
        'T_ini', T_ini ...
    );

    try
        save(temp_file_path, 'unique_result');
        fprintf("✅ Temporary result saved: %s\n", temp_file_name);
    catch ME
        warning("❌ Failed to save temporary iteration result: %s\n%s", temp_file_name, ME.message);
    end

    % Negate for minimization
    objective = -total_score;

    if ~isscalar(objective) || ~isnumeric(objective) || isnan(objective) || isinf(objective)
        error('Objective function must return a valid numeric scalar.');
    end

    varargout = {objective};

end
