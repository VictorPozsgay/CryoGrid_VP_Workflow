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

%create and load PROVIDER
providerNew = PROVIDER;
providerNew = assign_paths(providerNew, init_format, run_name, result_path, constant_file);
providerNew.PARA.parameter_file = [result_path run_name '\' 'NEW_PARAMS2.xlsx'];
providerNew = read_const(providerNew);
providerNew = read_parameters(providerNew);

%create and load PROVIDER
providerInit = PROVIDER;
providerInit = assign_paths(providerInit, init_format, run_name, result_path, constant_file);
providerInit.PARA.parameter_file = [result_path run_name '\' 'TILE_LOOP_INIT.xlsx'];
providerInit = read_const(providerInit);
providerInit = read_parameters(providerInit);

%create and load PROVIDER
providerNext = PROVIDER;
providerNext = assign_paths(providerNext, init_format, run_name, result_path, constant_file);
providerNext.PARA.parameter_file = [result_path run_name '\' 'TILE_LOOP_NEXT.xlsx'];
providerNext = read_const(providerNext);
providerNext = read_parameters(providerNext);



% %%%%%%%%%%%%%%%%%

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

% providerInit.CLASSES.TILE_1D = [providerInit.CLASSES.TILE_1D(~cellfun(@isempty,providerInit.CLASSES.TILE_1D)); ...
%     repmat(providerNext.CLASSES.TILE_1D(~cellfun(@isempty,providerNext.CLASSES.TILE_1D)),numLoops,1)];

providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.tile_class = cellfun(@class, providerInit.CLASSES.TILE_1D, ...
    'UniformOutput', false);

providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.tile_class_index = transpose(1:size(providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.tile_class,1));
providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.number_of_runs_per_tile = ones(size(providerInit.CLASSES.RUN_1D_POINT_SPINUP{1,1}.PARA.tile_class,1),1);


%%%%%%%%%%%%%%%%%
% identify classes with new parameters
cls = fieldnames(providerNew.CLASSES);
for i = 1:size(cls,1)
    c = cls{i}; % class c to modify, might be multiple iterations of the same class
    class_func = str2func(c);
    new_class = class_func();
    new_class = provide_PARA(new_class); % checks format of default class c
    for j = 1:size(providerNew.CLASSES.(c),1)
        if any(string(c) == ["GRID_user_defined", "STRAT_classes", "STRAT_layers", "STRAT_linear"])
            providerInit.CLASSES.(c){j,1} = copy(providerNew.CLASSES.(c){j,1});
        else
            % find all parameters to modify in class c, tile j, that are
            % different from default value
            pars = fieldnames(new_class.PARA);
            modpars = pars(cellfun(@(f) isfield(providerNew.CLASSES.(c){j,1}.PARA,f) && ~isequal(providerNew.CLASSES.(c){j,1}.PARA.(f), new_class.PARA.(f)), pars));
            for k = 1:size(modpars,1) % find all (param,value) to change
                p = modpars{k};
                v = providerNew.CLASSES.(c){j,1}.PARA.(p);
                if (isfield(providerInit.CLASSES, c)) && (size(providerInit.CLASSES.(c),1)>=j) && (isfield(providerInit.CLASSES.(c){j,1}.PARA, p))
                    providerInit.CLASSES.(c){j,1}.PARA.(p) = v;
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%

forc = providerInit.CLASSES.FORCING_seb_mat(~cellfun(@isempty,providerInit.CLASSES.FORCING_seb_mat));
providerInit.CLASSES.FORCING_seb_mat = {forc{1,1}; copy(forc{1,1})};

endTime = datetime(providerInit.CLASSES.FORCING_seb_mat{1,1}.PARA.start_time','Format','yyyyMMdd') + days(1);
providerInit.CLASSES.FORCING_seb_mat{1,1}.PARA.end_time = [endTime.Year; endTime.Month; endTime.Day];

for j = 1:size(providerInit.CLASSES.TILE_1D,1)
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


% create RUN_INFO class
[run_info, providerInit] = run_model(providerInit);
% run model
[run_info, tile] = run_model(run_info);

toc
