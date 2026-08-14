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

massif_num    = 5;
MASSIF_NUM    = sprintf('%02d',massif_num);
result_path   = char(fullfile(CG_RESULTS_PATH,'templates\'));
run_name      = 'test_spatial'; % name of parameter file (without file extension) AND name of subfolder (in result_path) within which it is located
TARGET_FOLDER = char(fullfile(result_path,run_name));
constant_file = 'CONSTANTS_excel'; %filename of file storing constants
init_format   = 'EXCEL3D';


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
provider = replace_PATHS_strings(provider, ...
    {'TARGET_FOLDER';'CG_FORCING_PATH';'MASSIF_NUM';'massif_num'}, ...
    {TARGET_FOLDER;CG_FORCING_PATH;MASSIF_NUM;massif_num});


% create RUN_INFO class
 [run_info, provider] = run_model(provider);
% run model
 [run_info, tile] = run_model(run_info);

% toc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% move files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

massif_folder = fullfile(TARGET_FOLDER,sprintf('massif_%s',MASSIF_NUM));

if ~isfolder(massif_folder)
    mkdir(massif_folder)
end

movefile(fullfile(TARGET_FOLDER,'*.mat'),massif_folder)