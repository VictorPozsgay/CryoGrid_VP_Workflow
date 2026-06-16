function run_CG_parallel(source_path, init_format, run_names, result_path, constant_file)
%RUN_CG_PARALLEL Executes multiple independent CryoGrid simulations in parallel.
%
% This function launches several independent CryoGrid simulations
% simultaneously using MATLAB's Parallel Computing Toolbox. Each simulation
% is associated with a different run name and is executed by calling
% RUN_CG on a separate worker in a local parallel pool.
%
%
% INPUTS
% ------
%   source_path : string or char
%       Path to the CryoGrid source code. The entire directory tree is added
%       to the MATLAB search path by each worker through RUN_CG.
%
%   init_format : string or char
%       CryoGrid initialization format identifier (typically 'EXCEL').
%
%   run_names : cell array of char or string array
%       Collection of simulation run names to execute in parallel.
%
%       Each run name is assumed to correspond to a separate run folder:
%
%           result_path/
%               run_name1/
%                   run_name1.xlsx
%
%               run_name2/
%                   run_name2.xlsx
%
%               ...
%
%               run_nameN/
%                   run_nameN.xlsx
%
%   result_path : string or char
%       Path to the directory containing the run folders.
%
%   constant_file : string or char
%       Path to the Excel file containing the constant CryoGrid parameters.
%

% --- Parallel pool
delete(gcp('nocreate'))
nWorkers = length(run_names);   % 1 node per run
nWorkers = min(nWorkers, parcluster('local').NumWorkers);
parpool('local', nWorkers);

% --- Running parallel jobs
parfor i = 1:numel(run_names)
    r = run_names{i};

    fprintf('--- Running %s on worker %d ---\n', r, getCurrentTask().ID);

    run_CG(source_path, init_format, r, result_path, constant_file)

    fprintf('--- End %s ---\n', r);
end

delete(gcp('nocreate'))

end
