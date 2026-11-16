% 
% files = {'SPINUP_analysis_4_accelerated_10x30ans_2600', ...
%          'SPINUP_analysis_4_accelerated_10x30ans_2900', ...
%          'SPINUP_analysis_4_accelerated_10x30ans_3200', ...
%          'SPINUP_analysis_4_accelerated_10x30ans_3900'};


files = {'SPINUP_analysis_6_classic_60x10ans_2600', ...
         'SPINUP_analysis_6_classic_60x10ans_2900', ...
         'SPINUP_analysis_6_classic_60x10ans_3200', ...
         'SPINUP_analysis_6_classic_60x10ans_3500'};


N = numel(files);
erreurs = cell(N, 1);

% Determine CryoGrid root path once, outside parfor
[file_path,file_name] = fileparts(mfilename("fullpath"));

while ~strcmp(file_name,'CryoGrid')
    [file_path,file_name]=fileparts(file_path);
    ROOT_PATH = char(fullfile(file_path,file_name));
end

CG_FORCING_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_forcing/"));
CG_RESULTS_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_results/"));
CG_RUN_PATH     = char(fullfile(ROOT_PATH,"CryoGridCommunity_run/"));
CG_SOURCE_PATH  = char(fullfile(ROOT_PATH,"CryoGridCommunity_source/"));

addpath(genpath(CG_SOURCE_PATH));

parfor i = 1:N
    try
        run_name = files{i};

        provider_path = fullfile(CG_RESULTS_PATH, run_name);
        mat_file = fullfile(provider_path, [run_name '.mat']);

        if ~isfile(mat_file)
            error('Fichier introuvable : %s', mat_file);
        end

        S = load(mat_file, 'provider');

        if ~isfield(S, 'provider')
            error('Le fichier ne contient pas de variable provider.');
        end

        provider = S.provider;

        % Initialize RUN_INFO and execute simulation
        [run_info, provider] = run_model(provider);
        [run_info, tile] = run_model(run_info);

    catch ME
        erreurs{i} = ME;
        warning('Simulation "%s" failed:\n%s', ...
                files{i}, getReport(ME, 'extended'));
    end
end

% Display failures
for i = 1:N
    if ~isempty(erreurs{i})
        fprintf('\nEchec : %s\n%s\n', ...
                files{i}, erreurs{i}.message);
    end
end

toc