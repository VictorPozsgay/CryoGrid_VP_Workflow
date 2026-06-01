%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
ext_dict = dictionary('EXCEL3D','.xlsx');

numLoops = 10;

result_path = '..\CryoGridCommunity_results\templates\automatic_loops\';
source_path = '..\CryoGridCommunity_source\';
constant_file = 'CONSTANTS_excel'; %filename of file storing constants
% template_file = 'template_param_file'; %name of template parameter file
% (without file extension) to modify

result_path = join_rel_path(result_path);
source_path = join_rel_path(source_path);



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

% -------------------------------------------------------------------------
%                             code run
% -------------------------------------------------------------------------

[~, folder_name] = fileparts(join_rel_path(result_path));

newParams = format_template(result_path,'NEW_PARAMS','.xlsx');

init = format_template(result_path,'TILE_LOOP_INIT','.xlsx');
next = format_template(result_path,'TILE_LOOP_NEXT','.xlsx');

TNew = cut_into_blocks(newParams);
TInit = cut_into_blocks(init);
blocksInit = TInit.blocks(:)';
TNext = cut_into_blocks(next);

mask = (TInit.sup == "RUN_INFO") & ...
    (TInit.cls == "RUN_1D_POINT_SPINUP") & ...
    (TInit.idx == 1);
idxBlock = find(mask);

rowIdx = identifying_line_to_change(TInit.blocks{idxBlock}, ...
    "RUN_1D_POINT_SPINUP", 1, "tile_class");
TInit.blocks{idxBlock} = replace_val_hlist(TInit.blocks{idxBlock}, ...
    rowIdx, "tile_class", repmat({"TILE_1D"}, 1, 2*numLoops-1));

rowIdx = identifying_line_to_change(TInit.blocks{idxBlock}, ...
    "RUN_1D_POINT_SPINUP", 1, "tile_class_index");
TInit.blocks{idxBlock} = replace_val_hlist(TInit.blocks{idxBlock}, ...
    rowIdx, "tile_class_index", num2cell(1:2*numLoops-1));

rowIdx = identifying_line_to_change(TInit.blocks{idxBlock}, ...
    "RUN_1D_POINT_SPINUP", 1, "number_of_runs_per_tile");
TInit.blocks{idxBlock} = replace_val_hlist(TInit.blocks{idxBlock}, ...
    rowIdx, "number_of_runs_per_tile", num2cell(ones(1,2*numLoops-1)));

 
% Maximum width across all blocks
maxCols = max([ ...
    cellfun(@(x) size(x,2), TInit.blocks); ...
    cellfun(@(x) size(x,2), TNext.blocks); ...
    cellfun(@(x) size(x,2), TNew.blocks) ]);

padBlock = @(B) padBlockFcn(B, maxCols);

TInit.blocks = cellfun(padBlock, TInit.blocks, 'UniformOutput', false);
TNext.blocks = cellfun(padBlock, TNext.blocks, 'UniformOutput', false);
TNew.blocks  = cellfun(padBlock, TNew.blocks,  'UniformOutput', false);

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

% for i = 1:size(TNew,1)
for i = 1:size(TNew,1)
    rowA = TNew(i,1:3);
    [tfInit, idxInit] = ismember(rowA, TInit(:,1:3), 'rows');
    [tfNext, idxNext] = ismember(rowA, TNext(:,1:3), 'rows');
    if strcmp(rowA.cls, "STRAT_linear")
        if tfInit
            TInit.blocks{idxInit} = TNew.blocks{i};
        elseif tfNext
            TNext.blocks{idxNext} = TNew.blocks{i};
        end
    else
        for j = 1:size(TNew.blocks{i},1)
            row = TNew.blocks{i}(j,:);
            strt = string(row(1));
            if ~strcmp(strt,"")
                % disp(strt)
                if tfInit
                    matchIdx = find(strcmp(string(TInit.blocks{idxInit}(:,1)), strt));
                    % disp(matchIdx)
                    for m=1:numel(matchIdx)
                        TInit.blocks{idxInit}(matchIdx(m),1:numel(row)) = row;
                    end
                elseif tfNext
                    matchIdx = find(strcmp(string(TNext.blocks{idxNext}(:,1)), strt));
                    % disp(matchIdx)
                    for m=1:numel(matchIdx)
                        TNext.blocks{idxNext}(matchIdx(m),1:numel(row)) = row;
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
% blocksAll = blocksInit;

for n = 2:numLoops
    TNextTemp = TNext;

    % First TILE with restart_OUT_last_timestep

    mask = (TNextTemp.sup == "TILE") & ...
        (TNextTemp.cls == "TILE_1D") & ...
        (TNextTemp.idx == 2);

    TNextTemp.idx(mask) = 2*n-2;

    rowIdx = identifying_line_to_change(TNext.blocks{1}, "TILE_1D", ...
        2, "TILE_1D");
    TNextTemp.blocks{1} = replace_val_hlist(TNextTemp.blocks{1}, ...
        rowIdx, "TILE_1D", 2*n-2);

    rowIdx = identifying_line_to_change(TNext.blocks{1}, "TILE_1D", ...
        2, "restart_file_name");
    val = string(folder_name) + "_loop" + string(n-1) + "_last_timestep";
    TNextTemp.blocks{1} = replace_val_hlist(TNextTemp.blocks{1}, ...
        rowIdx, "restart_file_name", val);

    % Second TILE with update_forcing_out

    mask = (TNextTemp.sup == "TILE") & ...
        (TNextTemp.cls == "TILE_1D") & ...
        (TNextTemp.idx == 3);

    TNextTemp.idx(mask) = 2*n-1;

    rowIdx = identifying_line_to_change(TNext.blocks{2}, "TILE_1D", ...
        3, "TILE_1D");
    TNextTemp.blocks{2} = replace_val_hlist(TNextTemp.blocks{2}, ...
        rowIdx, "TILE_1D", 2*n-1);

    rowIdx = identifying_line_to_change(TNext.blocks{2}, "TILE_1D", ...
        3, "out_class_index");
    TNextTemp.blocks{2} = replace_val_hlist(TNextTemp.blocks{2}, ...
        rowIdx, "out_class_index", {n});

    % Third TILE with OUT_last_timestep

    mask = (TNextTemp.sup == "OUT") & ...
        (TNextTemp.cls == "OUT_last_timestep") & ...
        (TNextTemp.idx == 2);

    TNextTemp.idx(mask) = n;

    rowIdx = identifying_line_to_change(TNext.blocks{3}, ...
        "OUT_last_timestep", 2, "OUT_last_timestep");
    TNextTemp.blocks{3} = replace_val_hlist(TNextTemp.blocks{3}, ...
        rowIdx, "OUT_last_timestep", n);

    rowIdx = identifying_line_to_change(TNext.blocks{3}, ...
        "OUT_last_timestep", 2, "tag");
    TNextTemp.blocks{3} = replace_val_hlist(TNextTemp.blocks{3}, ...
        rowIdx, "tag", "loop" + string(n));

    % Concatenate

    TAll = vertcat(TAll, TNextTemp);
end

supOrder = ["RUN_INFO"; "POINT"; "TILE"; "FORCING"; "OUT"; "GRID";
    "STRATIGRAPHY_CLASSES"; "STRATIGRAPHY_STATVAR"; "GROUND"; "SNOW";
    "LATERAL"; "LATERAL_IA"];
[~, TAll.supRank] = ismember(TAll.sup, supOrder); 
TAll.supRank(TAll.supRank == 0) = inf;
TAll = sortrows(TAll, {'supRank','idx'});

% blocksAll(:) = TAll.blocks;

% Concatenate vertically
result = cat(1, TAll.blocks{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

TCheck = cut_into_blocks(result);
blocksCheck = TCheck.blocks(:);
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

    writecell(result, path_out)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% restart = format_template(result_path,'RESTART','.xlsx');
% TRestart = cut_into_blocks(restart);
% blocksRestart = TRestart.blocks(:);
% blocksRestart = cellfun(padBlock, blocksRestart, 'UniformOutput', false);
% 
% blocksRun = cell(1,9);
% 
% % Class 1
% mask = (TAll.sup == "RUN_INFO") & ...
%     (TAll.cls == "RUN_1D_POINT_SPINUP") & ...
%     (TAll.idx == 1);
% idxBlock = find(mask);
% 
% rowIdx = identifying_line_to_change(blocksAll{1,idxBlock}, ...
%     "RUN_1D_POINT_SPINUP", 1, "tile_class");
% blocksRun{1,1} = replace_val_hlist(blocksAll{1,idxBlock}, ...
%     rowIdx, "tile_class", {"TILE_1D","TILE_1D"});
% 
% rowIdx = identifying_line_to_change(blocksAll{1,idxBlock}, ...
%     "RUN_1D_POINT_SPINUP", 1, "tile_class_index");
% blocksRun{1,1} = replace_val_hlist(blocksRun{1,1}, ...
%     rowIdx, "tile_class_index", {1,2});
% 
% rowIdx = identifying_line_to_change(blocksAll{1,idxBlock}, ...
%     "RUN_1D_POINT_SPINUP", 1, "number_of_runs_per_tile");
% blocksRun{1,1} = replace_val_hlist(blocksRun{1,1}, ...
%     rowIdx, "number_of_runs_per_tile", {1,1});
% 
% % Class 2
% mask = (TAll.sup == "POINT") & ...
%     (TAll.cls == "POINT_SLOPE") & ...
%     (TAll.idx == 1);
% idxBlock = find(mask);
% 
% blocksRun{1,2} = blocksAll{1,idxBlock};
% 
% % Class 3
% mask = (TAll.sup == "TILE") & ...
%     (TAll.cls == "TILE_1D") & ...
%     (TAll.idx == 2);
% idxBlock = find(mask);
% 
% rowIdx = identifying_line_to_change(blocksAll{1,idxBlock}, ...
%     "TILE_1D", 2, "TILE_1D");
% blocksRun{1,3} = replace_val_hlist(blocksAll{1,idxBlock}, ...
%     rowIdx, "TILE_1D", 1);
% % !!!!!!!!! MAYBE HAVE ONE FOR RESTART FILE PATH IF PUT INTO UNIQUE FOLDER
% 
% % Class 4
% mask = (TAll.sup == "TILE") & ...
%     (TAll.cls == "TILE_1D") & ...
%     (TAll.idx == 3);
% idxBlock = find(mask);
% 
% rowIdx = identifying_line_to_change(blocksAll{1,idxBlock}, ...
%     "TILE_1D", 3, "TILE_1D");
% blocksRun{1,4} = replace_val_hlist(blocksAll{1,idxBlock}, ...
%     rowIdx, "TILE_1D", 2);
% 
% rowIdx = identifying_line_to_change(blocksAll{1,idxBlock}, ...
%     "TILE_1D", 3, "out_class");
% blocksRun{1,4} = replace_val_hlist(blocksRun{1,4}, rowIdx, ...
%     "out_class", {"OUT_regridded","OUT_all_lateral","OUT_snow_all"});
% 
% rowIdx = identifying_line_to_change(blocksAll{1,idxBlock}, ...
%     "TILE_1D", 3, "out_class_index");
% blocksRun{1,4} = replace_val_hlist(blocksRun{1,4}, rowIdx, ...
%     "out_class_index", {1,1,1});
% 
% % Class 5
% mask = (TAll.sup == "FORCING") & ...
%     (TAll.cls == "FORCING_seb_mat") & ...
%     (TAll.idx == 1);
% idxBlock = find(mask);
% 
% blocksRun{1,5} = blocksAll{1,idxBlock};
% 
% rowIdx = identifying_line_to_change(blocksAll{1,idxBlock}, ...
%     "FORCING_seb_mat", 1, "start_time");
% time = blocksRun{5}(rowIdx,:);
% s = string(time);
% iStart = find(s == "H_LIST", 1);
% iEnd   = find(s == "END", 1);
% vals = time(iStart+1:iEnd-1);
% rowIdx = identifying_line_to_change(blocksAll{1,idxBlock}, ...
%     "FORCING_seb_mat", 1, "end_time");
% blocksRun{1,5} = replace_val_hlist(blocksRun{1,5}, rowIdx, ...
%     "end_time", vals);
% 
% % Class 6
% mask = (TAll.sup == "OUT") & ...
%     (TAll.cls == "OUT_do_nothing") & ...
%     (TAll.idx == 1);
% idxBlock = find(mask);
% 
% blocksRun{1,6} = blocksAll{1,idxBlock};
% 
% 
% % Class 7
% mask = (TRestart.sup == "OUT") & ...
%     (TRestart.cls == "OUT_regridded") & ...
%     (TRestart.idx == 1);
% idxBlock = find(mask);
% 
% blocksRun{1,7} = blocksAll{1,idxBlock};
% 
% % Class 8
% mask = (TRestart.sup == "OUT") & ...
%     (TRestart.cls == "OUT_all_lateral") & ...
%     (TRestart.idx == 1);
% idxBlock = find(mask);
% 
% blocksRun{1,8} = blocksAll{1,idxBlock};
% 
% % Class 9
% mask = (TRestart.sup == "OUT") & ...
%     (TRestart.cls == "OUT_snow_all") & ...
%     (TRestart.idx == 1);
% idxBlock = find(mask);
% 
% blocksRun{1,9} = blocksAll{1,idxBlock};
% 
% 
% 
% % clearvars;
