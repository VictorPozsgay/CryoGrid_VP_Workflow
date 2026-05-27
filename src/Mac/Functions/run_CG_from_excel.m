function run_CG_from_excel(run_name, constant_file, result_path, source_path)

    % Add source code to MATLAB path
    addpath(genpath(source_path));

    % Type of input file
    init_format = 'EXCEL3D';  % can remain fixed if always this format

    % Create and load the provider
    provider = PROVIDER;
    provider = assign_paths(provider, init_format, run_name, result_path, constant_file);
    provider = read_const(provider);
    provider = read_parameters(provider);

    % Create objects needed for the simulation
    [run_info, provider] = run_model(provider);
    [run_info, tile]     = run_model(run_info);
end
