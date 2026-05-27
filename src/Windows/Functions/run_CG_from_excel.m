function run_CG_from_excel(run_name, constant_file, result_path, source_path)

    % Ajouter le code source à la path
    addpath(genpath(source_path));

    % Type de fichier d'entrée
    init_format = 'EXCEL3D';  % peut rester fixe si c'est toujours ce format

    % Créer et charger le provider
    provider = PROVIDER;
    provider = assign_paths(provider, init_format, run_name, result_path, constant_file);
    provider = read_const(provider);
    provider = read_parameters(provider);

    % Créer les objets nécessaires à la simulation
    [run_info, provider] = run_model(provider);
    [run_info, tile]     = run_model(run_info);
end