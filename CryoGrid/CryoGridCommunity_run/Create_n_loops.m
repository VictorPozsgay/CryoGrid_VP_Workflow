%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
ext_dict = dictionary('EXCEL3D','.xlsx');

num_loops = 3;

result_path = '..\CryoGridCommunity_results\templates\automatic_loops\';
source_path = '..\CryoGridCommunity_source\';
constant_file = 'CONSTANTS_excel'; %filename of file storing constants
% template_file = 'template_param_file'; %name of template parameter file
% (without file extension) to modify

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
%   out : char
%       File or subdirectory name.
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
    out char
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

function S = identifying_lines_to_change(C,CB)
%IDENTIFYING_LINES_TO_CHANGE Locate varying parameters in template data.
%
%   S = IDENTIFYING_LINES_TO_CHANGE(C, CB)
%
%   Parses varying parameter definitions and identifies the corresponding
%   rows in the template spreadsheet where values must be modified.
%
%   Inputs
%   ------
%   C : cell array
%       Parameter variation definition table.
%
%   CB : cell array
%       Template spreadsheet cell array.
%
%   Output
%   ------
%   S : struct array
%       Structure array containing:
%
%       class
%           Parameter class/category.
%
%       index
%           Parameter index identifier.
%
%       var
%           Variable name.
%
%       idxRow
%           Row index in CB where the parameter is located.
%
%       vecValues
%           Vector of parameter values to vary.
%

N = size(C,1)-1;

S = struct( ...
    'class',     cell(N,1), ...
    'index',     cell(N,1), ...
    'var',       cell(N,1), ...
    'idxRow',    cell(N,1), ...
    'vecValues', cell(N,1));

for r = 2:size(C,1)

    class = C{r,1};
    index = C{r,2};
    var   = C{r,3};
    row   = C(r,:);

    S(r-1).class = class;
    S(r-1).index = index;
    S(r-1).var   = var;

    startIdx = find(strcmp(row, 'H_LIST'), 1, 'first');
    endIdx   = find(strcmp(row, 'END'), 1, 'first');

    vec = row(startIdx+1:endIdx-1);
    vec = cell2mat(vec);

    S(r-1).vecValues = vec;

    idxRow = (string(CB(:,1))==class) & ...
             (string(CB(:,2))==string(index));

    idxRow = find(idxRow);

    foundRow = [];

    for rr = idxRow:size(CB,1)

        firstCell = CB{rr,1};

        if ~ischar(firstCell) && ~isstring(firstCell)
            continue
        end

        firstCell = char(firstCell);

        if startsWith(firstCell, '---')
            break
        end

        if strcmp(firstCell, var)
            foundRow = rr;
            break
        end
    end

    S(r-1).idxRow = foundRow;

end

end

% -------------------------------------------------------------------------
%                             code run
% -------------------------------------------------------------------------

sheets = cell(num_loops,1);
sheets{1} = format_template(result_path,'TILE_LOOP_INIT','.xlsx');
for n=2:num_loops
    sheets{n} = format_template(result_path,'TILE_LOOP_NEXT','.xlsx');
end

if 2*num_loops+2>size(sheets{1},2)
    sheets{1} = [sheets{1}, repmat({""}, size(sheets{1},1), ...
        2*num_loops+2-size(sheets{1},2))];
end

% Find max number of columns
maxCols = max(cellfun(@(x) size(x,2), sheets));

% Pad each sheet to same width (cellfun)
sheets = cellfun(@(x) ...
    [x, repmat({""}, size(x,1), maxCols - size(x,2))], ...
    sheets, 'UniformOutput', false);

% find row where first column is "tile_class"
col1 = strtrim(string(sheets{1}(:,1)));
rowIdx = find(col1 == "tile_class");

vec_tile1 = {"tile_class", "H_LIST", "TILE_1D"};
vec_tile2 = {"tile_class_index", "H_LIST", 1};
vec_tile3 = {"number_of_runs_per_tile", "H_LIST", 1};
for n=1:num_loops-1
    vec_tile1 = [vec_tile1, {"TILE_1D", "TILE_1D"}];
    vec_tile2 = [vec_tile2, {2*n, 2*n+1}];
    vec_tile3 = [vec_tile3, {1, 1}];
end
vec_tile1 = [vec_tile1, {"END"}];
vec_tile2 = [vec_tile2, {"END"}];
vec_tile3 = [vec_tile3, {"END"}];

% modify column 3 in that row
sheets{1}(rowIdx, 1:(numel(vec_tile1))) = vec_tile1;
sheets{1}(rowIdx+1, 1:(numel(vec_tile2))) = vec_tile2;
sheets{1}(rowIdx+2, 1:(numel(vec_tile3))) = vec_tile3;










% Find max number of columns
maxCols = max(cellfun(@(x) size(x,2), sheets));

% Pad each sheet to same width (cellfun)
sheets = cellfun(@(x) ...
    [x, repmat({""}, size(x,1), maxCols - size(x,2))], ...
    sheets, 'UniformOutput', false);

% append 2 empty rows
for n=1:num_loops
    sheets{n} = [sheets{n}; repmat({""}, 2, maxCols)];
end

% Concatenate vertically
result = cat(1, sheets{:});

% Write to Excel
writecell(result, join_rel_path(result_path,'automatic_loops','.xlsx'));

% clearvars;
