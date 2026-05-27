clc; clear;

%% Chemin où se trouvent les fichiers .mat
folderPath = "E:\CG_Merge\CryoGrid_Optimization_Automatization_Workflow-main\CryoGrid\CryoGridCommunity_results\1MEN4\snow"; % CHEMIN À MODIFIER

files = dir(fullfile(folderPath, "*.mat"));

if isempty(files)
    error("Aucun fichier .mat trouvé dans le dossier.");
end

fileInfo = struct([]);

%% --- 1. Lecture des timestamps de chaque fichier ---
for k = 1:length(files)
    
    filePath = fullfile(folderPath, files(k).name);
    data = load(filePath);
    
    s = data.CG_out;

    % Extraction du timestamp
    ts = s.timestamp;

    % Conversion en datetime (format datenum supposé)
    ts_dt = datetime(ts, "ConvertFrom", "datenum");

    fileInfo(k).name   = files(k).name;
    fileInfo(k).path   = filePath;
    fileInfo(k).tStart = min(ts_dt);
    fileInfo(k).tEnd   = max(ts_dt);
end

%% --- 2. Tri chronologique des fichiers ---
[~, idx] = sort([fileInfo.tStart]);
fileInfo = fileInfo(idx);

disp("Ordre temporel des fichiers :");
for k = 1:length(fileInfo)
    fprintf("%02d) %s   -->   %s\n", ...
        k, fileInfo(k).name, datestr(fileInfo(k).tStart));
end

%% --- 3. Concaténation de snow_depth et timestamp ---
final = struct();
final.timestamp   = [];
final.snow_depth  = [];

for k = 1:length(fileInfo)
    
    data = load(fileInfo(k).path);
    s = data.CG_out;

    % Conversion du timestamp
    ts_dt = datetime(s.timestamp, "ConvertFrom", "datenum");

    % Forcer timestamp en colonne
    ts_dt = ts_dt(:);

    % Extraction snow_depth (déjà en colonne)
    sd = s.snow_depth;

    % Sécurité minimale
    if length(ts_dt) ~= length(sd)
        error("Incohérence timestamp / snow_depth dans le fichier : %s", ...
            fileInfo(k).name);
    end

    % Concaténation verticale
    final.timestamp  = [final.timestamp;  ts_dt];
    final.snow_depth = [final.snow_depth; sd];
end

disp("Concaténation finale terminée.");

tStartFinal = min(final.timestamp);
tEndFinal   = max(final.timestamp);

fprintf("Période finale : %s à %s\n", ...
    string(tStartFinal), string(tEndFinal));

%% --- 4. Création dynamique du nom du fichier de sortie ---
% Préfixe basé sur le premier fichier
premierNom = files(idx(1)).name;

% Détection de la partie avant la date (format supposé *_yyyymmdd.mat)
tokens = regexp(premierNom, '(.*_)\d{8}\.mat', 'tokens');

if isempty(tokens)
    error("Impossible d'identifier le préfixe commun du nom de fichier.");
end

prefijo = tokens{1}{1};

% Formatage des dates
startStr = datestr(tStartFinal, 'yyyymmdd');
endStr   = datestr(tEndFinal, 'yyyymmdd');

% Nom final
outputName = sprintf('%s%s_%s.mat', prefijo, startStr, endStr);

% Chemin complet
outputPath = fullfile(folderPath, outputName);

%% --- 5. Sauvegarde du fichier final ---
save(outputPath, 'final', '-v7.3');

fprintf("Fichier sauvegardé sous :\n%s\n", outputPath);
