clc; clear;

baseResultsPath = ...
"E:\CG_Merge\CryoGrid_Optimization_Automatization_Workflow-main\CryoGrid\CryoGridCommunity_results";

run_names = {
    '1MEN4'
    '2MEN4'
    '3MEN4'
    '4MEN4'
    '5MEN4'
    '6MEN4'
    '1MEN7'
    '2MEN7'
    '3MEN7'
    '4MEN7'
    '5MEN7'
    '6MEN7'
    '1MEN12'
    '2MEN12'
    '3MEN12'
    '4MEN12'
    '5MEN12'
    '6MEN12'
    '1MEN13'
    '2MEN13'
    '3MEN13'
    '4MEN13'
    '5MEN13'
    '6MEN13'
    '1MEN15'
    '2MEN15'
    '3MEN15'
    '4MEN15'
    '5MEN15'
    '6MEN15'
};

for r = 1:numel(run_names)

    run_name = run_names{r};
    folderPath = fullfile(baseResultsPath, run_name);

    pattern = run_name + "_TwaterIce_fichier_resultats_????????.mat";
    files = dir(fullfile(folderPath, pattern));
    if isempty(files)
        error("Aucun fichier .mat");
    end

    final = struct();
    initialized = false;

    for k = 1:numel(files)

        data = load(fullfile(folderPath, files(k).name));
        if ~isfield(data, 'OUT_TwaterIce')
            continue
        end

        s = data.OUT_TwaterIce;

        % --- timestamp
        ts = datetime(s.timestamp(:), "ConvertFrom", "datenum");

        if ~initialized
            final.timestamp = [];
            final.T         = [];
            final.water     = [];
            final.ice       = [];
            final.waterIce  = [];
            final.depths    = s.depths; % identique pour tous les fichiers
            initialized = true;
        end

        Nt = numel(ts);

        % --- sécurité tailles (profondeur × temps)
        if size(s.T,2) ~= Nt
            warning("Tailles incompatibles dans %s (ignoré)", files(k).name);
            continue
        end

        % --- concaténation temporelle (HORIZONTALE)
        final.timestamp = [final.timestamp ; ts];
        final.T         = [final.T        , s.T];
        final.water     = [final.water    , s.water];
        final.ice       = [final.ice      , s.ice];
        final.waterIce  = [final.waterIce , s.waterIce];

    end

    save(fullfile(folderPath, "OUT_TwaterIce_merged.mat"), ...
         "final", "-v7.3");

    disp("✔ Fusion terminée correctement (dimensions conservées)");
end
