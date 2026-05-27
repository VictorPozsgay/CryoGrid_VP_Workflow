%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

init_format = 'EXCEL3D'; % choose the option corresponding to the parameter file format
ext_dict = dictionary('EXCEL3D','.xlsx');

result_path = '..\CryoGridCommunity_results\test_multivar\';
source_path = '..\CryoGridCommunity_source\';
constant_file = 'CONSTANTS_excel'; %filename of file storing constants
template_file = 'template_param_file'; %name of template parameter file
% (without file extension) to modify
vary_par_file = 'varying_params'; %filename of parameters to vary

name_output = 'outpout'; %will create n name_output_i (i=1:n) directories 

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

function C = get_varying_params( ...
    init_format, ext_dict, result_path, vary_par_file)
%GET_VARYING_PARAMS Read and preprocess varying parameter definitions.
%
%   C = GET_VARYING_PARAMS(INIT_FORMAT, EXT_DICT, RESULT_PATH, ...
%                          VARY_PAR_FILE)
%
%   Reads a parameter variation file and fills missing values in the
%   first two columns using the previous non-missing entry.
%
%   Inputs
%   ------
%   init_format : string or char
%       Key used to retrieve the file extension from EXT_DICT.
%
%   ext_dict : containers.Map
%       Dictionary mapping initialization formats to file extensions.
%
%   result_path : string or char
%       Base directory containing the varying parameter file.
%
%   vary_par_file : string or char
%       Name of the varying parameter file (without extension).
%
%   Output
%   ------
%   C : cell array
%       Processed cell array read from the spreadsheet file.
%       Column 1 missing values are forward-filled as strings.
%       Column 2 missing values are forward-filled as numeric values.
%
%   Example
%   -------
%   C = get_varying_params('EXCEL3D',ext_dict,result_path,vary_par_file);
% 

ext  = ext_dict(init_format);
path = join_rel_path(result_path, vary_par_file, ext);

C = readcell(path);

% Fill down column 1 (strings)
C(2:end,1) = num2cell( ...
    fillmissing(string(C(2:end,1)), 'previous'));

% Fill down column 2 (numeric)
C(2:end,2) = num2cell( ...
    fillmissing(cell2mat(C(2:end,2)), 'previous'));

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

function [SOuter,T] = distribute_varying_params(S)
%DISTRIBUTE_VARYING_PARAMS Generate all parameter combinations.
%
%   SOUTER = DISTRIBUTE_VARYING_PARAMS(S)
%
%   Generates all possible combinations of varying parameter values using
%   a Cartesian product over the vecValues fields.
%
%   Inputs
%   ------
%   S : struct array
%       Structure array describing varying parameters.
%
%   Outputs
%   -------
%   SOuter : struct array
%       Structure array containing all parameter combinations.
%       Each entry contains a DATA field storing one complete parameter set.
%
%   T : table
%       Table containing all parameter combinations.
%       Each column corresponds to one varying parameter and each row
%       corresponds to one simulation configuration.
%

nTot = prod(arrayfun(@(x) numel(x.vecValues), S));

SOuter = struct( ...
    'data', cell(nTot,1));

V = {S.vecValues};
n = numel(V);

G = cell(1,n);
[G{:}] = ndgrid(V{:});

numComb = numel(G{1});
Cz = zeros(numComb, n);

for i = 1:n
    Cz(:,i) = G{i}(:);
end

T = array2table(Cz);

varNames = matlab.lang.makeUniqueStrings(string({S.var}));
T.Properties.VariableNames = varNames;

for i = 1:size(Cz,1)

    SOuter(i).data = S;

    for j = 1:size(Cz,2)

        SOuter(i).data(j).varName  = varNames(j);
        SOuter(i).data(j).vecValues = Cz(i,j);
        SOuter(i).data(j).value     = ...
            SOuter(i).data(j).vecValues;

    end

    SOuter(i).data = rmfield(SOuter(i).data, 'vecValues');

end

end

function T = create_sim_folders( ...
    SOuter,CB,T,result_path,name_output,constant_path_in,ext)
%CREATE_SIM_FOLDERS Generate simulation folders and parameter files.
%
%   T = CREATE_SIM_FOLDERS( ...
%       SOUTER,CB,T,RESULT_PATH,NAME_OUTPUT,CONSTANT_PATH_IN,EXT)
%
%   Creates one simulation directory per parameter combination, updates
%   the template spreadsheet with the corresponding parameter values,
%   writes the resulting spreadsheet, and copies constant input files.
%
%   Additionally appends the generated directory names to the metadata
%   table and writes the metadata table to disk.
%
%   Inputs
%   ------
%   SOuter : struct array
%       Structure array containing all parameter combinations.
%
%   CB : cell array
%       Template spreadsheet cell array.
%
%   T : table
%       Metadata table describing all parameter combinations.
%
%   result_path : string or char
%       Base output directory.
%
%   name_output : string or char
%       Base simulation folder name.
%
%   constant_path_in : string or char
%       Path to constant input file or directory to copy.
%
%   ext : string or char
%       Spreadsheet file extension.
%
%   Output
%   ------
%   T : table
%       Updated metadata table containing the generated simulation
%       directory names.
%

newTabCol = strings(height(T), 1);

for i = 1:size(SOuter,1)

    dir_output = append(name_output,"_",string(i));
    newTabCol(i,1) = dir_output;

    outDir = join_rel_path(result_path,dir_output);

    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    COut = CB;
    class = SOuter(i).data;

    for j = 1:size(class,1)

        COut{class(j).idxRow,2} = class(j).value;
        path = join_rel_path(outDir,dir_output,ext);

    end

    writecell(COut, path);
    copyfile(constant_path_in,outDir);

end

T.("directory") = newTabCol;
T = T(:,[end 1:end-1]);
writetable(T,join_rel_path(result_path,'metadata.xlsx'))

end

function vary_param_wrapper(init_format,ext_dict,result_path, ...
    vary_par_file,constant_file,template_file,name_output)
%VARY_PARAM_WRAPPER Main workflow for generating varying parameter simulations.
%
%   VARY_PARAM_WRAPPER( ...
%       INIT_FORMAT,EXT_DICT,RESULT_PATH,VARY_PAR_FILE, ...
%       CONSTANT_FILE,TEMPLATE_FILE,NAME_OUTPUT)
%
%   Executes the complete workflow for generating simulation folders from
%   a parameter variation definition file.
%
%   The workflow:
%       1. Reads varying parameter definitions.
%       2. Reads and sanitizes the template spreadsheet.
%       3. Identifies parameter rows to modify.
%       4. Generates all parameter combinations.
%       5. Creates one simulation folder per combination.
%       6. Writes metadata describing all generated simulations.
%
%   Inputs
%   ------
%   init_format : string or char
%       Initialization format key used to retrieve file extensions.
%
%   ext_dict : containers.Map
%       Dictionary mapping initialization formats to file extensions.
%
%   result_path : string or char
%       Base working/output directory.
%
%   vary_par_file : string or char
%       Name of the varying parameter definition file.
%
%   constant_file : string or char
%       Name of the constant input file or directory to copy into each
%       simulation folder.
%
%   template_file : string or char
%       Name of the template spreadsheet file.
%
%   name_output : string or char
%       Base name used for generated simulation directories.
%

ext = ext_dict(init_format);
constant_path_in = ...
    join_rel_path(result_path,constant_file,ext);
C = get_varying_params( ...
    init_format,ext_dict,result_path,vary_par_file);
CB = format_template(result_path,template_file,ext);
S = identifying_lines_to_change(C,CB);
[SOuter,T] = distribute_varying_params(S);
create_sim_folders( ...
    SOuter,CB,T,result_path,name_output,constant_path_in,ext);

end

% -------------------------------------------------------------------------
%                             code run
% -------------------------------------------------------------------------

vary_param_wrapper(init_format,ext_dict,result_path, ...
    vary_par_file,constant_file,template_file,name_output)

clearvars;
