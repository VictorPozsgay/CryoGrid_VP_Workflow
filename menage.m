%% ================= CHEMIN RACINE =================
base_path = 'E:\CG_Merge\CryoGrid_Optimization_Automatization_Workflow-main\CryoGrid\CryoGridCommunity_results\';

%% ================= LISTE DES RUNS =================
run_names = {
    '1MEN4','2MEN4','3MEN4','4MEN4','5MEN4','6MEN4', ...
    '1MEN7','2MEN7','3MEN7','4MEN7','5MEN7','6MEN7', ...
    '1MEN12','2MEN12','3MEN12','4MEN12','5MEN12','6MEN12', ...
    '1MEN13','2MEN13','3MEN13','4MEN13','5MEN13','6MEN13', ...
    '1MEN15','2MEN15','3MEN15','4MEN15','5MEN15','6MEN15'
};

%% ================= BOUCLE =================
for i = 1:numel(run_names)
    run = run_names{i};
    run_path = fullfile(base_path, run);

    if ~isfolder(run_path)
        warning('Dossier introuvable : %s', run_path);
        continue
    end

    % --- créer le sous-dossier "7"
    target_folder = fullfile(run_path, '7');
    if ~isfolder(target_folder)
        mkdir(target_folder);
    end

    % --- déplacer tous les .mat
    mat_files = dir(fullfile(run_path, '*.mat'));
    for f = 1:numel(mat_files)
        movefile(fullfile(run_path, mat_files(f).name), target_folder);
    end

    % --- déplacer le fichier "snow" s'il existe
    snow_file = fullfile(run_path, 'snow');
    if isfile(snow_file)
        movefile(snow_file, target_folder);
    end

    fprintf('Fichiers déplacés pour %s\n', run);
end
