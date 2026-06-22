%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
result_path = '..\CryoGridCommunity_results\templates\';
source_path = '..\CryoGridCommunity_source\';
constant_file = 'CONSTANTS_excel'; %filename of file storing constants

run_name = 'accelerated_spinup'; % name of parameter file (without file extension) AND name of subfolder (in result_path) within which it is located

%%%%%%%%%%%%%%%%%%%%%%%% end user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
%                             do not change
% -------------------------------------------------------------------------

% add source code path
addpath(genpath(source_path));

% create PROVIDER class object for the multiloop spinup
providerInit = construct_provider(init_format, run_name, result_path, constant_file, 'TILES_ACCELERATED');
providerNew = construct_provider(init_format, run_name, result_path, constant_file, 'NEW_PARAMS');
providerInit = modify_parameters(providerInit, providerNew);

fns = fieldnames(providerInit.CLASSES.FORCING_seb_mat{1,1}.PARA);
for i = 2:size(providerInit.CLASSES.FORCING_seb_mat,1)
    for f = 1:size(fns,1)
        fn = fns{f};
        providerInit.CLASSES.FORCING_seb_mat{i,1}.PARA.(fn) = providerInit.CLASSES.FORCING_seb_mat{1,1}.PARA.(fn);
    end
    providerInit.CLASSES.FORCING_seb_mat{i,1}.PARA.class_index = i;
end

startTime = providerNew.CLASSES.FORCING_seb_mat{1,1}.PARA.start_time;
endTime = providerNew.CLASSES.FORCING_seb_mat{1,1}.PARA.end_time;

start_dt = datetime(startTime','Format','yyyyMMdd');
end_dt   = datetime(endTime','Format','yyyyMMdd');

end_time_new_dt = min(start_dt + calyears(10) - days(1), end_dt);
end_time_new = [end_time_new_dt.Year; end_time_new_dt.Month; end_time_new_dt.Day];

for i = 1:size(providerInit.CLASSES.FORCING_seb_mat,1)-1
    providerInit.CLASSES.FORCING_seb_mat{i,1}.PARA.end_time = end_time_new;
end

providerInit.CLASSES.INIT_TTOP_from_forcing{1,1}.PARA.start_time = startTime;
providerInit.CLASSES.INIT_TTOP_from_forcing{1,1}.PARA.end_time = end_time_new;

% restart path for OUT_last_timestep
endTime = string(datetime(providerInit.CLASSES.FORCING_seb_mat{1,1}.PARA.end_time','Format','yyyyMMdd'));
for i = [2, 5]
    providerInit.CLASSES.TILE_1D{i,1}.PARA.restart_file_path = [result_path run_name '\'];
    providerInit.CLASSES.TILE_1D{i,1}.PARA.restart_file_name = sprintf('%s_tile%d_run1_%s_last_timestep',run_name,i-1,endTime);
end

% check if simulation is finished, if not, adapts the provider to restart
% from broken point
[providerInit, runBool] = checkpoint_manager(providerInit, result_path, run_name, false);

% write provider class to excel
provider_to_parameter_file_excel(providerInit, result_path, run_name)

% if simulation is not finished, run the model
if runBool
    run_CG(source_path, init_format, run_name, result_path, constant_file)
end

% % run the model
% run_CG(source_path, init_format, run_name, result_path, constant_file)