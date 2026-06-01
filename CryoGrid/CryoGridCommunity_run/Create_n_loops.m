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

% function sheet = replace_val_hlist(sheet, rowIdx, param, valLoopInit, options)
% 
% arguments
%     sheet
%     rowIdx
%     param
%     valLoopInit
% 
%     options.numLoops = 1
%     options.valLoopNext = ""
%     options.hlist = false
% end
% 
% numLoops = options.numLoops;
% valLoopNext = options.valLoopNext;
% hlist = options.hlist;
% 
% if (numLoops == 1) && ~hlist
%     vecTile = {param, valLoopInit};
% else
%     vecTile = {param, "H_LIST", valLoopInit};
% end
% 
% for n=1:numLoops-1
%     if strcmp(valLoopNext, 'increasing')
%         vecTile = [vecTile, {valLoopInit+2*n-1, valLoopInit+2*n}];
%     elseif strcmp(valLoopNext, 'equal')
%         vecTile = [vecTile, {valLoopInit, valLoopInit}];
%     else
%         vecTile = [vecTile, valLoopNext];
%     end
% end
% 
% if (numLoops > 1) || hlist
%     vecTile = [vecTile, {"END"}];
% end
% 
% % CAREFUL: make sure the table is wide enough!!!
% sheet(:, end+1:numel(vecTile)) = repmat({""}, size(sheet,1), ...
%     numel(vecTile)-size(sheet,2));
% sheet(rowIdx, 1:(numel(vecTile))) = vecTile;
% 
% end

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
sheet(rowIdx, 1:(numel(vec))) = vec;

end

function [blocks, T] = cut_into_blocks(data)

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

end

% -------------------------------------------------------------------------
%                             code run
% -------------------------------------------------------------------------

[~, folder_name] = fileparts(join_rel_path(result_path));

newParams = format_template(result_path,'NEW_PARAMS','.xlsx');

init = format_template(result_path,'TILE_LOOP_INIT','.xlsx');
next = format_template(result_path,'TILE_LOOP_NEXT','.xlsx');

[blocksNew, TNew] = cut_into_blocks(newParams);
[blocksInit, TInit] = cut_into_blocks(init);
[blocksNext, TNext] = cut_into_blocks(next);

% Maximum width across all blocks
maxCols = max([ ...
    cellfun(@(x) size(x,2), blocksInit), ...
    cellfun(@(x) size(x,2), blocksNext), ...
    cellfun(@(x) size(x,2), blocksNew) ]);

padBlock = @(B) padBlockFcn(B, maxCols);

blocksInit = cellfun(padBlock, blocksInit, 'UniformOutput', false);
blocksNext = cellfun(padBlock, blocksNext, 'UniformOutput', false);
blocksNew  = cellfun(padBlock, blocksNew,  'UniformOutput', false);

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
    rowA = TNew(i,:);
    [tfInit, idxInit] = ismember(rowA, TInit, 'rows');
    [tfNext, idxNext] = ismember(rowA, TNext, 'rows');
    if strcmp(rowA.cls, "STRAT_linear")
        if tfInit
            blocksInit{idxInit} = blocksNew{i};
        elseif tfNext
            blocksNext{idxNext} = blocksNew{i};
        end
    else
        for j = 1:size(blocksNew{i},1)
            row = blocksNew{i}(j,:);
            strt = string(row(1));
            if ~strcmp(strt,"")
                % disp(strt)
                if tfInit
                    matchIdx = find(strcmp(string(blocksInit{idxInit}(:,1)), strt));
                    % disp(matchIdx)
                    for m=1:numel(matchIdx)
                        blocksInit{idxInit}(matchIdx(m),1:numel(row)) = row;
                    end
                elseif tfNext
                    matchIdx = find(strcmp(string(blocksNext{idxNext}(:,1)), strt));
                    % disp(matchIdx)
                    for m=1:numel(matchIdx)
                        blocksNext{idxNext}(matchIdx(m),1:numel(row)) = row;
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
blocksAll = blocksInit;

for n = 2:numLoops
    TNextTemp = TNext;
    blocksNextTemp = blocksNext;

    % First TILE with restart_OUT_last_timestep

    mask = (TNextTemp.sup == "TILE") & ...
        (TNextTemp.cls == "TILE_1D") & ...
        (TNextTemp.idx == 2);

    TNextTemp.idx(mask) = 2*n-2;

    rowIdx = identifying_line_to_change(blocksNext{1,1}, "TILE_1D", ...
        2, "TILE_1D");
    blocksNextTemp{1,1} = replace_val_hlist(blocksNextTemp{1,1}, ...
        rowIdx, "TILE_1D", 2*n-2);

    rowIdx = identifying_line_to_change(blocksNext{1,1}, "TILE_1D", ...
        2, "restart_file_name");
    val = string(folder_name) + "_loop" + string(n-1) + "_last_timestep";
    blocksNextTemp{1,1} = replace_val_hlist(blocksNextTemp{1,1}, ...
        rowIdx, "restart_file_name", val);

    % Second TILE with update_forcing_out

    mask = (TNextTemp.sup == "TILE") & ...
        (TNextTemp.cls == "TILE_1D") & ...
        (TNextTemp.idx == 3);

    TNextTemp.idx(mask) = 2*n-1;

    rowIdx = identifying_line_to_change(blocksNext{1,2}, "TILE_1D", ...
        3, "TILE_1D");
    blocksNextTemp{1,2} = replace_val_hlist(blocksNextTemp{1,2}, ...
        rowIdx, "TILE_1D", 2*n-1);

    rowIdx = identifying_line_to_change(blocksNext{1,2}, "TILE_1D", ...
        3, "out_class_index");
    blocksNextTemp{1,2} = replace_val_hlist(blocksNextTemp{1,2}, ...
        rowIdx, "out_class_index", {n});

    % Third TILE with OUT_last_timestep

    mask = (TNextTemp.sup == "OUT") & ...
        (TNextTemp.cls == "OUT_last_timestep") & ...
        (TNextTemp.idx == 2);

    TNextTemp.idx(mask) = n;

    rowIdx = identifying_line_to_change(blocksNext{1,3}, ...
        "OUT_last_timestep", 2, "OUT_last_timestep");
    blocksNextTemp{1,3} = replace_val_hlist(blocksNextTemp{1,3}, ...
        rowIdx, "OUT_last_timestep", n);

    rowIdx = identifying_line_to_change(blocksNext{1,3}, ...
        "OUT_last_timestep", 2, "tag");
    blocksNextTemp{1,3} = replace_val_hlist(blocksNextTemp{1,3}, ...
        rowIdx, "tag", "loop" + string(n));

    % Concatenate

    TAll = vertcat(TAll, TNextTemp);
    blocksAll = horzcat(blocksAll, blocksNextTemp);
end

supOrder = ["RUN_INFO"; "POINT"; "TILE"; "FORCING"; "OUT"; "GRID";
    "STRATIGRAPHY_CLASSES"; "STRATIGRAPHY_STATVAR"; "GROUND"; "SNOW";
    "LATERAL"; "LATERAL_IA"];
[~, TAll.supRank] = ismember(TAll.sup, supOrder); 
TAll.supRank(TAll.supRank == 0) = inf;
TAll.blocks = blocksAll(:);
TAll = sortrows(TAll, {'supRank','idx'});

blocksAll(:) = TAll.blocks;

% Concatenate vertically
result = cat(1, blocksAll{:});

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

[blocksCheck, TCheck] = cut_into_blocks(result);
tfa = all(all(TAll{:,1:3} == TCheck{:,:}));
tfb = compareBlocks(blocksAll, blocksCheck);

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

% clearvars;
