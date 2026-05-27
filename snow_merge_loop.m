clc; clear;

%% ================= PARAMÈTRES GÉNÉRAUX =================

baseResultsPath = ...
"E:\CG_Merge\CryoGrid_Optimization_Automatization_Workflow-main\CryoGrid\CryoGridCommunity_results";

run_names = {
    '1MEN4','2MEN4','3MEN4','4MEN4','5MEN4','6MEN4', ...
    '1MEN7','2MEN7','3MEN7','4MEN7','5MEN7','6MEN7', ...
    '1MEN12','2MEN12','3MEN12','4MEN12','5MEN12','6MEN12', ...
    '1MEN13','2MEN13','3MEN13','4MEN13','5MEN13','6MEN13', ...
    '1MEN15','2MEN15','3MEN15','4MEN15','5MEN15','6MEN15'
};

%% ================= BOUCLE SUR LES RUNS =================

for r = 1:numel(run_names)

    run_name = run_names{r};

    fprintf('\n=================================================\n');
    fprintf('Traitement %s (%d / %d)\n', run_name, r, numel(run_names));
    fprintf('=================================================\n');

    %% --- Chemin du dossier snow du run courant
    folderPath = fullfile(baseResultsPath, run_name, "snow");

    if ~isfolder(folderPath)
        warning("Dossier introuvable : %s (run ignoré)", folderPath);
        continue
    end

    files = dir(fullfile(folderPath, "*.mat"));

    if isempty(files)
        warning("Aucun fichier .mat dans %s (run ignoré)", folderPath);
        continue
    end

    fileInfo = struct([]);

    %% --- 1. Lecture des timestamps de chaque fichier
    for k = 1:length(files)

        filePath = fullfile(folderPath, files(k).name);
        data = load(filePath);
        s = data.CG_out;

        ts_dt = datetime(s.timestamp, "ConvertFrom", "datenum");

        fileInfo(k).name   = files(k).name;
        fileInfo(k).path   = filePath;
        fileInfo(k).tStart = min(ts_dt);
        fileInfo(k).tEnd   = max(ts_dt);
    end

    %% --- 2. Tri chronologique
    [~, idx] = sort([fileInfo.tStart]);
    fileInfo = fileInfo(idx);

    fprintf("Ordre temporel des fichiers (%s) :\n", run_name);
    for k = 1:length(fileInfo)
        fprintf("%02d) %s --> %s\n", ...
            k, fileInfo(k).name, datestr(fileInfo(k).tStart));
    end

    %% --- 3. Concaténation snow_depth / timestamp
    final = struct();
    final.timestamp  = [];
    final.snow_depth = [];

    for k = 1:length(fileInfo)

        data = load(fileInfo(k).path);
        s = data.CG_out;

        ts_dt = datetime(s.timestamp, "ConvertFrom", "datenum");
        ts_dt = ts_dt(:);
        sd    = s.snow_depth;

        if length(ts_dt) ~= length(sd)
            error("Incohérence timestamp / snow_depth dans %s", ...
                fileInfo(k).name);
        end

        final.timestamp  = [final.timestamp;  ts_dt];
        final.snow_depth = [final.snow_depth; sd];
    end

    tStartFinal = min(final.timestamp);
    tEndFinal   = max(final.timestamp);

    fprintf("Période finale %s : %s → %s\n", ...
        run_name, string(tStartFinal), string(tEndFinal));

    %% --- 4. Nom du fichier de sortie
    premierNom = fileInfo(1).name;

    tokens = regexp(premierNom, '(.*_)\d{8}\.mat', 'tokens');
    if isempty(tokens)
        error("Impossible d'identifier le préfixe du fichier (%s)", premierNom);
    end

    prefijo  = tokens{1}{1};
    startStr = datestr(tStartFinal, 'yyyymmdd');
    endStr   = datestr(tEndFinal, 'yyyymmdd');

    outputName = sprintf('%s%s_%s.mat', prefijo, startStr, endStr);
    outputPath = fullfile(folderPath, outputName);

    %% --- 5. Sauvegarde
    save(outputPath, 'final', '-v7.3');

    fprintf("✔ Fichier sauvegardé :\n%s\n", outputPath);

end

disp("=== Tous les runs ont été traités ===");
