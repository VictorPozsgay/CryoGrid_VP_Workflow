function run_CG_parallel(source_path, init_format, run_names, result_path, constant_file)

% add source code path
addpath(genpath(source_path));

%% --- Parallel pool
delete(gcp('nocreate'))
nWorkers = length(run_names);   % 1 node per run
nWorkers = min(nWorkers, parcluster('local').NumWorkers);
parpool('local', nWorkers);

%% --- Running parallel jobs
parfor i = 1:numel(run_names)

    run_name = run_names{i};

    fprintf('--- Running %s on worker %d ---\n', run_name, getCurrentTask().ID);

    % PROVIDER local (important)
    provider = PROVIDER;
    provider = assign_paths(provider, init_format, run_name, result_path, constant_file);
    provider = read_const(provider);
    provider = read_parameters(provider);

    % Run CryoGrid
    [run_info, ~] = run_model(provider);
    [~, ~] = run_model(run_info);

    fprintf('--- End %s ---\n', run_name);
end

end
