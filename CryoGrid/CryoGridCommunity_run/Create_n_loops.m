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

function sheet = replace_val_hlist(sheet, rowIdx, param, valLoopInit, options)

arguments
    sheet
    rowIdx
    param
    valLoopInit

    options.numLoops = 1
    options.valLoopNext = ""
    options.hlist = false
end

numLoops = options.numLoops;
valLoopNext = options.valLoopNext;
hlist = options.hlist;

if (numLoops == 1) && ~hlist
    vecTile = {param, valLoopInit};
else
    vecTile = {param, "H_LIST", valLoopInit};
end

for n=1:numLoops-1
    if strcmp(valLoopNext, 'increasing')
        vecTile = [vecTile, {valLoopInit+2*n-1, valLoopInit+2*n}];
    elseif strcmp(valLoopNext, 'equal')
        vecTile = [vecTile, {valLoopInit, valLoopInit}];
    else
        vecTile = [vecTile, valLoopNext];
    end
end

if (numLoops > 1) || hlist
    vecTile = [vecTile, {"END"}];
end

% CAREFUL: make sure the table is wide enough!!!
sheet(:, end+1:numel(vecTile)) = repmat({""}, size(sheet,1), ...
    numel(vecTile)-size(sheet,2));
sheet(rowIdx, 1:(numel(vecTile))) = vecTile;

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

% for i = 1:size(TNew,1)
for i = 1:size(TNew,1)
    rowA = TNew(i,:);
    [tfInit, idxInit] = ismember(rowA, TInit, 'rows');
    [tfNext, idxNext] = ismember(rowA, TNext, 'rows');
    disp([i idxInit idxNext])
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
                disp(strt)
                if tfInit
                    matchIdx = find(strcmp(string(blocksInit{idxInit}(:,1)), strt));
                    disp(matchIdx)
                    for m=1:numel(matchIdx)
                        blocksInit{idxInit}(matchIdx(m),1:numel(row)) = row;
                    end
                elseif tfNext
                    matchIdx = find(strcmp(string(blocksNext{idxNext}(:,1)), strt));
                    disp(matchIdx)
                    for m=1:numel(matchIdx)
                        blocksNext{idxNext}(matchIdx(m),1:numel(row)) = row;
                    end
                end
            end
        end
    end
end





% sheets = cell(numLoops,1);
% sheets{1} = format_template(result_path,'TILE_LOOP_INIT','.xlsx');
% for n=2:numLoops
%     sheets{n} = format_template(result_path,'TILE_LOOP_NEXT','.xlsx');
% end
% 
% if 2*numLoops+2>size(sheets{1},2)
%     sheets{1} = [sheets{1}, repmat({""}, size(sheets{1},1), ...
%         2*numLoops+2-size(sheets{1},2))];
% end
% 
% % Find max number of columns
% maxCols = max(cellfun(@(x) size(x,2), sheets));
% 
% % Pad each sheet to same width (cellfun)
% sheets = cellfun(@(x) ...
%     [x, repmat({""}, size(x,1), maxCols - size(x,2))], ...
%     sheets, 'UniformOutput', false);
% 
% % find row where first column is "tile_class"
% % col1 = strtrim(string(sheets{1}(:,1)));
% % rowIdx = find(col1 == "tile_class");
% rowIdx = identifying_line_to_change(sheets{1}, "RUN_1D_POINT_SPINUP", ...
%     1, "tile_class");
% sheets{1} = replace_val_hlist(sheets{1}, rowIdx, "tile_class", ...
%     "TILE_1D", numLoops=numLoops, valLoopNext={"TILE_1D", "TILE_1D"});
% 
% rowIdx = identifying_line_to_change(sheets{1}, "RUN_1D_POINT_SPINUP", ...
%     1, "tile_class_index");
% sheets{1} = replace_val_hlist(sheets{1}, rowIdx, "tile_class_index", ...
%     1, numLoops=numLoops, valLoopNext="increasing");
% 
% rowIdx = identifying_line_to_change(sheets{1}, "RUN_1D_POINT_SPINUP", ...
%     1, "number_of_runs_per_tile");
% sheets{1} = replace_val_hlist(sheets{1}, rowIdx, ...
%     "number_of_runs_per_tile", 1, numLoops=numLoops, valLoopNext="equal");
% 
% 
% for n=2:numLoops
%     rowIdx = identifying_line_to_change(sheets{n}, "TILE_1D", ...
%         2, "TILE_1D");
%     sheets{n} = replace_val_hlist(sheets{n}, rowIdx, ...
%         "TILE_1D", 2*n-2);
% 
%     rowIdx = identifying_line_to_change(sheets{n}, "TILE_1D", ...
%         3, "TILE_1D");
%     sheets{n} = replace_val_hlist(sheets{n}, rowIdx, ...
%         "TILE_1D", 2*n-1);
% 
%     rowIdx = identifying_line_to_change(sheets{n}, "TILE_1D", ...
%         2*n-2, "restart_file_name");
%     val = string(folder_name) + "_loop" + string(n-1) + "_last_timestep";
%     sheets{n} = replace_val_hlist(sheets{n}, rowIdx, ...
%         "restart_file_name", val);
% 
%     rowIdx = identifying_line_to_change(sheets{n}, "TILE_1D", ...
%         2*n-1, "out_class_index");
%     sheets{n} = replace_val_hlist(sheets{n}, rowIdx, ...
%         "out_class_index", n, hlist=true);
% 
%     rowIdx = identifying_line_to_change(sheets{n}, "OUT_last_timestep", ...
%         2, "OUT_last_timestep");
%     sheets{n} = replace_val_hlist(sheets{n}, rowIdx, ...
%         "OUT_last_timestep", n);
% 
%     rowIdx = identifying_line_to_change(sheets{n}, "OUT_last_timestep", ...
%         n, "tag");
%     sheets{n} = replace_val_hlist(sheets{n}, rowIdx, ...
%         "tag", "loop" + string(n));
% end
% 
% 
% % Find max number of columns
% maxCols = max(cellfun(@(x) size(x,2), sheets));
% 
% % Pad each sheet to same width (cellfun)
% sheets = cellfun(@(x) ...
%     [x, repmat({""}, size(x,1), maxCols - size(x,2))], ...
%     sheets, 'UniformOutput', false);
% 
% % append 2 empty rows
% for n=1:numLoops
%     sheets{n} = [sheets{n}; repmat({""}, 2, maxCols)];
% end
% 
% % Concatenate vertically
% result = cat(1, sheets{:});
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% [blocks, T] = cut_into_blocks(result);
% 
% % sepIdx = find(startsWith(strtrim(string(result(:,1))), "-"));
% % sepIdx = [sepIdx; size(result,1)+1];
% % 
% % nBlocks = numel(sepIdx)-1;
% % blocks = cell(1,nBlocks);
% % 
% % for i = 1:nBlocks
% %     blocks{i} = result(sepIdx(i):sepIdx(i+1)-1, :);    
% %     if ~startsWith(strtrim(string(blocks{i}(1,1))), "-")
% %         disp('Issue with block, not starting with "-"')
% %     end    
% % end
% % 
% % sup = strings(nBlocks,1);
% % cls = strings(nBlocks,1);
% % idx = zeros(nBlocks,1);
% % 
% % for i = 1:nBlocks
% %     sup(i) = string(blocks{i}{2,1});
% %     cls(i) = string(blocks{i}{3,1});
% %     idx(i) = blocks{i}{3,2};
% % end
% % 
% % T = table(sup, cls, idx);
% supOrder = ["RUN_INFO"; "POINT"; "TILE"; "FORCING"; "OUT"; "GRID";
%     "STRATIGRAPHY_CLASSES"; "STRATIGRAPHY_STATVAR"; "GROUND"; "SNOW";
%     "LATERAL"; "LATERAL_IA"];
% [~, T.supRank] = ismember(T.sup, supOrder); 
% T.supRank(T.supRank == 0) = inf;
% T.blocks = blocks(:);
% T = sortrows(T, {'supRank','idx'});
% 
% blocks(:) = T.blocks;
% 
% % Concatenate vertically
% result = cat(1, blocks{:});
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % Write to Excel
% path_out = join_rel_path(result_path,folder_name,'.xlsx');
% if isfile(path_out)
%     try
%         delete(path_out);
%     catch
%         warning("Could not delete file: %s", path_out);
%     end
% end
% 
% writecell(result, path_out)
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % Pad each sheet to same width (cellfun)
% newParams = [newParams, repmat({""}, size(newParams,1), ...
%     maxCols - size(newParams,2))];
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% [blocksNew, TNew] = cut_into_blocks(newParams);
% 
% % sepIdx = find(startsWith(strtrim(string(newParams(:,1))), "-"));
% % sepIdx = [sepIdx; size(newParams,1)+1];
% % 
% % nBlocks = numel(sepIdx)-1;
% % blocksNew = cell(1,nBlocks);
% % 
% % for i = 1:nBlocks
% %     blocksNew{i} = newParams(sepIdx(i):sepIdx(i+1)-1, :);    
% %     if ~startsWith(strtrim(string(blocksNew{i}(1,1))), "-")
% %         disp('Issue with block, not starting with "-"')
% %     end    
% % end
% % 
% % sup = strings(nBlocks,1);
% % cls = strings(nBlocks,1);
% % idx = zeros(nBlocks,1);
% % 
% % for i = 1:nBlocks
% %     sup(i) = string(blocksNew{i}{2,1});
% %     cls(i) = string(blocksNew{i}{3,1});
% %     idx(i) = blocksNew{i}{3,2};
% % end
% % 
% % TNew = table(sup, cls, idx);
% 
% % clearvars;
