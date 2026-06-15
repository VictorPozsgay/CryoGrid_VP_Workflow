%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

% clear, close('all'), clc
% tic
%init_format = 'EXCEL'; 
%init_format = 'YAML';
init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format

result_path = '..\CryoGridCommunity_results\templates\';
source_path = '..\CryoGridCommunity_source\';
constant_file = 'CONSTANTS_excel'; %filename of file storing constants

run_name = 'restart_broken'; % name of parameter file (without file extension) AND name of subfolder (in result_path) within which it is located
%run_name = 'CG_EXAMPLE_sensitivity_test'; % name of parameter file (without file extension) AND name of subfolder (in result_path) within which it is located


numLoops = 5;

%%%%%%%%%%%%%%%%%%%%%%%% end user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
%                             do not change
% -------------------------------------------------------------------------

% add source code path
addpath(genpath(source_path));

providerInit = create_model_loops(init_format, run_name, result_path, source_path, constant_file, numLoops);
[providerInit, runBool] = checkpoint_manager(providerInit, result_path, run_name);

if runBool
    % create RUN_INFO class
    [run_info, providerInit] = run_model(providerInit);
    % run model
    [run_info, tile] = run_model(run_info);
end



% toc

function providerInit = initiate_restart_provider(init_format, run_name, result_path, source_path, constant_file)
%create and load PROVIDER for the initial loop
providerNew = construct_provider(init_format, run_name, result_path, constant_file, 'NEW_PARAMS');
providerRestart = construct_provider(init_format, run_name, result_path, constant_file, 'RESTART');
providerRestart = modify_parameters(providerRestart, providerNew);

providerInit = create_model_loops(init_format, run_name, result_path, source_path, constant_file, 1);
providerInit = shift_to_next_tile(providerInit, 1);

fns = fieldnames(providerRestart.CLASSES);
fns = fns(contains(fns, 'OUT_'));
for i = 1:size(fns,1)
    f = fns{i};
    providerInit.CLASSES.(f) = providerRestart.CLASSES.(f);
end

providerInit.CLASSES.TILE_1D{3,1}.PARA.out_class = fns;
providerInit.CLASSES.TILE_1D{3,1}.PARA.out_class_index = ones(size(fns,1),1);
providerInit.CLASSES.TILE_1D{3,1}.PARA.forcing_class_index = 1;

end

providerInit = initiate_restart_provider(init_format, run_name, result_path, source_path, constant_file);

function write_individual_loop_folders(numLoops, providerInit)

result_path = string(providerInit.PARA.result_path);
run_name = string(providerInit.PARA.run_name);
constant_file = string(providerInit.PARA.constant_file);

for n = 0:numLoops
    folder = result_path + run_name + "\loop" + string(n);
    if ~exist(folder, 'dir')
        mkdir(folder);
    end

    idxForcing = 1;
    if n > 0
        idxForcing = 2;
    end

    endTime = providerInit.CLASSES.FORCING_seb_mat{idxForcing,1}.PARA.end_time;
    endTime = string(datetime(endTime','Format','yyyyMMdd'));
    file = sprintf("%s_tile%d_run1_%s_last_timestep", run_name, 2*n+1, endTime);

    % Write to Excel
    path_out = [folder "loop" string(2*n+1) '.xlsx'];
    if isfile(path_out)
        try
            delete(path_out);
        catch
            warning("Could not delete file: %s", path_out);
        end
    end

    copyfile(constant_file,folder)
    copyfile(result_path+run_name+"\"+file+".mat",folder+"\"+run_name+"_loop"+n+".mat")
    % movefile(result_path+run_name+"\"+file+".mat",folder)
end

end

write_individual_loop_folders(numLoops, providerInit)


function run_CG_parallel(numLoops, providerInit)

result_path = string(providerInit.PARA.result_path);
folder_name = string(providerInit.PARA.run_name);
run_names = arrayfun(@(k) sprintf('loop%d', k), 0:numLoops, 'UniformOutput', false)';

% % add source code path
% addpath(genpath(source_path));

%% --- Parallel pool
delete(gcp('nocreate'))
nWorkers = length(run_names);   % 1 node per run
nWorkers = min(nWorkers, parcluster('local').NumWorkers);
parpool('local', nWorkers);

%% --- Running parallel jobs
parfor i = 1:numel(run_names)
    r = run_names{i};
    folder = result_path + folder_name + "\" + r + "\";

    fprintf('--- Running %s on worker %d ---\n', r, getCurrentTask().ID);

    % PROVIDER local (important)
    providerLoop = providerInit;
    providerLoop.CLASSES.TILE_1D{2,1} = copy(providerInit.CLASSES.TILE_1D{2,1});
    providerLoop.CLASSES.TILE_1D{2,1}.PARA.restart_file_path = char(folder);
    providerLoop.CLASSES.TILE_1D{2,1}.PARA.restart_file_name = char(folder_name+"_"+r);

    % providerLoop.PARA = copy(providerInit.PARA);
    providerLoop.PARA.run_name = char(r);
    providerLoop.PARA.result_path = char(result_path + folder_name + "\");


    % Run CryoGrid
    [run_info, ~] = run_model(providerLoop);
    [~, ~] = run_model(run_info);

    fprintf('--- End %s ---\n', r);
end

delete(gcp('nocreate'))

end


run_CG_parallel(numLoops, providerInit)
