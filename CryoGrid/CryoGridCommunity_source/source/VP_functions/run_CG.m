function run_CG(source_path, init_format, run_name, result_path, constant_file)
%RUN_CG Executes a standard CryoGrid simulation from a parameter file.
%
% This function initializes the CryoGrid source code, constructs a PROVIDER
% object from the specified parameter files, creates the corresponding
% RUN_INFO object, and executes the simulation.
%
%
% INPUTS
% ------
%   source_path : string or char
%       Path to the CryoGrid source code. The entire directory tree is added
%       to the MATLAB search path using addpath(genpath(...)).
%
%   init_format : string or char
%       CryoGrid initialization format identifier (typically 'EXCEL').
%
%   run_name : string or char
%       Name of the simulation run. This corresponds to the folder
%       containing the parameter Excel file(s) and is also used as the
%       simulation name.
%
%   result_path : string or char
%       Path to the directory containing the run folder.
%
%       The expected directory structure is:
%
%           result_path/
%               run_name/
%                   run_name.xlsx
%                   <parameter files>
%
%   constant_file : string or char
%       Path to the Excel file containing the constant CryoGrid parameters.
%


% add source code path
addpath(genpath(source_path));

%create and load PROVIDER
provider = PROVIDER;
provider = assign_paths(provider, init_format, run_name, result_path, constant_file);
provider = read_const(provider);
provider = read_parameters(provider);

% create RUN_INFO class
[run_info, ~] = run_model(provider);
% run model
[~, ~] = run_model(run_info);

toc

end
