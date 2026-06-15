function provider = construct_provider(init_format, run_name, result_path, constant_file, param_file)
%CONSTRUCT_PROVIDER  Initialize and load a CryoGrid PROVIDER object from Excel inputs
%
% This function creates and configures a CryoGrid PROVIDER object by
% assigning file paths and reading constant and parameter definitions from
% Excel input files. It serves as a lightweight wrapper around the standard
% PROVIDER initialization workflow and ensures consistent setup of simulation
% input data across different model configurations.
%
%
% INPUTS
% ------
% init_format   (char|string)
%     Initialization format identifier used by CryoGrid (e.g. 'EXCEL3D').
%
% run_name      (char|string)
%     Name of the simulation run. Used to construct input/output paths.
%
% result_path   (char|string)
%     Root directory where simulation data and parameter files are stored.
%
% constant_file (char|string)
%     Name of the file containing constant model definitions (without extension).
%
% param_file    (char|string)
%     Name of the Excel parameter file (without ".xlsx" extension).
%
%
% OUTPUT
% ------
% provider      (PROVIDER)
%     Fully initialized CryoGrid PROVIDER object with:
%       - paths assigned via assign_paths
%       - constants loaded via read_const
%       - parameters loaded via read_parameters
%
%
% DESCRIPTION
% -----------
% The function performs the standard CryoGrid initialization sequence:
%
%   1. Create empty PROVIDER object
%   2. Assign run-specific paths and configuration
%   3. Set parameter file location
%   4. Load constant definitions
%   5. Load model parameters
%
% This wrapper ensures consistent initialization across multiple simulations
% and reduces repetitive setup code in higher-level scripts.
%
%
% SEE ALSO
% --------
% PROVIDER, assign_paths, read_const, read_parameters
%

provider = PROVIDER;
provider = assign_paths(provider, init_format, run_name, result_path, constant_file);
provider.PARA.parameter_file = [result_path run_name '\' param_file '.xlsx'];
provider = read_const(provider);
provider = read_parameters(provider);

end