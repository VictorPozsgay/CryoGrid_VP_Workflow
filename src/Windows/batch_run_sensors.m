% ==============================================================
% SCRIPT: batch_run_sensors.m
% DESCRIPTION: Lance la fonction main_optimization_parallel_fc.m pour une liste de capteurs
%              Si une simulation plante, l'erreur est affichée mais le
%              programme continue avec le capteur suivant.
% ==============================================================

clc; clear; close all;

% --- Liste des capteurs à simuler ---
% sensor_list = {'MON_E','MON_N','MON_W','MON_TOP','PEL_E','PEL_SW','PEL_N','2ALP_N1',...
%     '2ALP_S1','2ALP_S2','GD_CAP_W_H','GD_CAP_N','TIG_N','TIG_S','TIG_BH_N','Lau_N',...
%     'OBI_NE_H','TR_AIG_N','TR_AIG_E','VAU_N','VAU_E','ADM_N','ADM_NE','ADM_NO','ADM_S1',...
%     'ADM_S2','ADM_S3','ADM_S3','ADM_S4','BEL_N_TOP'};
sensor_list = {'MON1'};

% --- Compteurs pour le résumé final ---
n_sensors = numel(sensor_list);
success_list = {};
failed_list = {};

fprintf('\n=======================\n');
fprintf('  Lancement des %d simulations\n', n_sensors);
fprintf('=======================\n\n');

% --- Boucle sur chaque capteur ---
for i = 1:n_sensors
    sensor_ID = sensor_list{i};
    fprintf('>>> [%d/%d] Simulation capteur : %s\n', i, n_sensors, sensor_ID);
    
    try
        % Exécuter la fonction principale
        main_optimization_parallel_fc(sensor_ID);
        fprintf('✅ Simulation terminée avec succès pour %s\n\n', sensor_ID);
        success_list{end+1} = sensor_ID;
        
    catch ME
        % Gestion de l’erreur
        fprintf('❌ ERREUR pour %s : %s\n', sensor_ID, ME.message);
        failed_list{end+1} = sensor_ID;
    end
end

% --- Résumé final ---
fprintf('\n=======================\n');
fprintf('       RÉSUMÉ FINAL\n');
fprintf('=======================\n');

fprintf('\n✅ Simulations réussies (%d) :\n', numel(success_list));
disp(success_list');

fprintf('\n❌ Simulations échouées (%d) :\n', numel(failed_list));
disp(failed_list');

fprintf('\n--- Fin du batch ---\n');
