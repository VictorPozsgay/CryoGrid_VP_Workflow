clear; 
clc;

%% PARAMÈTRES GÉNÉRAUX
excelFile = '/Users/maximefadel/Documents/Stage_Edytem_aout/PAPROG_Dataset_final.xlsx';
sheetName = 'Feuil1';  % à adapter si besoin
outputFolder = '/Users/maximefadel/Documents/Stage_Edytem/Tristan_Forcage/Donnes_Forcage';

% Charger le fichier Excel
T = readtable(excelFile, 'VariableNamingRule', 'preserve');
disp(T.Properties.VariableNames');

% Boucle sur chaque ligne
for i = 1:82
    massif_num = T.("Numero Massif")(i);
    elev = T.("altitude (m)")(i);

    % Utiliser uniquement l'ID comme nom de capteur
    capteur_name = string(T.ID(i));
    
    % Nettoyage du nom capteur (évite les caractères invalides pour un nom de fichier)
    capteur_name = regexprep(capteur_name, '[^a-zA-Z0-9_-]', '_');

    fprintf('Traitement du couple massif = %d, altitude = %d m, capteur = %s\n', massif_num, elev, capteur_name);

    % Exécuter le script 1 (forçage SAFRAN)
    run_forcing_safran(massif_num, elev, capteur_name);

    % Construire le nom du fichier généré par le premier script
    nom_fichier = sprintf('SAFRAN_ttab_elev_%d_slope_0_aspect_-1_massif_%d_dates_01Aug1958_01Aug2024_%s.mat', elev, massif_num, capteur_name);
    chemin_complet = fullfile(outputFolder, nom_fichier);

    % Vérifier l'existence du fichier attendu
    if isfile(chemin_complet)
        % Exécuter le script 2 avec ce fichier
        run_post_traitement(chemin_complet, massif_num, elev, capteur_name);
    else
        warning('Fichier non trouvé : %s\n', chemin_complet);
    end
end