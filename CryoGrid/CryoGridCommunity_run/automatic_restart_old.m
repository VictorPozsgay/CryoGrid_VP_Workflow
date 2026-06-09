%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
ext_dict = dictionary('EXCEL3D','.xlsx');

numLoops = 5;

result_path = '..\CryoGridCommunity_results\templates\restart_broken_old\';
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

[TNew, TInit, TNext, TRestart] = setup_files(result_path, numLoops);
[TNew, TInit, TNext, TRestart] = include_input_params(TNew, TInit, TNext, TRestart);

TAll = vertcat(TInit, TNext, TRestart);

supOrder = ["RUN_INFO"; "POINT"; "TILE"; "FORCING"; "OUT"; "GRID";
    "STRATIGRAPHY_CLASSES"; "STRATIGRAPHY_STATVAR"; "GROUND"; "SNOW";
    "LATERAL"; "LATERAL_IA"];
[~, TAll.supRank] = ismember(TAll.sup, supOrder); 
TAll.supRank(TAll.supRank == 0) = inf;
TAll = sortrows(TAll, {'supRank','idx'});

mask = (TAll.sup == "OUT") & (TAll.cls == "OUT_last_timestep") & (TAll.idx == 2);
TAll(mask,:) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mask = (TAll.sup == "FORCING");

rowIdx = identifying_line_to_change(TAll.blocks{mask}, ...
    "FORCING_seb_mat", 1, "start_time");
time = TAll.blocks{mask}(rowIdx,:);
iStart = find(string(time) == "H_LIST", 1);
iEnd   = find(string(time) == "END", 1);
vals = time(iStart+1:iEnd-1);
dtStart = datetime(vals{1}, vals{2}, vals{3});

rowIdx = identifying_line_to_change(TAll.blocks{mask}, ...
    "FORCING_seb_mat", 1, "end_time");
time = TAll.blocks{mask}(rowIdx,:);
iStart = find(string(time) == "H_LIST", 1);
iEnd   = find(string(time) == "END", 1);
vals = time(iStart+1:iEnd-1);
dtEnd = datetime(vals{1}, vals{2}, vals{3});


fileOUT = dir(fullfile(result_path, '*_last_timestep.mat'));
if numel(fileOUT) == 0
    dtLastTimestep = dtStart;
else
    out = load(join_rel_path(result_path,fileOUT.name));
    dtLastTimestep = datetime(out.out.OUTPUT_TIME,'ConvertFrom','datenum');
end

files = dir(fullfile(result_path, '*.mat'));
dtMostRecent = regexp(string({files.name}), '_(\d{8})\.mat$', 'tokens', 'once');
dtMostRecent = string([dtMostRecent{:}]);
dtMostRecent = datetime(dtMostRecent, 'InputFormat', 'yyyyMMdd');
dtMostRecent = max(dtMostRecent);

skip = true;
restart = false;

if dtLastTimestep < dtEnd
    skip = false;
    if numel(dtMostRecent) > 0
        disp('Did not reach the end, simulation was broken')
        fprintf('Simulation to restart on %s (new date) \n', dtMostRecent)
        restart = true;
    else
        fprintf('Simulation will start as expected on %s \n', dtStart)
    end
else
    disp('Simulation already completed!')
end

if restart
    disp('restart, needs some work')

    mask = ~((TAll.sup == "RUN_INFO") | (TAll.sup == "POINT") | ...
        (TAll.sup == "TILE") | (TAll.sup == "FORCING")  | ...
        (TAll.sup == "OUT"));
    TAll(mask,:) = [];

    mask = (TAll.sup == "TILE") & (TAll.cls == "TILE_1D") & (TAll.idx == 1);
    TAll(mask,:) = [];

    ops = struct([]);
    ops(1).param = "tile_class";
    ops(1).value = {"TILE_1D","TILE_1D"};
    ops(2).param = "tile_class_index";
    ops(2).value = {1,2};
    ops(3).param = "number_of_runs_per_tile";
    ops(3).value = {1,1};
    [TAll, ~] = modify_blocks(TAll, TAll, false, ...
        "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ops);

    restart_file_name = fileOUT.name;

    ops = struct([]);
    ops(1).param = "TILE_1D";
    ops(1).value = 1;
    ops(2).param = "restart_file_name";
    ops(2).value = restart_file_name;
    [TAll, idxBlock] = modify_blocks(TAll, TAll, false, ...
        "TILE", "TILE_1D", 2, ops);
    TAll.idx(idxBlock) = 1;

    ops = struct([]);
    ops(1).param = "TILE_1D";
    ops(1).value = 2;
    ops(2).param = "out_class";
    ops(2).value = {"OUT_last_timestep", "OUT_all_lateral", "OUT_regridded", "OUT_snow_all"};
    ops(3).param = "out_class_index";
    ops(3).value = {1,1,1,1};
    [TAll, idxBlock] = modify_blocks(TAll, TAll, false, ...
        "TILE", "TILE_1D", 3, ops);
    TAll.idx(idxBlock) = 2;

    ops = struct([]);
    ops(1).param = "start_time";
    ops(1).value = {dtMostRecent.Year, dtMostRecent.Month, dtMostRecent.Day};
    [TAll, idxBlock] = modify_blocks(TAll, TAll, false, ...
        "FORCING", "FORCING_seb_mat", 1, ops);
    
else
    disp('normal from start')
    mask = (TAll.sup == "TILE") & (TAll.cls == "TILE_1D") & (TAll.idx > 1);
    TAll(mask,:) = [];
    mask = (TAll.sup == "OUT") & (TAll.cls == "OUT_do_nothing") & (TAll.idx == 1);
    TAll(mask,:) = [];

    ops = struct([]);
    ops(1).param = "out_class";
    ops(1).value = {"OUT_last_timestep", "OUT_all_lateral", "OUT_regridded", "OUT_snow_all"};
    ops(2).param = "out_class_index";
    ops(2).value = {1,1,1,1};
    [TAll, idxBlock] = modify_blocks(TAll, TAll, false, ...
        "TILE", "TILE_1D", 1, ops);
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Concatenate vertically
result = cat(1, TAll.blocks{:});

write_automatic_loops(TAll, result, result_path);
 
 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~, folder_name] = fileparts(join_rel_path(result_path));
run_CG(source_path, init_format, folder_name, ...
    extractBefore(result_path, folder_name), constant_file)

