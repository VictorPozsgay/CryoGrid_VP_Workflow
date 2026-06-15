function providerInit = create_model_loops(init_format, run_name, result_path, source_path, constant_file, numLoops)
%CREATE_MODEL_LOOPS  Build CryoGrid PROVIDER object for multi-loop spinup simulations
%
% This function constructs a fully configured CryoGrid PROVIDER object based on
% multiple Excel parameter files and generates a spinup-ready simulation setup.
% The configuration includes repeated tile structures and forcing chains that
% enable multi-loop simulations with consistent restart handling.
%
% Each spinup loop reuses and extends the previous configuration while ensuring
% that restart files are uniquely named and never overwritten.
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
% numLoops      (double, integer)
%     Number of spinup loops to generate.
%
%
% OUTPUTS
% -------
% providerInit  (PROVIDER)
%     Fully constructed CryoGrid PROVIDER object containing:
%       - Expanded TILE_1D structure over all loops
%       - FORCING_seb_mat spinup chain with independent copies
%       - RUN_INFO_CLASS metadata (tile mapping and run indices)
%       - Updated class parameters from Excel input files
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
% ALGORITHM
% ---------
% 1. Initialize CryoGrid PROVIDER objects:
%       providerNew  : parameter update definitions
%       providerInit : base configuration (initial tiles)
%       providerNext : loop tile template
%
% 2. Construct TILE_1D structure:
%       - Retain initial tiles
%       - Deep-copy loop tiles numLoops times
%       - Concatenate into final tile list
%
% 3. Update RUN_INFO_CLASS metadata:
%       - Assign tile class names
%       - Assign tile indices
%       - Set number of runs per tile
%
% 4. Apply parameter updates:
%       - Loop over classes defined in providerNew
%       - Update matching parameters in providerInit
%       - Fully replace selected structural classes (e.g. STRAT, GRID)
%
% 5. Build forcing spinup chain:
%       - Copy forcing objects using copy()
%       - Assign class indices
%       - Extend simulation time (end_time = start_time + 1 day)
%
% 6. Define restart logic:
%       - Each TILE (index ≥ 2) receives a unique restart filename
%       - Naming ensures no overwrite between loops:
%         <run_name>_tile<k>_run1_<YYYYMMDD>_last_timestep
%
%
% SEE ALSO
% --------
% PROVIDER, assign_paths, read_const, read_parameters
%

% add source code path
addpath(genpath(source_path));

%create and load PROVIDER for the initial loop
providerInit = construct_provider(init_format, run_name, result_path, constant_file, 'TILE_LOOP_INIT');
% providerInit = PROVIDER;
% providerInit = assign_paths(providerInit, init_format, run_name, result_path, constant_file);
% providerInit.PARA.parameter_file = [result_path run_name '\' 'TILE_LOOP_INIT.xlsx'];
% providerInit = read_const(providerInit);
% providerInit = read_parameters(providerInit);

%create and load PROVIDER for the subsequent loops
providerNext = construct_provider(init_format, run_name, result_path, constant_file, 'TILE_LOOP_NEXT');
% providerNext = PROVIDER;
% providerNext = assign_paths(providerNext, init_format, run_name, result_path, constant_file);
% providerNext.PARA.parameter_file = [result_path run_name '\' 'TILE_LOOP_NEXT.xlsx'];
% providerNext = read_const(providerNext);
% providerNext = read_parameters(providerNext);

%create and load PROVIDER for the new parameters to change
providerNew = construct_provider(init_format, run_name, result_path, constant_file, 'NEW_PARAMS');
% providerNew = PROVIDER;
% providerNew = assign_paths(providerNew, init_format, run_name, result_path, constant_file);
% providerNew.PARA.parameter_file = [result_path run_name '\' 'NEW_PARAMS.xlsx'];
% providerNew = read_const(providerNew);
% providerNew = read_parameters(providerNew);


%%%%%%%%%%%%%%%%%
% Create the full provider

initTiles = providerInit.CLASSES.TILE_1D(~cellfun(@isempty, providerInit.CLASSES.TILE_1D));
nextTiles = providerNext.CLASSES.TILE_1D(~cellfun(@isempty, providerNext.CLASSES.TILE_1D));
nextTiles = nextTiles(:);  % ensure column
repNext = cell(numel(nextTiles)*numLoops, 1);
k = 1;
for i = 1:numLoops
    for j = 1:numel(nextTiles)
        repNext{k} = copy(nextTiles{j});
        k = k + 1;
    end
end
providerInit.CLASSES.TILE_1D = [initTiles; repNext];


providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.tile_class = cellfun(@class, providerInit.CLASSES.TILE_1D, ...
    'UniformOutput', false);

providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.tile_class_index = transpose(1:size(providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.tile_class,1));
providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.number_of_runs_per_tile = ones(size(providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.tile_class,1),1);


%%%%%%%%%%%%%%%%%
% Identify classes with new parameters from providerNew and modify them into providerInit
providerInit = modify_parameters(providerInit, providerNew);

%%%%%%%%%%%%%%%%%
% Duplicate forcing (first tile just for 1 day to initialize, then real one for subsequent loops)
forc = providerInit.CLASSES.FORCING_seb_mat(~cellfun(@isempty,providerInit.CLASSES.FORCING_seb_mat));
providerInit.CLASSES.FORCING_seb_mat = [forc; {copy(forc{1,1})}];

for j = 1:size(providerInit.CLASSES.FORCING_seb_mat,1)
    providerInit.CLASSES.FORCING_seb_mat{j,1}.PARA.class_index = j;
end

endTime = datetime(providerInit.CLASSES.FORCING_seb_mat{1,1}.PARA.start_time','Format','yyyyMMdd') + days(1);
providerInit.CLASSES.FORCING_seb_mat{1,1}.PARA.end_time = [endTime.Year; endTime.Month; endTime.Day];

for j = 1:size(providerInit.CLASSES.TILE_1D,1)
    providerInit.CLASSES.TILE_1D{j,1}.PARA.class_index = providerInit.RUN_INFO_CLASS.PARA.tile_class_index(j,1);
    if j >= 2
        if rem(j, 2) == 0 % even
            idx = 1;
            if j > 2
                idx = 2;
            end
            endTime = string(datetime(providerInit.CLASSES.FORCING_seb_mat{idx,1}.PARA.end_time','Format','yyyyMMdd'));
            providerInit.CLASSES.TILE_1D{j,1}.PARA.restart_file_path = [result_path run_name '\'];
            providerInit.CLASSES.TILE_1D{j,1}.PARA.restart_file_name = sprintf('%s_tile%d_run1_%s_last_timestep',run_name,j-1,endTime);
        else % odd
        end
    end
end

end
