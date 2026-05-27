function run_parallel_program(sensor_ID, source_path, daily_mean_sensors_folder, sensors_file, excel_file, num_iterations, season_weights, forcing_folder, config_params, dt, results_path)
% Main function to automatically run all calibration steps 
% for CryoGrid for a given sensor

    clc;
    clear objectiveFcn;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 1: Update the CryoGrid file to match the studied sensor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Avoid conflict between MATLAB's Nanmin and CryoGrid's Nanmin
    rmpath(genpath(source_path));
    
    % Find the correct reference data file for the specified sensor
    sensor_data_file = find_sensor_file(daily_mean_sensors_folder, string(sensor_ID));

    % Retrieve information for the studied sensor
    [~, sensor_info] = get_sensor_info(string(sensor_ID), sensors_file, forcing_folder);
    
    % Update the CG_single.xlsx file BEFORE optimization so that all 
    % information is correctly adapted to the sensor

    % Structure the retrieved sensor information
    fixed_params = struct();
    fields = fieldnames(sensor_info);
    for i = 1:length(fields)
        field_name = fields{i};
        fixed_params.(field_name) = sensor_info.(field_name);
    end
    
    % Detect parameter rows in CG_single.xlsx
    rows = find_param_rows(excel_file, fieldnames(fixed_params));

    % Replace sensor values in CG_single.xlsx
    replace_params(excel_file, rows, fixed_params);

    % Pause to ensure Excel file is saved
    pause(3);

    % Replace initial temperature in CG_single.xlsx
    
    % Find row of initial temperature values
    temp_row = find_param_rows(excel_file, {'points'});
    
    % Initialize temperature profile to zero (to be updated later)
    init_temp = 0;
    
    % Replace in Excel file
    replace_init_temp(excel_file, temp_row.points, init_temp);

    % Pause to ensure Excel file is saved
    pause(3);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % End of Step 1: Sensor information is now retrieved and CryoGrid's
    % CG_single.xlsx file is updated with sensor-specific fixed parameters
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 2: Analyze snow presence for the studied sensor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Temperature variation threshold between two days to determine snow.
    % Lower threshold detects only strong snow periods.
    variation_threshold = 0.05;
    
    % Minimum duration for stable temperatures to be considered as snow.
    % Set to 2 days to count all snow days. Increase to detect only long snow periods.
    min_duration = 2;

    % Analyze sensor data: count snow days, extract useful info, 
    % and plot snow periods
    [~, ~, ~, ~, avg_snow_days_per_year, snow_dates] = ...
        detect_snow_presence(sensor_data_file, variation_threshold, min_duration);

    % ⚠️ Note: Excel already has a column indicating snow presence for sensors.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % End of Step 2: Snow periods for the studied sensor are now retrieved
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 3: Optimize model for the studied sensor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Define variables to optimize with physical bounds
    params = [];

    param_fields = fieldnames(config_params);

    for i = 1:length(param_fields)
        name = param_fields{i};
        conf = config_params.(name);

        % Always optimized parameters
        if isfield(conf, 'always_optimize') && conf.always_optimize
            if isfield(conf, 'distribution')
                params = [params; optimizableVariable(name, conf.bounds, 'Type','real')];
            else
                params = [params; optimizableVariable(name, conf.bounds)];
            end
            continue
        end

        % Snow-dependent parameters
        if (15 < avg_snow_days_per_year) && (avg_snow_days_per_year < 50) && isfield(conf, 'low_snow_bounds')
            params = [params; optimizableVariable(name, conf.low_snow_bounds)];
        elseif avg_snow_days_per_year >= 50 && isfield(conf, 'high_snow_bounds')
            params = [params; optimizableVariable(name, conf.high_snow_bounds)];
        else
            fixed_params.(name) = conf.fixed_if_no_snow;
        end
    end

    delete(gcp('nocreate'));  % Close pool if exists
    parpool('local');         % Start a new local pool

    % Objective function handle: pass fixed parameters since bayesopt 
    % only passes variables. Allows plotting after optimization.
    objFcn = @(x) objectiveFunction_parallel(x, excel_file, sensor_data_file, sensor_info, snow_dates, avg_snow_days_per_year, season_weights, source_path, sensor_ID, forcing_folder, dt, results_path, config_params);

    % Run Bayesian optimization (requires MATLAB Statistics & ML Toolbox)
    results = bayesopt(objFcn, params, ...
        'MaxObjectiveEvaluations', num_iterations, ...
        'IsObjectiveDeterministic', true, ...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'Verbose', 1, 'UseParallel', true, ...
        'PlotFcn', {@plotMinObjective});

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % End of Step 3: Optimization finished; optimal parameter set is known
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 4: Post-processing to analyze optimization efficiency
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Post-optimization analysis: convergence plots, parameter influence, 
    % and correlation maps
    analyze_bayesopt_optimization(results);



    % =========================================================================
    % Post-processing: merge and save optimization results
    % =========================================================================

    temp_folder = fullfile(results_path, 'CG_single', 'temp_results');
    final_result_file = fullfile(results_path, 'CG_single', 'bayesopt_results.mat');
    merge_bayesopt_results(temp_folder, sensor_ID, final_result_file);



    % ====================================================================================
    % Plot comparison between best and first simulation
    % with sensor data
    % ====================================================================================
    
    global_result_path = fullfile(results_path, 'CG_single\');
    
    S = load(fullfile(global_result_path, 'results_bayesopt.mat'));
    R = S.results;
    
    % Compute number of workers to pick the first iteration of bayesopt
    
    p = gcp('nocreate');
    if isempty(p)
        nWorkers = 1;
    else
        nWorkers = p.NumWorkers;
    end
    
    idx_ini = min(nWorkers, length(R)) + 1;  % ensure we don't exceed R size
    
    scores = cellfun(@(x) x.score, R);
    [~, idx_best] = max(scores);
    
    best_result = R{idx_best};
    first_result = R{idx_ini};
    
    figure;
    plot(R{1}.dates, R{1}.T_obs, 'k', 'DisplayName', 'Observed');
    hold on;
    plot(best_result.dates, best_result.T_sim, '--g', 'DisplayName', 'Best simulation');
    plot(first_result.dates, first_result.T_sim, ':r', 'DisplayName', 'First simulation');
    legend;
    title(sprintf('Simulation comparison — Best (%.4f) vs First (%.4f)', ...
        best_result.score, first_result.score));
    xlabel('Time'); ylabel('Temperature (°C)');
    grid on;
    
    
    % =========================================================================
    % Extract indices and parameters of the best simulation
    % =========================================================================
    
    
    % === Extract statistical info and parameters ===
    scores = cellfun(@(x) x.score, R);
    best_score = max(scores);
    idx_best_all = find(scores == best_score);
    
    all_results = [];
    
    % === Prepare result structure ===
    for k = idx_best_all
        best_result = R{k};
        global_stats = best_result.stats.Global;
        best_params = best_result.params;
    
        final_results = struct( ...
            'R2', global_stats.R2, ...
            'RMSE', global_stats.RMSE, ...
            'Mean_Bias', global_stats.Ecart_Moyenne, ...
            'albedo', best_params.albedo, ...
            'z0', best_params.z0, ...
            'T_ini', best_result.T_ini, ...  % Ensure it's saved correctly in each result
            'score', best_result.score, ...
            'iteration', k ...
        );
    
        % Add snow_fraction if it exists
        if isfield(best_params, 'snow_fraction')
            final_results.snow_fraction = best_params.snow_fraction;
        end
    
        all_results = [all_results; final_results];
    end
    
    % === Convert to table and export to Excel ===
    T = struct2table(final_results);
    
    if ~exist(results_path, 'dir')
        mkdir(results_path);
    end
    
    % Build full file path
    filename = fullfile(results_path, sprintf('results_%s.xlsx', sensor_ID));
    
    % Write to file
    writetable(T, filename);
    
    fprintf('✅ Results saved in file: %s\n', filename);
    
    
    % =========================================================================
    % Optimization table
    % =========================================================================
    
    % Retrieve data from BayesOpt result
    X = results.XTrace;
    n = height(X);
    
    T = table;
    T.Iter = (1:n)';
    
    % Number of workers (if parallelization is active)
    p = gcp('nocreate');
    if isempty(p)
        nWorkers = 1;
    else
        nWorkers = p.NumWorkers;
    end
    T.Active_workers = repmat(nWorkers, n, 1);
    
    % Evaluation result for each iteration
    if isprop(results, 'EvaluationResults') && isfield(results.EvaluationResults, 'Result')
        T.Eval_result = results.EvaluationResults.Result;
    else
        % Default value if not available
        T.Eval_result = repmat('Best', n, 1);
    end
    
    % Objective traces and runtime
    T.Objective = results.ObjectiveTrace;
    
    % Runtime (if available)
    if isprop(results, 'IterationTimeTrace')
        T.Objective_runtime = results.IterationTimeTrace;
    else
        T.Objective_runtime = NaN(n,1);
    end
    
    % Rebuild best observed score at each iteration
    T.BestSoFar_observed = cummin(results.ObjectiveTrace);
    
    % Estimated (probabilistic) best value cannot be rebuilt, set to NaN or omit
    T.BestSoFar_estimated = NaN(n,1);  % Remove this line if not needed
    
    % Dynamically add all tested parameters
    T = [T, X];
    
    % Excel file name
    filename = fullfile(results_path, ['results_full_bayesopt_' sensor_ID '.xlsx']);
    
    % Save
    writetable(T, filename, 'FileType', 'spreadsheet');
    
    fprintf('✅ Full results saved in: %s\n', filename);


    % =========================================================================
    % Comparison of results with snowfall data
    % =========================================================================

    if avg_snow_days_per_year > 15
        % Load snowfall data
        file_name = find_forcing_file(forcing_folder, char(sensor_ID));
        file_path = fullfile(forcing_folder, file_name);
        [snowfall, snowfall_dates] = extract_snowfall(file_path, info.start_time, info.end_time);
    
        figure;
        hold on;
    
        % === Left axis: Temperatures ===
        yyaxis left
        plot(R{1}.dates, R{1}.T_obs, '-k', 'LineWidth', 1.5, 'DisplayName', 'Sensor (reference)');
        plot(best_result.dates, best_result.T_sim, '--g', 'LineWidth', 1.5, 'DisplayName', 'Best iteration');
        ylabel('Temperature (°C)');
        set(gca, 'YColor', 'white'); % Left axis color
    
        % === Right axis: Snowfall ===
        yyaxis right
        bar(snowfall_dates, snowfall, ...
            'FaceAlpha', 0.5, ...
            'FaceColor', [0.3 0.6 1], ...
            'EdgeColor', 'none', ...
            'DisplayName', 'Snowfall');
        ylabel('Snowfall (mm/day)');
        set(gca, 'YColor', [0.3 0.6 1]); % Right axis color
    
        % === Axes, legend and title ===
        xlabel('Date');
        title('Simulation vs Sensor Comparison with Snowfall');
        legend('Location', 'best');
        grid on;
    end


    % ====================================================================================
    % Seasonal scatter plot
    % ====================================================================================

    % Data
    obs = R{1}.T_obs;
    dates = R{1}.dates;
    sim = R{idx_best}.T_sim;

    % === Assigning seasons ===
    seasons = strings(size(dates));
    for i = 1:length(dates)
        month_val = month(dates(i));
        if ismember(month_val, [12, 1, 2])
            seasons(i) = 'Winter';
        elseif ismember(month_val, [3, 4, 5])
            seasons(i) = 'Spring';
        elseif ismember(month_val, [6, 7, 8])
            seasons(i) = 'Summer';
        else
            seasons(i) = 'Autumn';
        end
    end
    
    % Colors associated with seasons
    colors = containers.Map(...
        ['Winter', 'Spring', 'Summer', 'Autumn'], ...
        {[0.2 0.6 1], [0.4 0.8 0.4], [1 0.6 0.2], [0.7 0.5 1]});
    
    % Ordered list of seasons
    season_list = ['Winter', 'Spring', 'Summer', 'Autumn'];
    
    % === Seasonal comparative plot ===
    figure;
    for k = 1:4
        current_season = season_list(k);
        idx = seasons == current_season;
    
        subplot(2,2,k);
        hold on;
    
        scatter(obs(idx), sim(idx), 25, ...
            'filled', 'MarkerFaceColor', colors(current_season));
    
        % Reference line y = x
        minT = min([obs(idx); sim(idx)], [], 'omitnan');
        maxT = max([obs(idx); sim(idx)], [], 'omitnan');
        plot([minT, maxT], [minT, maxT], '--k', 'LineWidth', 1);
    
        % RMSE calculation
        rmse = sqrt(mean((sim(idx) - obs(idx)).^2, 'omitnan'));
        text(minT + 0.5, maxT - 1, sprintf('RMSE = %.2f °C', rmse), ...
            'FontSize', 10, 'Color', 'k', 'BackgroundColor', 'w');
    
        xlabel('Observed (°C)');
        ylabel('Simulated (°C)');
        title(current_season);
        axis equal;
        grid on;
    end
    
    sgtitle('Observed vs Simulated Comparison by Season — Best Iteration');


    % ====================================================================================
    % UNCERTAINTY ENVELOPE
    % ====================================================================================

    % Check if results exist
    if isempty(R)
        warning('⚠️ No simulation results recorded.');
        return;
    end
    
    % Check sizes and content
    cellfun(@(x) size(x.T_sim), R, 'UniformOutput', false)

    % Check if any T_sim is missing
    any(cellfun(@(x) isempty(x.T_sim), R))

    % Retrieve simulated temperature vectors
    allTemps = cellfun(@(x) x.T_sim(:), R, 'UniformOutput', false);  % cell array of T_sim vectors

    matTemp = cat(2, allTemps{:});
    
    % Envelope calculation
    temp_min = min(matTemp, [], 2);
    temp_max = max(matTemp, [], 2);
    temp_mean = mean(matTemp, 2, 'omitnan');
    
    % Score of each iteration
    scores = cellfun(@(x) x.score, R);
    [~, idx_best] = max(scores);  
    temp_best = R{idx_best}.T_sim(:);
    
    % Plotting
    refDates = R{1}.dates;
    refTemps = R{1}.T_obs;
    
    figure;
    hold on;
    
    size(refDates)
    size(temp_min)
    size(temp_max)

    % Envelope
    fill([refDates; flipud(refDates)], ...
         [temp_min; flipud(temp_max)], ...
         [0.4 0.4 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', ...
         'DisplayName', 'Uncertainty envelope');
    
    % Mean of simulations
    plot(refDates, temp_mean, 'b--', 'LineWidth', 1.2, ...
         'DisplayName', 'Mean of simulations');
    
    % Best simulation
    plot(refDates, temp_best, 'b-', 'LineWidth', 1.5, ...
         'DisplayName', 'Best simulation');
    
    % Observed data
    plot(refDates, refTemps, 'k', 'LineWidth', 1.5, ...
         'DisplayName', 'Sensor data (ref.)');
    
    % Aesthetics
    xlabel('Date');
    ylabel('Temperature (°C)');
    title('Final Bayesian optimization results');
    legend('Location', 'best');
    grid on;

    % =========================================================================
    % File cleanup and figure saving
    % =========================================================================

    % === Define output folder (same as Excel file) ===
    figures_folder = fullfile(results_path, sprintf('Figures_%s', sensor_ID));
    if ~exist(figures_folder, 'dir')
        mkdir(figures_folder);
    end

    % === Save all open figures ===
    figs = findall(0, 'Type', 'figure');
    for i = 1:numel(figs)
        fig_name = sprintf('Figure_%d.png', i);
        saveas(figs(i), fullfile(figures_folder, fig_name));
    end
    fprintf('📊 All figures saved in: %s\n', figures_folder);

    % === Close all figures after saving ===
    close all;
    
    % === Cleanup ===
    global_results_folder = fullfile(results_path, 'CG_single');
    
    if exist(global_results_folder, 'dir')
        % Remove worker folders
        worker_folders = dir(fullfile(global_results_folder, 'CG_single_worker*'));
        for k = 1:length(worker_folders)
            worker_folder_path = fullfile(worker_folders(k).folder, worker_folders(k).name);
            if worker_folders(k).isdir
                try
                    rmdir(worker_folder_path, 's');
                catch ME
                    warning('❌ Cannot delete %s: %s', worker_folder_path, ME.message);
                end
            end
        end
    
        % Delete bayesopt results file
        bayesopt_file = fullfile(global_results_folder, 'resultats_bayesopt.mat');
        if exist(bayesopt_file, 'file')
            try
                delete(bayesopt_file);
            catch ME
                warning('❌ Error deleting %s: %s', bayesopt_file, ME.message);
            end
        end
    
        % Delete temporary folder
        temp_folder = fullfile(global_results_folder, 'resultats_temp');
        if exist(temp_folder, 'dir')
            try
                rmdir(temp_folder, 's');
            catch ME
                warning('❌ Cannot delete %s: %s', temp_folder, ME.message);
            end
        end
    else
        warning('📁 Global folder %s does not exist.', global_results_folder);
    end
    
    fprintf('🧹 Cleanup completed.\n');
end


