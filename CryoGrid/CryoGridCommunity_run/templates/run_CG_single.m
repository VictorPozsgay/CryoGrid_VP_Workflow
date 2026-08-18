%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

[file_path,file_name] = fileparts(mfilename('fullpath'));

while ~strcmp(file_name,'CryoGrid')
    [file_path,file_name]=fileparts(file_path);
    ROOT_PATH = char(fullfile(file_path,file_name));
end

CG_FORCING_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_forcing/"));
CG_RESULTS_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_results/"));
CG_RUN_PATH     = char(fullfile(ROOT_PATH,"CryoGridCommunity_run/"));
CG_SOURCE_PATH  = char(fullfile(ROOT_PATH,"CryoGridCommunity_source/"));


%% The 4 parameters needed to run a simulation
init_format   = 'EXCEL3D'; % choose the option corresponding to the parameter file format
run_name      = 'test_spatial'; % name of parameter file (without file extension) AND name of subfolder (in result_path) within which it is located
result_path   = char(fullfile(CG_RESULTS_PATH,'templates\'));
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
provider = assign_paths(provider, init_format, run_name, result_path, constant_file);
provider = read_const(provider);
provider = read_parameters(provider);

% % create RUN_INFO class
%  [run_info, provider] = run_model(provider);
% % run model
%  [run_info, tile] = run_model(run_info);

% toc