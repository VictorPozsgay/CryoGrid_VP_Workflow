%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
ext_dict = dictionary('EXCEL3D','.xlsx');

numLoops = 5;

result_path = '..\CryoGridCommunity_results\templates\restart_broken\';
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
[TNew, TInit, TNext, TRestart, TAll, result, dtEnd] = create_automatic_loops(TNew, TInit, TNext, TRestart, result_path, numLoops);
write_automatic_loops(TAll, result, result_path);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [lastFile, TDates] = find_last_file_expected(result_path, TIn)

[~, folder_name] = fileparts(join_rel_path(result_path));

mask = (TIn.sup == "TILE") & (TIn.cls == "TILE_1D");
idxs = num2cell(TIn{mask,'idx'})';

lastFile = '';
TDates = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','string'}, ...
    'VariableNames', {'tile','run','endDate','lastFile'});

for i = 1:numel(idxs)
    idx = idxs{i};
    vals = reading_line_block(TIn, "TILE", "TILE_1D", idx, "out_class");
    out = any(cellfun(@(x) isstring(x) && any(x == "OUT_last_timestep"), vals));
    if out
        vals = reading_line_block(TIn, "TILE", "TILE_1D", idx, "forcing_class_index");
        endTime = reading_line_block(TIn, "FORCING", "FORCING_seb_mat", vals{1}, "end_time");
        endTime = yyyymmdd(datetime(endTime{:}));
        vals = reading_line_block(TIn, "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, "number_of_runs_per_tile");
        nRun = vals{i};
        lastFile = sprintf("%s_tile%d_run%d_%d_last_timestep", folder_name, idx, nRun, endTime);
        TDates(end+1,:) = {idx, nRun, endTime, lastFile};
    end
end

end

[lastFile, TDates] = find_last_file_expected(result_path, TAll);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lastFile, lastTile] = find_last_file_out_last_timestep(result_path)

% find last file
files = dir(fullfile(result_path, '*_last.mat*'));

if isempty(files)
    lastFile = "";
    lastTile = 1;
else
    names = {files.name};

    pattern = '.*tile(\d+)_run(\d+)_(\d+)_last_timestep';

    tok = regexp(names, pattern, 'tokens');

    % remove files that didn't match (robustness)
    valid = ~cellfun(@isempty, tok);
    names = names(valid);
    tok = tok(valid);

    nums = cellfun(@(t) str2double(t{1}), tok);
    nums = vertcat(nums{:});

    % lexicographic sort: tile → run → date
    [~, idx] = sortrows(nums, [1 2 3]);

    lastIdx = idx(end);

    [~, lastFile] = fileparts(names{lastIdx});
    lastTile = nums(lastIdx, 1);
end

end

[lastFile, lastTile] = find_last_file_out_last_timestep(result_path);
% lastFile = "restart_broken_tile5_run1_19590901_last_timestep";
% lastTile = 5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% tiles = cell2mat(reading_line_block(TAll, "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, "tile_class_index"))';
% nruns = cell2mat(reading_line_block(TAll, "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, "number_of_runs_per_tile"))';
% TDates = table(tiles, nruns);
% TDates.endTime = cell(height(TDates),1);
% 
% for i = 1:height(TDates)
%     tile = TDates{i,'tiles'};
%     reading_line_block(TAll, "TILE", "TILE_1D", tile, "number_of_runs_per_tile");
% end

% if strcmp(lastFile, lastFileExpected)
%     disp('Simulation already finished!')
% else
%     if lastTile <= 1
%         disp('Restart simulation from the beginning')
%     else 
%         fprintf('Restart simulation from file \n%s\n', lastFile)
% 
%         lastDate = strsplit(lastFile,'_last_timestep');
%         lastDate = strsplit(lastDate{1}, '_');
%         lastDate = datetime(lastDate{end},"InputFormat","yyyyMMdd");
% 
%         mask = (TAll.sup == "TILE") & (TAll.cls == "TILE_1D") & (TAll.idx < lastTile-1);
%         TAll(mask,:) = [];
% 
%         mask = (TAll.sup == "TILE") & (TAll.cls == "TILE_1D");
%         idxs = num2cell(TAll{mask,'idx'})';
% 
%         ops = struct([]);
%         ops(1).param = "tile_class";
%         ops(1).value = repmat({"TILE_1D"},1,numel(idxs));
%         ops(2).param = "tile_class_index";
%         ops(2).value = idxs;
%         ops(3).param = "number_of_runs_per_tile";
%         ops(3).value = repmat({1},1,numel(idxs));
%         [TAll, ~] = modify_blocks(TAll, TAll, false, ...
%             "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ops);
% 
%         ops = struct([]);
%         ops(1).param = "restart_file_name";
%         ops(1).value = lastFile;
%         [TAll, ~] = modify_blocks(TAll, TAll, false, ...
%             "TILE", "TILE_1D", lastTile-1, ops);
% 
%         mask = (TAll.sup == "FORCING") & (TAll.cls == "FORCING_seb_mat");
%         max_forcing_index = max(TAll{mask,'idx'});
% 
%         vals = reading_line_block(TAll, "TILE", "TILE_1D", lastTile, "forcing_class_index");
% 
%         lineRefForcing = find((TAll.sup == "FORCING") & (TAll.cls == "FORCING_seb_mat") & (TAll.idx == vals{1}));
%         lineMaxForcing = find((TAll.sup == "FORCING") & (TAll.cls == "FORCING_seb_mat") & (TAll.idx == max_forcing_index));
% 
%         Tf = TAll(lineRefForcing,:);
%         Tf{1,"idx"} = vals{1};
%         ops = struct([]);
%         ops(1).param = "FORCING_seb_mat";
%         ops(1).value = max_forcing_index+1;
%         ops(2).param = "start_time";
%         ops(2).value = {lastDate.Year, lastDate.Month, lastDate.Day};
%         [Tf, ~] = modify_blocks(TAll, Tf, 1, ...
%             "FORCING", "FORCING_seb_mat", vals{1}, ops);
%         Tf{1,"idx"} = max_forcing_index+1;
% 
%         TAll = [TAll(1:lineMaxForcing,:); Tf; TAll(lineMaxForcing+1:end,:)];
%         result = cat(1, TAll.blocks{:});
% 
%         write_automatic_loops(TAll, result, result_path)
%     end
% 
%     [~, folder_name] = fileparts(join_rel_path(result_path));
%     run_CG(source_path, init_format, folder_name, ...
%         extractBefore(result_path, folder_name), constant_file)
% end






