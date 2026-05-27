function run_program_parallel(sensor_ID, source_path, daily_mean_sensors_folder, sensors_file, excel_file, num_iterations, season_weights, forcing_folder, config_params, dt, results_path)
% Main function to automatically run all calibration steps 
% for CryoGrid for a given sensor

    clc;
    clear objectiveFunction_parallel;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 1: Update the CryoGrid file to match the studied sensor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    % Avoid conflict between MATLAB's Nanmin and CryoGrid's Nanmin
    rmpath(genpath(source_path));
    
    % Find the correct reference data file for the specified sensor
    sensor_data_file = find_measure_file(daily_mean_sensors_folder, string(sensor_ID));

    % Retrieve information for the studied sensor
    [~, sensor_info] = get_sensor_info(string(sensor_ID), sensors_file, forcing_folder, dt);
    
    % Update the CG_single.xlsx file BEFORE optimization so that all 
    % information is correctly adapted to the sensor

    % Structure the retrieved sensor information
    fixed_params = struct();
    fields = fieldnames(sensor_info);
    for i = 1:length(fields)
        field_name = fields{i};
        fixed_params.(field_name) = sensor_info.(field_name);
    end

    disp(forcing_folder);
    
    % Detect parameter rows in CG_single.xlsx
    rows = find_parameter_rows(excel_file, fieldnames(fixed_params));

    % Replace sensor values in CG_single.xlsx
    replace_parameters(excel_file, rows, fixed_params);

    % Pause to ensure Excel file is saved
    pause(5);

    % Replace initial temperature in CG_single.xlsx
    
    % Find row of initial temperature values
    temp_row = find_parameter_rows(excel_file, {'points'});
    
    % Initialize temperature profile to zero (to be updated later)
    init_temp = 0;
    
    % Replace in Excel file
    replace_initial_temp(excel_file, temp_row.points, init_temp);

    % Pause to ensure Excel file is saved
    pause(5);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % End of Step 1: Sensor information is now retrieved and CryoGrid's
    % CG_single.xlsx file is updated with sensor-specific fixed parameters
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 2: Analyze snow presence for the studied sensor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Temperature variation threshold between two days to determine snow presence.
    % The lower it is, the more it detects snow period with very low variations.
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
            params = [params; optimizableVariable(name, conf.bounds, 'Type','real')];
            
        elseif isfield(conf, 'low_snow_bounds') || isfield(conf, 'high_snow_bounds')
            % Snow-dependent parameters
            if (15 < avg_snow_days_per_year) && (avg_snow_days_per_year < 50) && isfield(conf, 'low_snow_bounds')
                params = [params; optimizableVariable(name, conf.low_snow_bounds)];
            elseif avg_snow_days_per_year >= 50 && isfield(conf, 'high_snow_bounds')
                params = [params; optimizableVariable(name, conf.high_snow_bounds)];
            else
                fixed_params.(name) = conf.fixed_if_no_snow;
            end
        end
    end

    delete(gcp('nocreate'));  % Close pool if exists
    parpool('local');         % Start a new local pool

    % Objective function handle: pass fixed parameters since bayesopt 
    % only passes variables. Allows plotting after optimization.
    objFcn = @(x) objectiveFunction_parallel(x, excel_file, sensor_data_file, sensor_info, snow_dates, avg_snow_days_per_year, season_weights, source_path, sensor_ID, forcing_folder, dt, results_path, config_params);

    % Run Bayesian optimization (requires MATLAB Statistics & Machine Learning Toolbox)
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
    final_result_file = fullfile(results_path, 'CG_single', ...
        sprintf('bayesopt_results_%s.mat', sensor_ID));
    merge_bayesopt_results(temp_folder, sensor_ID, final_result_file);



    % ====================================================================================
    % Plot comparison between best and first simulation
    % with sensor data
    % ====================================================================================
    
    global_result_path = fullfile(results_path, 'CG_single\');
    
    S = load(fullfile(global_result_path, ...
        sprintf('bayesopt_results_%s.mat', sensor_ID)));
    R = S.results;

    % ---------------------------------
    % Sort results by iteration number
    % ---------------------------------
    iterations = cellfun(@(x) x.iteration, R);
    [sorted_iterations, sort_idx] = sort(iterations);

    R = R(sort_idx);

    % ---------------------------------
    % Identify best simulation
    % ---------------------------------
    scores = cellfun(@(x) x.score, R);
    [~, idx_best] = max(scores);
    best_result = R{idx_best};

    % -----------------------------------------------------------
    % Identify 'first' simulation according to number of workers
    % -----------------------------------------------------------
    
    p = gcp('nocreate');
    if isempty(p)
        nWorkers = 1;
    else
        nWorkers = p.NumWorkers + 1;
    end
    
    % Find the simulation whose iteration matches the number of workers
    idx_first = find(sorted_iterations == nWorkers, 1);
    if isempty(idx_first)
        idx_first = 1;  % fallback if not found
    end
    first_result = R{idx_first};


    % -----------------------------------------------------------
    % Plot comparaison
    % -----------------------------------------------------------
    
    figure;
    plot(R{1}.dates, R{1}.T_obs, 'k', 'DisplayName', 'Observed');
    hold on;
    plot(best_result.dates, best_result.T_sim, '--r', 'DisplayName', sprintf('Best simulation (iter %d)', best_result.iteration));
    plot(first_result.dates, first_result.T_sim, ':b', 'DisplayName', sprintf('First simulation (iter 1)'));
    legend;
    title(sprintf('Simulation comparison — Best (%.1f) vs First (%.1f)', ...
        best_result.score, first_result.score));
    xlabel('Time'); ylabel('Temperature (°C)');
    grid on;
    
    
    % =========================================================================
    % Retrieve best simulation stats and parameters
    % =========================================================================
    

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
            'Mean_Diff', global_stats.Mean_Diff, ...
            'albedo', best_params.albedo, ...
            'z0', best_params.z0, ...
            'T_ini', best_result.T_ini, ...  % Ensure it's saved correctly in each result
            'score', best_result.score, ...
            'iteration', best_result.iteration ...
        );
    
        % Add snow_fraction if it exists
        if isfield(best_params, 'snow_fraction')
            final_results.snow_fraction = best_params.snow_fraction;
        end
        
        % === Add seasonal Mean_Diff values (simple version) ===
        season_keys = {'winter', 'spring', 'summer', 'autumn'};
        season_labels = {'Winter','Spring', 'Summer','Autumn'};

        % Pre-create all 4 fields as NaN
        for si = 1:numel(season_keys)
            label = season_labels{si};
            final_results.(sprintf('MeanDiff_%s', label)) = NaN;
        end

        % Fill if data is available
        for si = 1:numel(season_keys)
            key = season_keys{si};
            label = season_labels{si};
            if isfield(best_result.stats, key) && ...
               isfield(best_result.stats.(key), 'stats') && ...
               isfield(best_result.stats.(key).stats, 'Mean_Diff')
                final_results.(sprintf('MeanDiff_%s', label)) = ...
                    best_result.stats.(key).stats.Mean_Diff;
            end
        end
        all_results = [all_results; final_results]; %#ok<AGROW>
    end
    
    % === Convert to table and export to Excel ===
    T = struct2table(all_results);

    if any(strcmp(T.Properties.VariableNames, 'z0'))
        T = renamevars(T, 'z0', 'z0_(m)');
    end
    
    if ~exist(results_path, 'dir')
        mkdir(results_path);
    end
    
    % Build full file path
    output_file = fullfile(results_path, sprintf('results_%s.xlsx', sensor_ID));
    writetable(T, output_file);
    
    fprintf('✅ All best results (score = %.1f) saved to file : %s\n', best_score, output_file);
    
    
    % =========================================================================
    % Optimization result tab
    % =========================================================================
    % ----------- Extract bayesopt results (with initialization info) -----------
    
    % Total number of evaluations (initialization + active optimization)
    X = results.XTrace;
    n = height(X);
    
    % Results table
    T = table;
    T.Iteration = (1:n)';
    
    % Number of workers (if running in parallel)
    p = gcp('nocreate');
    if isempty(p)
        nWorkers = 1;
    else
        nWorkers = p.NumWorkers;
    end
    T.Active_workers = repmat(nWorkers, n, 1);
    
    % Evaluation results (depends on MATLAB version)
    if isprop(results, 'EvaluationResults') && isfield(results.EvaluationResults, 'Result')
        T.Eval_result = results.EvaluationResults.Result;
    else
        T.Eval_result = repmat('Best', n, 1);
    end
    
    % Objective trace and runtime per iteration
    T.Score = results.ObjectiveTrace;
    T.Iteration_runtime = results.IterationTimeTrace;
    
    % Best-so-far observed
    T.BestScore_Observed = cummin(T.Score);
    
    T.Stage = repmat('Acquisition', n, 1);  % All iterations from bayesopt are acquisition
    
    % Add all tested parameters
    T = [T, X];

    % Rename z0 column if present
    if any(strcmp(T.Properties.VariableNames, 'z0'))
        T.Properties.VariableNames{strcmp(T.Properties.VariableNames, 'z0')} = 'z0_(m)';
    end

    % ------------ Handle initial simulations from final_result_file -----------

    S = load(final_result_file);  % results from merge_bayesopt_results
    R = S.results;
    
    % Identify initial simulations (iterations <= nWorkers)
    init_idx = find(cellfun(@(x) x.iteration, R) <= nWorkers);
    
    init_rows = [];
    best_so_far = [];
    for k = init_idx
        res = R{k};
        % Track best score so far
        if isempty(best_so_far)
            best_so_far = -res.score;
        else
            best_so_far = min(best_so_far, -res.score);
        end

        temp_struct = struct( ...
            'Iteration', res.iteration, ...
            'Active_workers', nWorkers, ...
            'Eval_result', 'Initialization', ...
            'Score', -res.score, ...  % negate to match your convention
            'Iteration_runtime', NaN, ...
            'BestScore_Observed', NaN ...
        );
        % Add parameters tested
        param_names = fieldnames(res.params);
        for pn = 1:numel(param_names)
            temp_struct.(param_names{pn}) = res.params.(param_names{pn});
        end
        temp_struct.Stage = 'Initialization';
        init_rows = [init_rows; temp_struct]; %#ok<AGROW>
    end
    
    % Convert to table
    T_init = struct2table(init_rows);

    % Rename z0 in T_init if necessary
    if any(strcmp(T.Properties.VariableNames,'z0_(m)')) && any(strcmp(T_init.Properties.VariableNames,'z0'))
        T_init = renamevars(T_init, 'z0','z0_(m)');
    end
    
    % Reorganize T_init to match the columns in T
    T_init = T_init(:, T.Properties.VariableNames);

    if any(strcmp(T_init.Properties.VariableNames, 'z0'))
        T_init.z0 = [];  % Supprime la colonne z0 de T_init
    end
    
    % Concatenate with existing bayesopt table
    T = [T_init; T];
    
    % Save Excel
    filename = fullfile(results_path, ['bayesopt_results_' sensor_ID '.xlsx']);
    writetable(T, filename, 'FileType', 'spreadsheet');
    fprintf('✅ Results saved to: %s\n', filename);

    % =========================================================================
    % Comparison of results with snowfall data
    % =========================================================================

    if avg_snow_days_per_year > 15
        % Load snowfall data
        file_name = find_forcing_file(forcing_folder, char(sensor_ID));
        file_path = fullfile(forcing_folder, file_name);
        [snowfall, snowfall_date] = extract_snowfall(file_path, sensor_info.start_time, sensor_info.end_time);
    
        figure;
        hold on;
    
        % === Left axis: Temperatures ===
        yyaxis left
        plot(R{1}.dates, R{1}.T_obs, '-k', 'LineWidth', 1.5, 'DisplayName', 'Observed');
        plot(best_result.dates, best_result.T_sim, '--r', 'LineWidth', 1.5, 'DisplayName', 'Best iteration');
        ylabel('Temperature (°C)');
        set(gca, 'YColor', 'white'); % Left axis color
        ylim([min([R{1}.T_obs; best_result.T_sim], [], 'omitnan'), ...
            max([R{1}.T_obs; best_result.T_sim], [], 'omitnan')]);
   
        % Right axis: Snowfall
        yyaxis right
        bar(snowfall_date, snowfall, ...
            'FaceAlpha', 0.5, ...
            'FaceColor', [0.3 0.6 1], ...
            'EdgeColor', 'none', ...
            'DisplayName', 'Snowfall');
        ylabel('Snowfall (mm/day)');
        set(gca, 'YColor', [0.3 0.6 1]);

        xlabel('Date');
        title('Simulation vs Sensor with Snowfall');
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

    % --- Compute global min and max for consistent axes ---
    global_min = min([obs; sim], [], 'omitnan');
    global_max = max([obs; sim], [], 'omitnan');
    
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
        plot([global_min, global_max], [global_min, global_max], '--k', 'LineWidth', 1);
    
        % RMSE calculation
        rmse = sqrt(mean((sim(idx) - obs(idx)).^2, 'omitnan'));

        % MeanDiff recover from seasonal stats
        mean_diff_field = sprintf('MeanDiff_%s', current_season);
        if isfield(final_results, mean_diff_field)
            mean_diff = final_results.(mean_diff_field);
        else
            mean_diff = NaN;
        end

        % Text
        txt = sprintf('RMSE = %.2f °C\nMean ΔT = %2.f °C', rmse, mean_diff);
        text(0.05, 0.9, txt, ...
            'Units', 'normalized', ...
            'FontSize', 9, ...
            'Color', 'k', ...
            'BackgroundColor', 'w');
    
        xlabel('Observed (°C)');
        ylabel('Simulated (°C)');
        title(current_season);
        axis equal;
        xlim([global_min, global_max]);
        ylim([global_min, global_max]);
        grid on;
    end
    
    sgtitle('Observed vs Simulated by Season — Best Iteration');


    % ====================================================================================
    % UNCERTAINTY ENVELOPE
    % ====================================================================================

    % Check if results exist
    if isempty(R)
        warning('⚠️ No simulation results recorded.');
        return;
    end
    
    % Check sizes and content
    cellfun(@(x) size(x.T_sim), R, 'UniformOutput', false);

    % Check if any T_sim is missing
    any(cellfun(@(x) isempty(x.T_sim), R));

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
    set(gcf, 'Renderer', 'painters');
    % Envelope
    fill([refDates; flipud(refDates)], ...
         [temp_min; flipud(temp_max)], ...
         [0.4 0.4 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', ...
         'DisplayName', 'Uncertainty envelope');
    
    % Mean of simulations
    plot(refDates, temp_mean, 'b--', 'LineWidth', 0.8, ...
         'DisplayName', 'Mean of simulations');
    
    % Best simulation
    plot(refDates, temp_best, 'r-', 'LineWidth', 1.2, ...
         'DisplayName', 'Best simulation');
    
    % Observed data
    plot(refDates, refTemps, 'k', 'LineWidth', 1.2, ...
         'DisplayName', 'Observed');
    h = plot(refDates, refTemps, 'k', 'LineWidth', 1.5, ...
         'DisplayName', 'Observed');
    uistack(h, 'top');  % place la courbe tout en haut

    
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
    figs = findall(groot, 'Type', 'figure');
    for i = 1:numel(figs)
        fig_name_base = sprintf('Figure_%d', i);
        fig_path_png = fullfile(figures_folder, [fig_name_base '.png']);
        fig_path_pdf = fullfile(figures_folder, [fig_name_base '.pdf']);
        fig_path_fig = fullfile(figures_folder, [fig_name_base '.fig']);
       
        % Save as PNG
        saveas(figs(i), fig_path_png);
        saveas(figs(i), fig_path_fig);
        try
            % Save as PDF (vector)
            exportgraphics(figs(i), fig_path_pdf, 'ContentType', 'vector');
        catch
            % Fallback if exportgraphics is not available
            saveas(figs(i), fig_path_pdf);
        end

    end
    fprintf('📊 All figures saved as PNG and PDF in: %s\n', figures_folder);

    
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
    
    
        % Delete temporary folder
        temp_folder = fullfile(global_results_folder, 'temp_results');
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


