%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

result_path = '..\CryoGridCommunity_results\templates\restart_broken\';
source_path = '..\CryoGridCommunity_source\';

modify.restart_file_path = result_path;


%%%%%%%%%%%%%%%%%%%%%%%% end user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
%                             do not change
% -------------------------------------------------------------------------

% add source code path
addpath(genpath(source_path));

% -------------------------------------------------------------------------
%                             code run
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
%                             PART I
%                             CREATE AUTOMATIC LOOPS
% -------------------------------------------------------------------------

[TNew, GenParamsStruct] = interpret_new_params(result_path);
[TNew, TInit, TNext, TRestart] = setup_files(result_path, TNew, GenParamsStruct);



[TNew, TInit, TNext, TRestart] = include_input_params(TNew, TInit, TNext, TRestart);
TInit = duplicate_forcing_init(TInit, 1);
[TNew, TInit, TNext, TRestart, TAll, result, dictDtEnd] = create_automatic_loops(TNew, TInit, TNext, TRestart, result_path, GenParamsStruct);
write_automatic_loops(TAll, result, result_path);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[lastFileExpected, TDates] = find_last_file_expected(result_path, TAll);
lastStruct = find_last_file_out_last_timestep(result_path);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

new_diagnostic_run(TAll, lastFileExpected, TDates, lastStruct, source_path, result_path);

TRun = create_template_loop_run(TAll, TNext, TRestart);
new_write_individual_loop_folders(TRun, TDates, result_path)

run_names = arrayfun(@(k) sprintf('loop%d', k), ...
    0:height(TDates)-1, 'UniformOutput', false)';
init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
constant_file = 'CONSTANTS_excel'; %filename of file storing constants
run_CG_parallel(source_path, init_format, run_names, ...
    result_path, constant_file)
% shut down parallel pool
delete(gcp('nocreate'))
