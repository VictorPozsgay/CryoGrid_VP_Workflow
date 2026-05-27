%% Chemin racine
base_path = 'E:\CG_Merge\CryoGrid_Optimization_Automatization_Workflow-main\CryoGrid\CryoGridCommunity_results\';

%% Liste des runs
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

%% Cellules et valeurs
cells  = {'B56','D97','D98','D99','D100','D101'};
values = {0, 0.05, 0.05, 0.1, 1, 5};

%% Boucle
for i = 1:numel(run_names)

    run = run_names{i};
    file = fullfile(base_path, run, [run '.xlsx']);

    if ~isfile(file)
        warning('Fichier introuvable : %s', file);
        continue
    end

    for c = 1:numel(cells)
        writematrix(values{c}, file, 'Range', cells{c});
    end

    fprintf('OK : %s\n', run);
end




%%%%%%%%%%%%


%% ================= CHEMIN RACINE =================
base_path = 'E:\CG_Merge\CryoGrid_Optimization_Automatization_Workflow-main\CryoGrid\CryoGridCommunity_results\';

%% ================= MEN =================
MEN_list = {'MEN4','MEN7','MEN12','MEN13','MEN15'};

%% ================= CALIB =================
groupA_prefix = {'calib','calib2'};   % groupe A
groupB_prefix = {'calib3','calib4'};  % groupe B

%% ================= CELLULES FIXES =================
fixed_cells  = {'C53','D36','E36','D37','E37'};
fixed_values = {1990, 'STRAT_linear', 'END', 1, 'END'};

%% ================= CELLULES C145:C152 =================
row_range = 145:152;
C_cells = arrayfun(@(r) ['C' num2str(r)], row_range, 'UniformOutput', false);

%% ================= VALEURS PAR MEN =================
% Groupe A : calib + calib2
values_groupA = containers.Map( ...
    MEN_list, ...
    [-1.47, -0.10, 0.23, 2.12, 0.69] ...
);

% Groupe B : calib3 + calib4
values_groupB = containers.Map( ...
    MEN_list, ...
    [-2.47, -1.10, -0.77, 1.12, -0.31] ...
);

%% ================= BOUCLE PRINCIPALE =================
for m = 1:numel(MEN_list)

    MEN = MEN_list{m};

    %% ---------- GROUPE A ----------
    for g = 1:numel(groupA_prefix)

        run_name = [groupA_prefix{g} MEN];
        file = fullfile(base_path, run_name, [run_name '.xlsx']);

        if ~isfile(file)
            warning('Fichier introuvable : %s', file);
            continue
        end

        % valeurs fixes
        for k = 1:numel(fixed_cells)
            writematrix(fixed_values{k}, file, 'Range', fixed_cells{k});
        end

        % C145:C152
        val = values_groupA(MEN);
        for c = 1:numel(C_cells)
            writematrix(val, file, 'Range', C_cells{c});
        end

        fprintf('OK groupe A : %s\n', run_name);
    end

    %% ---------- GROUPE B ----------
    for g = 1:numel(groupB_prefix)

        run_name = [groupB_prefix{g} MEN];
        file = fullfile(base_path, run_name, [run_name '.xlsx']);

        if ~isfile(file)
            warning('Fichier introuvable : %s', file);
            continue
        end

        % valeurs fixes
        for k = 1:numel(fixed_cells)
            writematrix(fixed_values{k}, file, 'Range', fixed_cells{k});
        end

        % C145:C152
        val = values_groupB(MEN);
        for c = 1:numel(C_cells)
            writematrix(val, file, 'Range', C_cells{c});
        end

        fprintf('OK groupe B : %s\n', run_name);
    end

end
