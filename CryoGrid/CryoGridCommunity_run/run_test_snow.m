%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%


%% Automatically find the root of CryoGrid/ 
% If easier, just comment this out and  manually type your ROOT_PATH
% ROOT_PATH/
%   CryoGridCommunity_forcing_test_cpp/
%   CryoGridCommunity_results/
%       test_SAFRAN_cpp/
%           test_SAFRAN_point/
%           test_SAFRAN_spatial/
%   CryoGridCommunity_run/
%       run_CG_test_SAFRAN_point.m
%   CryoGridCommunity_source/
[file_path,file_name] = fileparts(mfilename('fullpath'));

while ~strcmp(file_name,'CryoGrid')
    [file_path,file_name]=fileparts(file_path);
    ROOT_PATH = char(fullfile(file_path,file_name));
end

CG_FORCING_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_forcing"));
CG_RESULTS_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_results"));
%CG_RUN_PATH     = char(fullfile(ROOT_PATH,"CryoGridCommunity_run"));
CG_SOURCE_PATH  = char(fullfile(ROOT_PATH,"CryoGridCommunity_source"));


%% The 4 parameters needed to run a simulation
init_format   = 'EXCEL3D'; % choose the option corresponding to the parameter file format
run_name_base = 'base'; % name of parameter file (without file extension) AND name of subfolder (in result_path) within which it is located
result_path   = char(fullfile(CG_RESULTS_PATH,'templates\test_snow\'));
constant_file = 'CONSTANTS_excel'; %filename of file storing constants


%%%%%%%%%%%%%%%%%%%%%%%% end user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
%                             do not change
% -------------------------------------------------------------------------

% add source code path
addpath(genpath(CG_SOURCE_PATH));

%create and load PROVIDER
provider = PROVIDER;
provider = assign_paths(provider, init_format, run_name_base, result_path, constant_file);
provider = read_const(provider);
provider = read_parameters(provider);

provider = replace_PATHS_strings( ...
    provider, ...
    {'CG_FORCING_PATH'}, ...
    {CG_FORCING_PATH});

files = {};

for slope_angle = 10:10:31
    for reservoir_contact_length = [0.1 1 10]
        run_name = sprintf('slope_%d_length_%g', slope_angle, reservoir_contact_length);

        slope_angle_bounded = min(max(slope_angle,10),80); % bound between 10° and 80°
        reservoir_elevation = provider.CLASSES.LAT_WATER_RESERVOIR{1,1}.PARA.reservoir_elevation;
        distance_reservoir  = abs(reservoir_elevation / tand(slope_angle_bounded));

        provider.CLASSES.POINT_SLOPE{1,1}.PARA.slope_angle = slope_angle;
        provider.CLASSES.LAT_WATER_RESERVOIR{1,1}.PARA.distance_reservoir = distance_reservoir;
        provider.CLASSES.LAT_WATER_RESERVOIR{1,1}.PARA.reservoir_contact_length = reservoir_contact_length;

        copyfile(char(fullfile(result_path,run_name_base)), ...
            char(fullfile(result_path,run_name)))
        movefile(char(fullfile(result_path,run_name,sprintf('%s.xlsx',run_name_base))), ...
            char(fullfile(result_path,run_name,sprintf('%s.xlsx',run_name))))
        save(fullfile(fullfile(result_path, run_name), [run_name '.mat']), 'provider');

        files{end+1} = run_name;
    end
end


N = numel(files);
erreurs = cell(N, 1);

parfor i = 1:N
    try
        run_name = files{i};
        mat_file = fullfile(fullfile(result_path, run_name), [run_name '.mat']);

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

% create RUN_INFO class
% [run_info, provider] = run_model(provider);
% run model
% [run_info, tile] = run_model(run_info);

% toc