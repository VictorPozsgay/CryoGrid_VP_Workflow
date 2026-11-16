%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%


%% Automatically find the root of CryoGrid/ 
% If easier, just comment this out and  manually type your ROOT_PATH so
% that
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


%% The 5 parameters needed to run a spatial simulation (ENTER MASSIF NUMBER)
massif_num    = 2; % specify SAFRAN massif number (currently choose between 2,3,5,10)
init_format   = 'EXCEL3D'; % choose the option corresponding to the parameter file format
run_name      = 'test_spatial_small'; % name of parameter file (without file extension) AND name of subfolder (in result_path) within which it is located
result_path   = char(fullfile(CG_RESULTS_PATH,'templates\'));
constant_file = 'CONSTANTS_excel'; %filename of file storing constants


%% Values for replace_PATHS_strings()
TARGET_FOLDER = char(fullfile(result_path,run_name));
% Zero-padded massif identifier used in file and folder names.
MASSIF_NUM = char(sprintf('%02d',massif_num));
massif_folder = fullfile(TARGET_FOLDER,sprintf('massif_%s',MASSIF_NUM));

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

provider = replace_PATHS_strings( ...
    provider, ...
    {'TARGET_FOLDER';'CG_FORCING_PATH';'MASSIF_NUM';'massif_num'}, ...
    {TARGET_FOLDER;CG_FORCING_PATH;MASSIF_NUM;massif_num});

% create RUN_INFO class
[run_info, provider] = run_model(provider);
% run model
[run_info, tile] = run_model(run_info);


% ---------------------------------------------------------------------
% Organize output files
% ---------------------------------------------------------------------

if ~isfolder(massif_folder)
    mkdir(massif_folder);
end

movefile(fullfile(TARGET_FOLDER,'*.mat'),massif_folder);

% toc
