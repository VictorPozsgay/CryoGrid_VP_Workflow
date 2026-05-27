function run_program_parallel(sensor_ID, source_path, daily_mean_sensors_folder, sensors_file, excel_file, num_iterations, season_weights, forcing_folder, params_config, dt, results_path)

% Main function to automatically run all CryoGrid calibration steps
% for CryoGrid for a given sensor

    clc;
    clear objectiveFunction_parallel;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 1: Modify the CryoGrid file to adapt it to the studied sensor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Avoid conflicts between the Nanmin function of MATLAB and CryoGrid
    rmpath(genpath(source_path));
    
    % Function that finds the correct reference data file for the given sensor
    sensor_data_file = find_measure_file(daily_mean_sensors_folder, string(sensor_ID));

    % Function to retrieve sensor information
    [~, info] = get_sensor_info(string(sensor_ID), sensors_file, forcing_folder, dt);
    

    % Update CG_single.xlsx BEFORE optimization to ensure the information
    % is correctly adapted to the studied sensor
    
    % Structure the retrieved sensor information
    fixed_params = struct();
    fields = fieldnames(info);
    for i = 1:length(fields)
        field_name = fields{i};
        fixed_params.(field_name) = info.(field_name);
    end
    
    % Function that detects parameter rows in the CG_single Excel file
    rows = find_parameter_rows(excel_file, fieldnames(fixed_params));

    % Replace sensor values in CG_single.xlsx
    replace_parameters(excel_file, rows, fixed_params);

    % Pause to ensure the modified Excel file is saved
    pause(3);

    % Replace the initial temperature in CG_single.xlsx
    
    % Find the row of initial temperatures
    param_row = find_parameter_rows(excel_file, {'points'});
    
    % Initialize temperature profile to zero, then update it with sensor data
    temp_ini = 0;
    
    % Replace the initial temperature in CG_single.xlsx
    replace_initial_temp(excel_file, param_row.points, temp_ini);
    
    % Pause to ensure the modified Excel file is saved
    pause(3);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % End of Step 1: Sensor information retrieved and CG_single.xlsx updated
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 2: Analyze the presence of snow days for the studied sensor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Temperature variation threshold between two days to determine snow presence.
    % The lower it is, the more it detects snow periods with very low variations.
    variation_threshold = 0.05;
    
    % Minimum duration (days) of low temperature variation considered as snow.
    % Set to 2 to count all snow days, increase it to detect only long snow periods.
    min_duration = 2;

    % Analyze sensor data to count snow days, retrieve useful info,
    % and plot highlighting snow periods
    [~, ~, ~, ~, avg_snow_days_per_year, snow_dates] = ...
        detect_snow_presence(sensor_data_file, variation_threshold, min_duration);

    % ⚠️ Note: The Excel file with sensor info already contains a "snow" column
    % indicating whether snow is present for the studied sensor.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % End of Step 2: Snow information retrieved
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 3: Model optimization for the studied sensor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Define variables to optimize with their physical bounds
    params = [];

    field_names = fieldnames(params_config);

    for i = 1:length(field_names)
        name = field_names{i};
        conf = params_config.(name);
    
        % If there is "always_optimize"
        if isfield(conf,'always_optimize') && conf.always_optimize
            params = [params; optimizableVariable(name, conf.bounds, 'Type','real')];
        
        % "snow_fraction" case, depending on number of snow days
        elseif isfield(conf,'low_snow_bounds') || isfield(conf,'high_snow_bounds')
            if (15 < avg_snow_days_per_year) && (avg_snow_days_per_year < 50)
                params = [params; optimizableVariable(name, conf.low_snow_bounds, 'Type','real')];
            elseif avg_snow_days_per_year >= 50
                params = [params; optimizableVariable(name, conf.high_snow_bounds, 'Type','real')];
            else
                fixed_params.(name) = conf.fixed_if_no_snow;
            end
        end
    end

    delete(gcp('nocreate'));  % Close pool if exists
    parpool('local');         % Restart local pool

    % Function handle with fixed parameters, since bayesopt only gives "x"
    % This allows post-processing plots of the optimization
    objFcn = @(x) objectiveFunction_parallel(x, excel_file, sensor_data_file, info, snow_dates, avg_snow_days_per_year, season_weights, source_path, sensor_ID, forcing_folder, dt, results_path, params_config);

    % Launch optimization using Bayesian optimization
    % Requires MATLAB Statistics and Machine Learning Toolbox
    results = bayesopt(objFcn, params, ...
        'MaxObjectiveEvaluations', num_iterations, ...
        'IsObjectiveDeterministic', true, ...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'Verbose', 1, 'UseParallel', true,...
        'PlotFcn', {@plotMinObjective});

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % End of Step 3: Optimization finished, best parameters found
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Step 4: Post-processing to analyze optimization efficiency
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Post-analysis: plots convergence, parameter influence, and correlations
    analyze_bayesopt_optimization(results);

    % =========================================================================
    % Merge temporary results
    % =========================================================================

    temp_folder = fullfile(results_path, 'CG_single', 'temp_results');
    final_result_file = fullfile(results_path, 'CG_single', ...
    sprintf('bayesopt_results_%s.mat', sensor_ID));
    merge_bayesopt_results(temp_folder, sensor_ID, final_result_file);

    % =========================================================================
    % Plot comparison: best vs first simulation
    % =========================================================================
    
    result_path_global = fullfile(results_path, 'CG_single/');
    
    S = load(fullfile(result_path_global, ...
    sprintf('bayesopt_results_%s.mat', sensor_ID)));
    R = S.results;

    % --------------------------------
    % Sort results by iteration number
    % --------------------------------
    iterations = cellfun(@(x) x.iteration, R);
    [sorted_iterations, sort_idx] = sort(iterations);

    R = R(sort_idx);
    
    % --------------------------------
    % Identify best simulation
    % --------------------------------
    scores = cellfun(@(x) x.score, R);
    [~, idx_best] = max(scores);     
    best_result = R{idx_best};
    
    % ----------------------------------------------------------
    % Identify "first" simulation according to number of workers
    % ----------------------------------------------------------

    
    p = gcp('nocreate');
    fprintf('Number of workers: %d\n', p.NumWorkers);
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
    
    % ----------------------------------------------------------
    % Plot comparison
    % ----------------------------------------------------------
    figure;
    plot(R{1}.dates, R{1}.T_obs, 'w', 'DisplayName', 'Observed');
    hold on;
    plot(best_result.dates, best_result.T_sim, '--r', 'DisplayName', sprintf('Best simulation (iter %d)', best_result.iteration));
    plot(first_result.dates, first_result.T_sim, ':b', 'DisplayName', sprintf('First simulation (iter 1)'));
    legend;
    title(sprintf('Simulations comparison — Best (%.1f) vs First (%.1f)', ...
        best_result.score, first_result.score));
    xlabel('Time'); ylabel('Temperature (°C)');
    grid on;


    % =========================================================================
    % Retrieve best simulation stats and parameters
    % =========================================================================

    scores = cellfun(@(x) x.score, R);
    best_score = max(scores);
    idx_best_all = find(scores == best_score);   % for all equal

    all_results = [];  % initialisation

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
            'T_ini', best_result.T_ini, ...
            'score', best_result.score, ...
            'iteration', best_result.iteration ...
        );

    
        if isfield(best_params, 'snow_fraction')
            final_results.snow_fraction = best_params.snow_fraction;
        end
        

        % === Add seasonal Mean_Diff values (simple version) ===
        season_keys   = {'winter','spring','summer','autumn'};
        season_labels = {'Winter','Spring','Summer','Autumn'};
        
        % Pre-create all 4 fields as NaN
        for si = 1:numel(season_keys)
            label = season_labels{si};
            final_results.(sprintf('MeanDiff_%s', label)) = NaN;
        end
        
        % Fill if data is available
        for si = 1:numel(season_keys)
            key   = season_keys{si};
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

    disp(best_result.stats.autumn);
    
    % Convertir en table
    T = struct2table(all_results);

    if any(strcmp(T.Properties.VariableNames, 'z0'))
        T = renamevars(T, 'z0', 'z0_(m)');
    end

    if ~exist(results_path, 'dir')
        mkdir(results_path);
    end
    
    output_file = fullfile(results_path, sprintf('results_%s.xlsx', sensor_ID));
    writetable(T, output_file);

    fprintf("✅ All best results (score = %.1f) saved to file: %s\n", best_score, output_file);


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
    p = gcp("nocreate");
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
        T.Eval_result = repmat("Best", n, 1);
    end
    
    % Objective trace and runtime per iteration
    T.Score = results.ObjectiveTrace;
    T.Iteration_runtime = results.IterationTimeTrace;
    
    % Best-so-far observed
    T.BestScore_Observed = cummin(T.Score);
    
    T.Stage = repmat("Acquisition", n, 1);  % All iterations from bayesopt are acquisition
    
    % Add all tested parameters
    T = [T, X];
    
    % Rename z0 column if present
    if any(strcmp(T.Properties.VariableNames, 'z0'))
        T.Properties.VariableNames{strcmp(T.Properties.VariableNames,'z0')} = 'z0_(m)';
    end
    
    % ----------- Handle initial simulations from final_result_file -----------
    
    S = load(final_result_file);  % results from merge_bayesopt_results
    R = S.results;
    
    % Identify initial simulations (iterations <= nWorkers)
    init_idx = find(cellfun(@(x) x.iteration, R) <= nWorkers);
    
    init_rows = [];
    best_so_far = [];  % track best score
    
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
            'Eval_result', "Initialization", ...
            'Score', -res.score, ...
            'Iteration_runtime', NaN, ...
            'BestScore_Observed', best_so_far ...
        );
        % Add parameters tested
        param_names = fieldnames(res.params);
        for pn = 1:numel(param_names)
            temp_struct.(param_names{pn}) = res.params.(param_names{pn});
        end
        temp_struct.Stage = "Initialization";
        init_rows = [init_rows; temp_struct]; %#ok<AGROW>
    end
    
    % Convert to table
    T_init = struct2table(init_rows);
    
    % Rename z0 in T_init if necessary
    if any(strcmp(T.Properties.VariableNames,'z0_(m)')) && any(strcmp(T_init.Properties.VariableNames,'z0'))
        T_init = renamevars(T_init,'z0','z0_(m)');
    end
    
    % Reorder columns to match T
    T_init = T_init(:, T.Properties.VariableNames);
    
    % Concatenate with T
    T = [T_init; T];
    
    % Save Excel
    filename = fullfile(results_path, ['bayesopt_results_' sensor_ID '.xlsx']);
    writetable(T, filename, 'FileType','spreadsheet');
    fprintf("✅ Results saved to: %s\n", filename);




    % =========================================================================
    % Comparison with snowfall data
    % =========================================================================

    if avg_snow_days_per_year > 15
        file = find_forcing_file(forcing_folder, string(sensor_ID));
        [snowfall, snowfall_date] = extract_snowfall(file, info.start_time, info.end_time);
    
        figure;
        hold on;

        size(R{1}.T_obs)
        size(best_result.T_sim)
    
        % Left axis: Temperatures
        yyaxis left
        plot(R{1}.dates, R{1}.T_obs, 'w-', 'LineWidth', 1.5, 'DisplayName', 'Observed');
        plot(best_result.dates, best_result.T_sim, '--r', 'LineWidth', 1.5, 'DisplayName', 'Best iteration');
        ylabel('Temperature (°C)');
        set(gca, 'YColor', 'white');
        ylim([min([R{1}.T_obs(:); best_result.T_sim(:)], [], 'omitnan'), ...
              max([R{1}.T_obs(:); best_result.T_sim(:)], [], 'omitnan')]);  % 🔥 Échelle ajoutée
    
        % Right axis: Cumulative Snowfall per Hydrological Year
        yyaxis right
        bar(snowfall_date, snowfall,...
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


    % =========================================================================
    % Seasonal scatter plot
    % =========================================================================
    
    obs = R{1}.T_obs;
    dates = R{1}.dates;
    sim = R{idx_best}.T_sim;
    
    seasons = strings(size(dates));
    for i = 1:length(dates)
        m = month(dates(i));
        if ismember(m, [12, 1, 2])
            seasons(i) = "Winter";
        elseif ismember(m, [3, 4, 5])
            seasons(i) = "Spring";
        elseif ismember(m, [6, 7, 8])
            seasons(i) = "Summer";
        else
            seasons(i) = "Autumn";
        end
    end
    
    colors = containers.Map(...
        ["Winter", "Spring", "Summer", "Autumn"], ...
        {[0.2 0.6 1], [0.4 0.8 0.4], [1 0.6 0.2], [0.7 0.5 1]});
    
    ordered_seasons = {"Winter", "Spring", "Summer", "Autumn"};
    
    % ---- Compute global min and max for consistent axes ----
    global_min = min([obs; sim], [], 'omitnan');
    global_max = max([obs; sim], [], 'omitnan');
    
    figure;
    for k = 1:4
        season = ordered_seasons{k};
        idx = seasons == season;
    
        subplot(2,2,k);
        hold on;
    
        scatter(obs(idx), sim(idx), 25, ...
            'filled', 'MarkerFaceColor', colors(season));
    
        % 1:1 line
        plot([global_min, global_max], [global_min, global_max], '--w', 'LineWidth', 1);
    
        % RMSE calculé directement
        rmse = sqrt(mean((sim(idx) - obs(idx)).^2, 'omitnan'));
    
        % MeanDiff recover from seasonal stats
        mean_diff_field = sprintf("MeanDiff_%s", season);
        if isfield(final_results, mean_diff_field)
            mean_diff = final_results.(mean_diff_field);
        else
            mean_diff = NaN;
        end
    
        % Text
        txt = sprintf('RMSE = %.2f °C\nMean ΔT = %.2f °C', rmse, mean_diff);
        text(0.05, 0.9, txt, ...
        'Units', 'normalized', ... 
        'FontSize', 9, ...
        'Color', 'k', ...
        'BackgroundColor', 'w');
    
        xlabel('Observed (°C)');
        ylabel('Simulated (°C)');
        title(season);
        axis equal;
        xlim([global_min, global_max]);
        ylim([global_min, global_max]);
        grid on;
    end
    
    sgtitle('Observed vs Simulated by season — Best iteration');



    % =========================================================================
    % Uncertainty envelope
    % =========================================================================

    if isempty(R)
        warning("⚠️ No simulation results found.");
        return;
    end
    
    allTemps = cellfun(@(x) x.T_sim(:), R, 'UniformOutput', false);
    matTemp = cat(2, allTemps{:});
    
    temp_min = min(matTemp, [], 2);
    temp_max = max(matTemp, [], 2);
    temp_mean = mean(matTemp, 2, 'omitnan');
    
    scores = cellfun(@(x) x.score, R);
    [~, idx_best] = max(scores);  
    temp_best = R{idx_best}.T_sim(:);
    
    refDates = R{1}.dates;
    refTemps = R{1}.T_obs;
    
    figure;
    hold on;
    
    fill([refDates; flipud(refDates)], ...
         [temp_min; flipud(temp_max)], ...
         [0.8 0.8 1], 'FaceAlpha', 0.4, 'EdgeColor', 'none', ...
         'DisplayName', "Uncertainty envelope");
    
    plot(refDates, temp_mean, 'c--', 'LineWidth', 0.8, ...
         'DisplayName', 'Mean of simulations');
    
    plot(refDates, temp_best, 'r-', 'LineWidth', 1.2, ...
         'DisplayName', 'Best simulation');
    
    plot(refDates, refTemps, 'w-', 'LineWidth', 1.2, ...
         'DisplayName', 'Observed');
    
    xlabel('Date');
    ylabel('Temperature (°C)');
    title("Final results of Bayesian optimization");
    legend('Location', 'best');
    grid on;


    % =========================================================================
    % Cleanup: remove temp files and save figures
    % =========================================================================
    
    % Define output folder (same as Excel file)
    figures_folder = fullfile(results_path, sprintf('Figures_%s', sensor_ID));
    if ~exist(figures_folder, 'dir')
        mkdir(figures_folder);
    end
    
    % Save all open figures
    figs = findall(groot, 'Type', 'figure');
    for i = 1:numel(figs)
        fig_name_base = sprintf('Figure_%d', i);
        fig_path_png = fullfile(figures_folder, [fig_name_base '.png']);
        fig_path_pdf = fullfile(figures_folder, [fig_name_base '.pdf']);
        
        % Save as PNG
        saveas(figs(i), fig_path_png);
        
        try
            % Save as PDF (vector)
            exportgraphics(figs(i), fig_path_pdf, 'ContentType', 'vector');
        catch
            % Fallback if exportgraphics is not available
            saveas(figs(i), fig_path_pdf);
        end
    end
    
    fprintf("📊 All figures saved as PNG and PDF in: %s\n", figures_folder);

    % ==== Cleanup ===
    results_global_path = fullfile(results_path, 'CG_single');

    worker_folders = dir(fullfile(results_global_path, 'CG_single_worker*'));
    for k = 1:length(worker_folders)
        worker_folder = fullfile(worker_folders(k).folder, worker_folders(k).name);
        if worker_folders(k).isdir
            rmdir(worker_folder, 's');
        end
    end


    temp_folder = fullfile(results_global_path, 'temp_results');
    if exist(temp_folder, 'dir')
        rmdir(temp_folder, 's');
    end

    fprintf("🧹 Cleanup done: worker folders, temp_results and bayesopt_results deleted.\n");
end
