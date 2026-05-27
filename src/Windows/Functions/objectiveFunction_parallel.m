function varargout = objectiveFunction_parallel(x, excel_file, sensor_data_file, sensor_info, snow_dates, avg_snow_days_per_year, season_weights, sourcePath, sensor_ID, forcing_folder, dt, resultsPath, params_config)

    % =====================================================================
    % Setup structure for parameters to optimize
    % =====================================================================

    if istable(x)
        x = table2struct(x);
    end

    optimized_params = x;

    if ~isfield(optimized_params, 'snow_fraction')
        warning('snow_fraction not present: forced to 0');
        optimized_params.snow_fraction = 0;  
    end

    disp(optimized_params);
    
    % =====================================================================
    % Parallelization setup
    % =====================================================================
    
    % Unique identifier for the worker
    workerID = feature('getpid');
    worker_run_name = sprintf('CG_single_worker%d', workerID);
    
    % Global result folder
    global_results_folder = fullfile(char(resultsPath), 'CG_single\');

    % Worker-specific folder
    worker_results_folder = fullfile(global_results_folder, worker_run_name);
    if ~exist(worker_results_folder, 'dir')
        mkdir(worker_results_folder);
    end
    
    % Excel input file for this worker
    excel_file_worker = fullfile(worker_results_folder, [worker_run_name '.xlsx']);

    % Start from a clean copy of the base Excel file
    copyfile(char(excel_file), char(excel_file_worker));
    
    % Modify Excel file with parameters
    lines_to_update = find_parameter_rows(excel_file_worker, fieldnames(optimized_params));
    replace_parameters(excel_file_worker, lines_to_update, optimized_params);

    % Copy constants file if needed
    constants_file = fullfile(worker_results_folder, 'CONSTANTS_excel.xlsx');
    if ~exist(constants_file, 'file')
        copyfile(fullfile(global_results_folder, 'CONSTANTS_excel.xlsx'), constants_file);
    end

    % Saved current path to restore later
    oldPath = path;

    % Add source files to launch CryoGrid
    addpath(genpath(sourcePath));
    
    % Run CryoGrid
    run_CG_from_excel(worker_run_name, 'CONSTANTS_excel', char(global_results_folder), char(sourcePath));
    pause(5);  % Safety pause

    % Restore path
    path(oldPath);

    % =====================================================================
    % Load simulation results
    % =====================================================================

    files = dir(fullfile(worker_results_folder, '*.mat'));
    files = files(~[files.isdir]);

    if isempty(files)
        error('❌ No result file found in %s', worker_results_folder);
    end

    % Find the most recent file
    [~, idx] = max([files.datenum]);
    file = fullfile(worker_results_folder, files(idx).name);
    
    % Add sensor ID to the filename
    [~, name, ext] = fileparts(file);
    new_name = sprintf('%s_%s%s', name, sensor_ID, ext);
    new_file = fullfile(worker_results_folder, new_name);
    
    % Rename the file
    movefile(file, new_file);
    file = new_file;

    % ==================================================
    % Extract reference and model data
    % ==================================================

    [dates_cryo, temp_cryo] = extract_mean_temperature(file, sensor_info.altitude, sensor_info.sensor_depth, dt, sensor_info.end_time);
    [dates_excel, temp_excel] = extract_temp_excel(sensor_data_file);

    % Compute mean temperature for initial profile adjustement
    T_mean_cryo = average_temperature_over_years(temp_cryo, dates_cryo);
    
    % Synchronize data lenghths
    [dates_cryo, temp_cryo, dates_excel, temp_excel] = synchronize_data(dates_cryo, temp_cryo, dates_excel, temp_excel);

    % Score model with seasonal weighting
    [season_score, stats_details] = score_model_seasonal(temp_excel, temp_cryo, dates_excel, dates_cryo, 7, season_weights);

    post_score = 0;
    total_score = season_score;

    % Add score for post-snow performance
    if (avg_snow_days_per_year > 50) && ~isempty(snow_dates)
        post_snow_score = evaluate_post_snow(temp_excel, temp_cryo, dates_excel, snow_dates, 5);
        post_score = max(0, min(100, post_snow_score));

        during_snow_score = evaluate_during_snow(temp_excel, temp_cryo, dates_excel, snow_dates);
        during_score = max(0, min(100, during_snow_score));

        % Weighted: 80% seasonal / 10% post-snow / 10% during-snow
        total_score = 0.8 * season_score + 0.1 * post_score + 0.1 * during_score;
    end

    % ============================
    % Create a temporary folder
    % ============================
    temp_folder = fullfile(resultsPath, 'CG_single', 'temp_results');
    if ~exist(temp_folder, 'dir')
        mkdir(temp_folder);
    end

    % =====================================
    % Unique identifier for this iteration
    % =====================================
    uuid = char(java.util.UUID.randomUUID);
    temp_file_name = sprintf('temp_result_%s_%s.mat', sensor_ID, uuid);
    temp_file_path = fullfile(temp_folder, temp_file_name);

    % =====================================================================
    % Initial temperature profile adjustment
    % =====================================================================
    best_score_file = fullfile(temp_folder, sprintf('best_score_%s.mat', sensor_ID));
    lock_file = [char(best_score_file), '.lock'];
    timeout = 30;
    t_start = tic;
    while exist(lock_file, 'file')
        lock_info = dir(lock_file);
        lock_time = datetime(lock_info.datenum, 'ConvertFrom', 'datenum');
        age_lock = seconds(datetime('now') - lock_time);

        if age_lock > 10
            warning('⏱️ Lock too old (%ds), forcing removal.', round(age_lock));
            delete(lock_file);
            break;
        end
        pause(0.1);
        if toc(t_start) > timeout
            error('⛔ Timeout waiting for lock %s.', lock_file);
        end
    end

    fid = fopen(lock_file, 'w');
    fprintf(fid, 'Lock created at %s\n', datestr(now));
    fclose(fid);
    c_cleanup = onCleanup(@() delete(lock_file));

    if isfile(best_score_file)
        S = load(best_score_file);
        best_global_score = S.best_global_score;
        previous_score = best_global_score.score;
    else
        previous_score = -inf;
    end

    improved = total_score > previous_score;

    if improved
        forcing_file = find_forcing_file(forcing_folder, string(sensor_ID));
        T_mean_ref_all = extract_air_temperature(forcing_file, datetime(1991, 1, 1), datetime(2020, 12, 31));
        T_mean_sensor = extract_air_temperature(forcing_file, sensor_info.start_time, sensor_info.end_time);
        T_ini = T_mean_cryo - abs(T_mean_sensor - T_mean_ref_all);

        line_param = find_parameter_rows(excel_file, {'points'});
        replace_initial_temp(excel_file, line_param.points, T_ini);

        best_global_score.score = total_score;
        best_global_score.T_ini = T_ini;
        save(best_score_file, 'best_global_score');

        fprintf('✅ Initial temperature profile updated to T = %d °C.\n', T_ini);
        pause(5);
    else
        if isfield(best_global_score, 'T_ini')
            T_ini = best_global_score.T_ini;
        else
            T_ini = 0;
        end
    end

    % ============================
    % Secure iteration counter
    % ============================
    counter_file = fullfile(temp_folder, 'iteration_counter.mat');
    counter_lock = char(strcat(counter_file, '.lock'));
    timeout = 30;
    t_start = tic;

    % Create lock
    while exist(counter_lock, 'file')
        pause(0.1);
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


    % =====================================================================
    % Collect and save results
    % =====================================================================

    unique_result = struct( ...
        'iteration', current_iter, ...
        'score', total_score, ...
        'params', optimized_params, ...
        'stats', stats_details, ...
        'T_sim', temp_cryo, ...
        'dates', dates_excel, ...
        'T_obs', temp_excel, ...
        'T_ini', T_ini ...
    );

    try
        save(temp_file_path, 'unique_result');
        fprintf('✅ Temporary result saved: %s\n', temp_file_name);
    catch ME
        warning('❌ Failed to save local iteration result: %s\n%s', temp_file_name, ME.message);
    end

    % =====================================================================
    % Return negative score for minimization
    % =====================================================================

    objective = -total_score;

    if ~isscalar(objective) || ~isnumeric(objective) || isnan(objective) || isinf(objective)
        error('Objective function must return a valid numeric scalar.');
    end

    varargout = {objective};
end
