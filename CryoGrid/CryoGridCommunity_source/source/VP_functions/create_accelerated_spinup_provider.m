function providerInit = create_accelerated_spinup_provider(init_format, run_name, result_path, source_path, constant_file)
%CREATE_ACCELERATED_SPINUP_PROVIDER  Build CryoGrid PROVIDER object for accelerated spinup simulations
%
% This function constructs a fully configured CryoGrid PROVIDER object based on
% multiple Excel parameter files and generates an accelerated spinup-ready simulation setup.
%
%
% INPUTS
% ------
% init_format   (char|string)
%     Initialization format identifier used by CryoGrid (e.g. 'EXCEL3D')
%
% run_name      (char|string)
%     Name of the simulation run. Used for output directory and file naming.
%
% result_path   (char|string)
%     Root directory for simulation outputs.
%
% source_path   (char|string)
%     Path to CryoGrid source code (added to MATLAB path).
%
% constant_file (char|string)
%     Constant configuration file used by PROVIDER.
%
%
% OUTPUTS
% -------
% providerInit  (PROVIDER)
%     Fully constructed CryoGrid PROVIDER object
%
%
% EXCEL INPUT FILES
% ------------------
% The function reads the following configuration files from:
%   [result_path run_name '\']
%
%   1. NEW_PARAMS.xlsx
%      Defines parameter modifications applied to the base PROVIDER.
%
%   2. TILE_LOOP_INIT.xlsx
%      Defines the initial tile configuration.
%
%   3. TILE_LOOP_NEXT.xlsx
%      Defines the tile configuration replicated across spinup loops.
%
%
% SEE ALSO
% --------
% PROVIDER, assign_paths, read_const, read_parameters
%

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

end_time_new_dt = min(start_dt + calyears(30) - days(1), end_dt);
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
