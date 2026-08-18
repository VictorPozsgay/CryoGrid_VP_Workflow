%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
result_path = '..\CryoGridCommunity_results\templates\';
source_path = '..\CryoGridCommunity_source\';
constant_file = 'CONSTANTS_excel'; %filename of file storing constants

run_name = 'restart_broken'; % name of parameter file (without file extension) AND name of subfolder (in result_path) within which it is located

numLoops = 5;

%%%%%%%%%%%%%%%%%%%%%%%% end user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
%                             do not change
% -------------------------------------------------------------------------

% add source code path
addpath(genpath(source_path));

% create PROVIDER class object for the multiloop spinup
providerInit = create_model_loops(init_format, run_name, result_path, source_path, constant_file, numLoops);
% check if simulation is finished, if not, adapts the provider to restart
% from broken point
[providerInit, runBool] = checkpoint_manager(providerInit, result_path, run_name);
% write provider class to excel
provider_to_parameter_file_excel(providerInit, result_path, run_name)

% % if simulation is not finished, run the model
% if runBool
%     run_CG(source_path, init_format, run_name, result_path, constant_file)
% end
% 
% % Create individual simulations from each loop
% % initialize the new PROVIDER class
% providerInit = initiate_restart_provider(init_format, run_name, result_path, source_path, constant_file);
% % creates folders for each loop and populates with the appropriate files
% write_individual_loop_folders(numLoops, providerInit)
% % run parallel simulations for each loop
% run_CG_parallel(source_path, init_format, ...
%     arrayfun(@(i) sprintf('loop%d', i), 0:numLoops, 'UniformOutput', false), ...
%     [result_path run_name '\'], constant_file)



