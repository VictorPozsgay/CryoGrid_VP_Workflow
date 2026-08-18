 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lancement parallèle de plusieurs runs CryoGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% --- Paramètres généraux (inchangés)
init_format   = 'EXCEL3D';
result_path  = '..\CryoGridCommunity_results\templates\automatic_loops\';
source_path  = '..\CryoGridCommunity_source\';
constant_file = 'CONSTANTS_excel';

addpath(genpath(source_path));

%% --- Liste des runs à lancer
run_names = {
    'loop1'
    'loop2'
    'loop3'
    'loop4'
    'loop5'
    'loop6'
    'loop7'
    'loop8'
    'loop9'
    'loop10'
};



%% --- Pool parallèle
delete(gcp('nocreate'))
nWorkers = length(run_names);   % 1 node per run
nWorkers = min(nWorkers, parcluster('local').NumWorkers);
parpool('local', nWorkers);

%% --- Lancement parallèle
parfor i = 1:numel(run_names)

    run_name = run_names{i};

    fprintf('--- Lancement %s sur worker %d ---\n', run_name, getCurrentTask().ID);

    % PROVIDER local (important)
    provider = PROVIDER;
    provider = assign_paths(provider, init_format, run_name, result_path, constant_file);
    provider = read_const(provider);
    provider = read_parameters(provider);

    % Run CryoGrid
    [run_info, provider] = run_model(provider);
    [run_info, tile] = run_model(run_info);

    fprintf('--- Fin %s ---\n', run_name);
end
