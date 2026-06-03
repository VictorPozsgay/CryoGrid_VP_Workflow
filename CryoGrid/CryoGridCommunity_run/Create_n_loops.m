%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
ext_dict = dictionary('EXCEL3D','.xlsx');

numLoops = 2;

result_path = '..\CryoGridCommunity_results\templates\automatic_loops\';
source_path = '..\CryoGridCommunity_source\';
constant_file = 'CONSTANTS_excel'; %filename of file storing constants

modify.restart_file_path = result_path;


%%%%%%%%%%%%%%%%%%%%%%%% end user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
%                             do not change
% -------------------------------------------------------------------------


% -------------------------------------------------------------------------
%                             function definitions
% -------------------------------------------------------------------------

function p = join_rel_path(in,out,ext)
%JOIN_REL_PATH Construct a canonical path from directory, filename and extension.
%
%   P = JOIN_REL_PATH(IN, OUT, EXT)
%
%   Builds a path using FULLFILE and converts it to a canonical absolute
%   path using Java file utilities.
%
%   Inputs
%   ------
%   in : char
%       Input directory path.
%
%   out : char, optional
%       File or subdirectory name.
%       Default: "".
%
%   ext : char, optional
%       File extension to append to OUT.
%       Default: "".
%
%   Output
%   ------
%   p : char
%       Canonical absolute path.
%

arguments
    in char
    out char = ""
    ext char = ""
end

p = fullfile(in, append(out,ext));
p = char(java.io.File(p).getCanonicalPath());

end

function CB = format_template(result_path,template_file,ext)
%FORMAT_TEMPLATE Read and sanitize a template spreadsheet file.
%
%   CB = FORMAT_TEMPLATE(RESULT_PATH, TEMPLATE_FILE, EXT)
%
%   Reads a spreadsheet template file and converts unsupported missing
%   values into writable string-compatible values.
%
%   Inputs
%   ------
%   result_path : string or char
%       Base directory containing the template file.
%
%   template_file : string or char
%       Template filename without extension.
%
%   ext : string or char
%       File extension.
%
%   Output
%   ------
%   CB : cell array
%       Sanitized cell array representation of the spreadsheet.
%

pathB = join_rel_path(result_path,template_file,ext);

CB = readcell(pathB);

for i = 1:numel(CB)
    x = CB{i};

    if ismissing(x)
        CB{i} = "";

    elseif ischar(x)
        CB{i} = string(x);

    end
end

end

function rowIdx = identifying_line_to_change(sheet, class, index, ...
    string_to_find)

% Convert columns to strings
col1 = strtrim(string(sheet(:,1)));
col2 = strtrim(string(sheet(:,2)));

% Find matching class/index row
rowIdxClass = find((col1 == class) & (col2 == string(index)));

% Ensure uniqueness
if isempty(rowIdxClass)
    error('No matching class/index row found.');
elseif numel(rowIdxClass) > 1
    error('Multiple matching class/index rows found.');
end

% Convert to scalar integer
rowIdxClass = rowIdxClass(1);

% Find all rows matching string_to_find
rowIdxAll = find(col1 == string_to_find);

% Keep only rows AFTER rowIdxClass
rowIdx = rowIdxAll(rowIdxAll >= rowIdxClass);

% Take first one
if isempty(rowIdx)
    error('No matching row found after class/index row.');
end

rowIdx = rowIdx(1);

end

function sheet = replace_val_hlist(sheet, rowIdx, param, value)

arguments
    sheet
    rowIdx
    param
    value
end

vec = {param};

if iscell(value)
    vec = [vec, {"H_LIST"}, value, {"END"}];
else
    vec = [vec, {value}];
end

% CAREFUL: make sure the table is wide enough!!!
sheet(:, end+1:numel(vec)) = repmat({""}, size(sheet,1), ...
    numel(vec)-size(sheet,2));
vec = [vec, repmat({""}, 1, size(sheet,2)-numel(vec))];
sheet(rowIdx, 1:(numel(vec))) = vec;

end

function T = cut_into_blocks(data)

sepIdx = find(startsWith(strtrim(string(data(:,1))), "-"));
sepIdx = [sepIdx; size(data,1)+1];

nBlocks = numel(sepIdx)-1;
blocks = cell(1,nBlocks);

for i = 1:nBlocks
    blocks{i} = data(sepIdx(i):sepIdx(i+1)-1, :);    
    if ~startsWith(strtrim(string(blocks{i}(1,1))), "-")
        disp('Issue with block, not starting with "-"')
    end    
end

sup = strings(nBlocks,1);
cls = strings(nBlocks,1);
idx = zeros(nBlocks,1);

for i = 1:nBlocks
    sup(i) = string(blocks{i}{2,1});
    cls(i) = string(blocks{i}{3,1});
    idx(i) = blocks{i}{3,2};
end

T = table(sup, cls, idx);
T.blocks = blocks(:);

end

function [TOut, idxBlock] = modify_blocks(TIn, TOut, idxOut, sup, cls, idx, ops)
%MODIFY_BLOCKS Copy a block from TIn to TOut and modify one or more parameters.
%
%   TOut = MODIFY_BLOCKS(TIn, TOut, idxOut, sup, cls, idx, ops)
%
%   Searches TIn for the unique block identified by the triplet
%   (sup, cls, idx). The corresponding block is copied into TOut.
%
%   The source block is located by finding the row of TIn satisfying:
%
%       TIn.sup == sup
%       TIn.cls == cls
%       TIn.idx == idx
%
%   The index of the matching block is denoted idxBlock.
%
%   Destination block selection:
%       - If idxOut is a positive integer, the copied block is written
%         to TOut.blocks{idxOut}.
%       - If idxOut is 0 or false, the copied block is written to
%         TOut.blocks{idxBlock}, i.e. the same position as in TIn.
%
%   After the block has been copied, a sequence of parameter
%   modifications is applied to the copied block in TOut.
%
%   ops is a structure array whose elements contain:
%
%       ops(k).param   Parameter name to modify.
%       ops(k).value   New value to assign to the parameter.
%
%   For each operation k:
%
%       1. The parameter line corresponding to ops(k).param is located
%          within the copied block using IDENTIFYING_LINE_TO_CHANGE.
%
%       2. The parameter value is replaced by ops(k).value using
%          REPLACE_VAL_HLIST.
%
%   The source block in TIn is never modified.
%
%   Inputs
%   ------
%   TIn     Source table containing the original blocks.
%   TOut    Destination table to be modified.
%   idxOut  Destination block index. If 0 or false, use idxBlock.
%   sup     Superclass identifier of the source block.
%   cls     Class identifier of the source block.
%   idx     Numerical class index of the source block.
%   ops     Structure array of parameter modifications.
%
%   Output
%   ------
%   TOut      Modified output table.
%   idxBlock  Index of the source block found in TIn corresponding to
%             the triplet (sup, cls, idx).
%
%   Example
%   -------
%       ops(1).param = "tile_class";
%       ops(1).value = repmat({"TILE_1D"},1,2*numLoops-1);
%
%       ops(2).param = "start_time";
%       ops(2).value = {1958, 9, 1};
%
%       [TOut, idxBlock] = modify_blocks( ...
%           TInit, TOut, 0, ...
%           "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ...
%           ops);
%

mask = (TIn.sup == sup) & (TIn.cls == cls) & (TIn.idx == idx);
idxBlock = find(mask);

if ~idxOut
    idxOut = idxBlock;
end

TOut.blocks{idxOut} = TIn.blocks{idxBlock};

for k = 1:numel(ops)
    param = ops(k).param;
    value = ops(k).value;

    rowIdx = identifying_line_to_change(TIn.blocks{idxBlock}, ...
        cls, idx, param);

    TOut.blocks{idxOut} = replace_val_hlist( ...
        TOut.blocks{idxOut}, rowIdx, param, value);

end

end

function B = padBlockFcn(B, maxCols)

% Pad columns
B = [B, repmat({""}, size(B,1), maxCols-size(B,2))];

% Count trailing rows that are entirely ""
trailingEmpty = 0;

for r = size(B,1):-1:1
    if all(string(B(r,:)) == "")
        trailingEmpty = trailingEmpty + 1;
    else
        break
    end
end

% Ensure at least 2 trailing empty rows
if trailingEmpty < 2
    B = [B;
        repmat({""}, 2-trailingEmpty, maxCols)];
end

end

function tf = compareBlocks(blocksInit, blocksCheck)

tf = true;

% 1. same number of blocks
if numel(blocksInit) ~= numel(blocksCheck)
    tf = false;
    return;
end

% 2. compare each block
for i = 1:numel(blocksInit)

    A = string(blocksInit{i});
    B = string(blocksCheck{i});

    if ~isequal(size(A), size(B))
        tf = false;
        return;
    end

    if ~all(A == B, 'all')
        tf = false;
        return;
    end

end

end

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

function run_CG_parallel(source_path, init_format, run_names, result_path, constant_file)

% add source code path
addpath(genpath(source_path));

%% --- Parallel pool
delete(gcp('nocreate'))
nWorkers = length(run_names);   % 1 node per run
nWorkers = min(nWorkers, parcluster('local').NumWorkers);
parpool('local', nWorkers);

%% --- Running parallel jobs
parfor i = 1:numel(run_names)

    run_name = run_names{i};

    fprintf('--- Running %s on worker %d ---\n', run_name, getCurrentTask().ID);

    % PROVIDER local (important)
    provider = PROVIDER;
    provider = assign_paths(provider, init_format, run_name, result_path, constant_file);
    provider = read_const(provider);
    provider = read_parameters(provider);

    % Run CryoGrid
    [run_info, ~] = run_model(provider);
    [~, ~] = run_model(run_info);

    fprintf('--- End %s ---\n', run_name);
end

end

% -------------------------------------------------------------------------
%                             code run
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
%                             PART I
%                             CREATE AUTOMATIC LOOPS
% -------------------------------------------------------------------------



[~, folder_name] = fileparts(join_rel_path(result_path));

newParams = format_template(result_path,'NEW_PARAMS','.xlsx');
init = format_template(result_path,'TILE_LOOP_INIT','.xlsx');
next = format_template(result_path,'TILE_LOOP_NEXT','.xlsx');
restart = format_template(result_path,'RESTART','.xlsx');

TNew = cut_into_blocks(newParams);
TInit = cut_into_blocks(init);
TNext = cut_into_blocks(next);
TRestart = cut_into_blocks(restart);

ops = struct([]);
ops(1).param = "tile_class";
ops(1).value = repmat({"TILE_1D"}, 1, 2*numLoops-1);

ops(2).param = "tile_class_index";
ops(2).value = num2cell(1:2*numLoops-1);

ops(3).param = "number_of_runs_per_tile";
ops(3).value = num2cell(ones(1,2*numLoops-1));

[TInit, ~] = modify_blocks(TInit, TInit, false, ...
    "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ops);

ops = struct([]);
ops(1).param = "restart_file_path";
ops(1).value = result_path;

[TNext, ~] = modify_blocks(TNext, TNext, false, ...
    "TILE", "TILE_1D", 2, ops);


% Maximum width across all blocks
maxCols = max([ ...
    cellfun(@(x) size(x,2), TInit.blocks); ...
    cellfun(@(x) size(x,2), TNext.blocks); ...
    cellfun(@(x) size(x,2), TNew.blocks) ]);

padBlock = @(B) padBlockFcn(B, maxCols);

TInit.blocks = cellfun(padBlock, TInit.blocks, 'UniformOutput', false);
TNext.blocks = cellfun(padBlock, TNext.blocks, 'UniformOutput', false);
TNew.blocks  = cellfun(padBlock, TNew.blocks,  'UniformOutput', false);
TRestart.blocks = cellfun(padBlock, TRestart.blocks, 'UniformOutput', false);


for i = 1:size(TNew,1)
    rowA = TNew(i,1:3);
    [tfInit, idxInit] = ismember(rowA, TInit(:,1:3), 'rows');
    [tfNext, idxNext] = ismember(rowA, TNext(:,1:3), 'rows');
    [tfRestart, idxRestart] = ismember(rowA, TRestart(:,1:3), 'rows');
    if strcmp(rowA.cls, "STRAT_linear")
        if tfInit
            TInit.blocks{idxInit} = TNew.blocks{i};
        elseif tfNext
            TNext.blocks{idxNext} = TNew.blocks{i};
        elseif tfRestart
            TRestart.blocks{idxRestart} = TNew.blocks{i};
        end
    else
        for j = 1:size(TNew.blocks{i},1)
            row = TNew.blocks{i}(j,:);
            strt = string(row(1));
            if ~strcmp(strt,"")
                if tfInit
                    matchIdx = find(strcmp(string(TInit.blocks{idxInit}(:,1)), strt));
                    for m=1:numel(matchIdx)
                        TInit.blocks{idxInit}(matchIdx(m),1:numel(row)) = row;
                    end
                elseif tfNext
                    matchIdx = find(strcmp(string(TNext.blocks{idxNext}(:,1)), strt));
                    for m=1:numel(matchIdx)
                        TNext.blocks{idxNext}(matchIdx(m),1:numel(row)) = row;
                    end
                elseif tfRestart
                    matchIdx = find(strcmp(string(TRestart.blocks{idxRestart}(:,1)), strt));
                    for m=1:numel(matchIdx)
                        TRestart.blocks{idxRestart}(matchIdx(m),1:numel(row)) = row;
                    end
                end
            end
        end
    end
end

nInit = size(TInit,1);
nNext = size(TNext,1);
nAll  = nInit + (numLoops-1)*nNext;

TAll = TInit;

for n = 2:numLoops
    TNextTemp = TNext;

    % First TILE with restart_OUT_last_timestep
    ops = struct([]);

    ops(1).param = "TILE_1D";
    ops(1).value = 2*n-2;

    ops(2).param = "restart_file_name";
    ops(2).value = string(folder_name) + "_loop" + string(n-1) + "_last_timestep";

    [TNextTemp, idxBlock] = modify_blocks(TNext, TNextTemp, false, ...
        "TILE", "TILE_1D", 2, ops);
    TNextTemp.idx(idxBlock) = 2*n-2;

    % Second TILE with update_forcing_out
    ops = struct([]);

    ops(1).param = "TILE_1D";
    ops(1).value = 2*n-1;

    ops(2).param = "out_class_index";
    ops(2).value = {n};

    [TNextTemp, idxBlock] = modify_blocks(TNext, TNextTemp, false, ...
        "TILE", "TILE_1D", 3, ops);
    TNextTemp.idx(idxBlock) = 2*n-1;

    % Third TILE with OUT_last_timestep
    ops = struct([]);

    ops(1).param = "OUT_last_timestep";
    ops(1).value = n;

    ops(2).param = "tag";
    ops(2).value = "loop" + string(n);

    [TNextTemp, idxBlock] = modify_blocks(TNext, TNextTemp, false, ...
        "OUT", "OUT_last_timestep", 2, ops);
    TNextTemp.idx(idxBlock) = n;

    % Concatenate
    TAll = vertcat(TAll, TNextTemp);
end

supOrder = ["RUN_INFO"; "POINT"; "TILE"; "FORCING"; "OUT"; "GRID";
    "STRATIGRAPHY_CLASSES"; "STRATIGRAPHY_STATVAR"; "GROUND"; "SNOW";
    "LATERAL"; "LATERAL_IA"];
[~, TAll.supRank] = ismember(TAll.sup, supOrder); 
TAll.supRank(TAll.supRank == 0) = inf;
TAll = sortrows(TAll, {'supRank','idx'});

% Concatenate vertically
result = cat(1, TAll.blocks{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TCheck = cut_into_blocks(result);
tfa = all(all(TAll{:,1:3} == TCheck{:,1:3}));
tfb = compareBlocks(TAll.blocks(:), TCheck.blocks(:));

if ~tfa
    disp("Something went wrong with the ordering")
else
    disp("All good with the ordering")
end

if ~tfb
    disp("Something went wrong with the blocks")
else
    disp("All good with the blocks")
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if tfa && tfb
    % Write to Excel
    path_out = join_rel_path(result_path,folder_name,'.xlsx');
    if isfile(path_out)
        try
            delete(path_out);
        catch
            warning("Could not delete file: %s", path_out);
        end
    end
    disp('Writing file')
    writecell(result, path_out)
end

% -------------------------------------------------------------------------
%                             PART II
%                             RUN AUTOMATIC LOOPS
% -------------------------------------------------------------------------

run_CG(source_path, init_format, folder_name, ...
    extractBefore(result_path, folder_name), constant_file)


% -------------------------------------------------------------------------
%                             PART III
%                             CREATE INDIVIDUAL LOOP RUNS
% -------------------------------------------------------------------------

n = 9;
TRun = table(strings(n,1), strings(n,1), zeros(n,1), cell(n,1), ...
    'VariableNames', {'sup','cls','idx','blocks'} );


% Class 1
i = 1;
ops = struct([]);

ops(1).param = "tile_class";
ops(1).value = {"TILE_1D","TILE_1D"};

ops(2).param = "tile_class_index";
ops(2).value = {1,2};

ops(3).param = "number_of_runs_per_tile";
ops(3).value = {1,1};

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ops);
TRun.sup(i) = "RUN_INFO";
TRun.cls(i) = "RUN_1D_POINT_SPINUP";
TRun.idx(i) = 1;

% Class 2
i = 2;
ops = struct([]);

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "POINT", "POINT_SLOPE", 1, ops);
TRun.sup(i) = "POINT";
TRun.cls(i) = "POINT_SLOPE";
TRun.idx(i) = 1;

% Class 3
i = 3;
ops = struct([]);

ops(1).param = "TILE_1D";
ops(1).value = 1;

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "TILE", "TILE_1D", 2, ops);
TRun.sup(i) = "TILE";
TRun.cls(i) = "TILE_1D";
TRun.idx(i) = 1;
% !!!!!!!!! MAYBE HAVE ONE FOR RESTART FILE PATH IF PUT INTO UNIQUE FOLDER

% Class 4
i = 4;
ops = struct([]);

ops(1).param = "TILE_1D";
ops(1).value = 2;

ops(2).param = "out_class";
ops(2).value = {"OUT_regridded","OUT_all_lateral","OUT_snow_all"};

ops(3).param = "out_class_index";
ops(3).value = {1,1,1};

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "TILE", "TILE_1D", 3, ops);
TRun.sup(i) = "TILE";
TRun.cls(i) = "TILE_1D";
TRun.idx(i) = 2;

% Class 5
i = 5;
ops = struct([]);

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "FORCING", "FORCING_seb_mat", 1, ops);
TRun.sup(i) = "FORCING";
TRun.cls(i) = "FORCING_seb_mat";
TRun.idx(i) = 1;

rowIdx = identifying_line_to_change(TRun.blocks{i}, ...
    "FORCING_seb_mat", 1, "start_time");
time = TRun.blocks{i}(rowIdx,:);
s = string(time);
iStart = find(s == "H_LIST", 1);
iEnd   = find(s == "END", 1);
vals = time(iStart+1:iEnd-1);

dt = datetime(vals{1}, vals{2}, vals{3});
dt = dt + days(1);

vals = {year(dt), month(dt), day(dt)};

ops = struct([]);

ops(1).param = "end_time";
ops(1).value = vals;

[TRun, idxBlock] = modify_blocks(TAll, TRun, i, ...
    "FORCING", "FORCING_seb_mat", 1, ops);

% Class 6
i = 6;
ops = struct([]);

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "OUT", "OUT_do_nothing", 1, ops);
TRun.sup(i) = "OUT";
TRun.cls(i) = "OUT_do_nothing";
TRun.idx(i) = 1;

% Class 7
i = 7;
ops = struct([]);

[TRun, ~] = modify_blocks(TRestart, TRun, i, ...
    "OUT", "OUT_regridded", 1, ops);
TRun.sup(i) = "OUT";
TRun.cls(i) = "OUT_regridded";
TRun.idx(i) = 1;

% Class 8
i = 8;
ops = struct([]);

[TRun, ~] = modify_blocks(TRestart, TRun, i, ...
    "OUT", "OUT_all_lateral", 1, ops);
TRun.sup(i) = "OUT";
TRun.cls(i) = "OUT_all_lateral";
TRun.idx(i) = 1;

% Class 9
i = 9;
ops = struct([]);

[TRun, ~] = modify_blocks(TRestart, TRun, i, ...
    "OUT", "OUT_snow_all", 1, ops);
TRun.sup(i) = "OUT";
TRun.cls(i) = "OUT_snow_all";
TRun.idx(i) = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for n = 1:numLoops
    folder = result_path + "loop" + string(n);
    if ~exist(folder, 'dir')
        mkdir(folder);
    end

    file = string(folder_name) + "_loop" + string(n) + "_last_timestep";

    ops = struct([]);

    ops(1).param = "restart_file_path";
    ops(1).value = folder+"\";

    ops(2).param = "restart_file_name";
    ops(2).value = file;

    [TRun, ~] = modify_blocks(TRun, TRun, false, ...
        "TILE", "TILE_1D", 1, ops);

    % Concatenate vertically
    run = cat(1, TRun.blocks{:});

    % Write to Excel
    path_out = join_rel_path(folder,"loop" + string(n),'.xlsx');
    if isfile(path_out)
        try
            delete(path_out);
        catch
            warning("Could not delete file: %s", path_out);
        end
    end
    % disp('Writing file')
    writecell(run, path_out)

    copyfile(join_rel_path(result_path,constant_file,ext_dict(init_format)),folder)
    copyfile(join_rel_path(result_path,file,".mat"),folder)
end

% -------------------------------------------------------------------------
%                             PART IV
%                             RUN INDIVIDUAL LOOP RUNS
% -------------------------------------------------------------------------

run_names = arrayfun(@(k) sprintf('loop%d', k), ...
    1:numLoops, 'UniformOutput', false)';
run_CG_parallel(source_path, init_format, run_names, ...
    result_path, constant_file)

% clearvars;
