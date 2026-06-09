%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
ext_dict = dictionary('EXCEL3D','.xlsx');

numLoops = 5;

result_path = '..\CryoGridCommunity_results\templates\automatic_loops\';
source_path = '..\CryoGridCommunity_source\';
constant_file = 'CONSTANTS_excel'; %filename of file storing constants

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

[TNew, TInit, TNext, TRestart] = setup_files(result_path, numLoops);
[TNew, TInit, TNext, TRestart] = include_input_params(TNew, TInit, TNext, TRestart);
[TNew, TInit, TNext, TRestart, TAll, result] = create_automatic_loops(TNew, TInit, TNext, TRestart, result_path, numLoops);
write_automatic_loops(TAll, result, result_path);

% -------------------------------------------------------------------------
%                             PART II
%                             RUN AUTOMATIC LOOPS
% -------------------------------------------------------------------------

diagnostic_run(TAll, source_path, init_format, constant_file, result_path, numLoops);

% -------------------------------------------------------------------------
%                             PART III
%                             CREATE INDIVIDUAL LOOP RUNS
% -------------------------------------------------------------------------

TRun = create_template_loop_run(TAll, TRestart);
write_individual_loop_folders(TRun, result_path, numLoops, init_format, constant_file, ext_dict);

% -------------------------------------------------------------------------
%                             PART IV
%                             RUN INDIVIDUAL LOOP RUNS
% -------------------------------------------------------------------------

run_names = arrayfun(@(k) sprintf('loop%d', k), ...
    1:numLoops, 'UniformOutput', false)';
run_CG_parallel(source_path, init_format, run_names, ...
    result_path, constant_file)

% clearvars;
