function run_CG(source_path, init_format, run_name, result_path, constant_file)

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
