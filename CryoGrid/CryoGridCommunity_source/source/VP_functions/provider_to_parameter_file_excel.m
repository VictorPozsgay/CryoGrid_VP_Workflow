function provider_to_parameter_file_excel(provider, result_path, run_name)
%PROVIDER_TO_PARAMETER_FILE_EXCEL Exports a CryoGrid PROVIDER object to an Excel parameter file.
%
% This function converts a fully constructed CryoGrid PROVIDER object into an
% Excel-based parameter file that can be re-read by the PROVIDER class system.
% The exported file preserves the hierarchical structure of classes, parameters,
% and complex PARA structures (including vectors and nested struct fields).
%
% The resulting spreadsheet follows CryoGrid's parameter file format, including:
%   • CLASS blocks with metadata headers
%   • H_LIST entries for horizontal parameter lists
%   • V_MATRIX entries for structured parameter fields
%   • STRAT_MATRIX entries for stratigraphy-style depth-dependent parameters
%   • Explicit END markers for each block type
%   • CLASS_END separators between classes
%
%
% INPUTS
% ------
%   provider : struct (PROVIDER object)
%       Fully initialized CryoGrid PROVIDER object containing CLASSES and PARA fields.
%
%   result_path : string or char
%       Path to the directory where the Excel file will be written.
%
%   run_name : string or char
%       Name of the simulation run. Used to define output file name.
%
%
% OUTPUT
% ------
%   (none)
%       The function writes an Excel file:
%           [result_path run_name '/' run_name '.xlsx']
%
%
% FORMAT OVERVIEW
% ---------------
% The exported Excel file contains:
%
%   1. CLASS header blocks
%   2. Parameter entries:
%        - Scalar values → direct entries
%        - Vectors/lists → H_LIST
%        - Structs:
%              • STRAT_MATRIX (if containing "depth")
%              • V_MATRIX (otherwise)
%   3. END markers for structured blocks
%   4. CLASS_END separator between classes
% 
%
% SEE ALSO
% --------
% PROVIDER, xlswrite, param_file_info, orderfields

classes = fieldnames(provider.CLASSES);

spreadsheet = {};
j=1;
for i = 1:size(classes,1)
    class_name = classes{i,1};
    class = str2func(class_name);
    class = class();

    try
        class_category = param_file_info(class).PARA.class_category;
    catch
        [~, class_category] = fileparts(fileparts(which(class_name)));
    end

    for ii = 1:size(provider.CLASSES.(class_name),1)

        %------------write the spreadsheet----
        spreadsheet(j,1)= {'-------------------'};
        j=j+1;
        spreadsheet(j,1) = {class_category};
        spreadsheet(j,2) = {'index'};
        j=j+1;
        spreadsheet(j,1) = {class_name};
        spreadsheet(j,2) = {ii};
        j=j+1;

        S = provider.CLASSES.(class_name){ii,1}.PARA;

        fns = fieldnames(S);
        fns = fns(cellfun(@(f) ...
            ~strcmp(f,'class_index') && ...
            ~isempty(S.(f)) && ...
            ~(isnumeric(S.(f)) && isscalar(S.(f)) && isnan(S.(f))), ...
            fns));

        for l = 1:size(fns,1)
            f = fns{l,1};
            val = S.(f);
            
            % if it is a structure
            if isstruct(val)
                fns2 = fieldnames(val);
                % write STRAT_MATRIX
                if any(strcmp(fns2, 'depth'))
                    % make sure 'depth' is first, else reorder
                    if ~strcmp(fns2{1}, 'depth')
                        val = orderfields(val, [{'depth'}; setdiff(fns2,'depth','stable')]);
                    end
                    
                    spreadsheet(j,1) = {f};
                    spreadsheet(j,2) = {'STRAT_MATRIX'};
                    spreadsheet(j,3:3-1+numel(fns2(2:end))) = fns2(2:end);
                    spreadsheet(j,3+numel(fns2(2:end))) = {'END'};
                    j=j+1;

                    cols = cell(size(fns2));
                    for k = 1:numel(fns2)
                        x = val.(fns2{k})(:);
                        if isnumeric(x)
                            x = num2cell(x);
                        end
                        cols{k} = x;
                    end
                    mat = [cols{:}];
                    spreadsheet(j:j-1+size(mat,1),2:2-1+size(mat,2)) = mat;
                    j=j+size(mat,1);
                    spreadsheet(j,2) = {'END'};
                    j=j+1;
                % write V_MATRIX
                else
                    spreadsheet(j,1) = {f};
                    spreadsheet(j,2) = {'V_MATRIX'};
                    spreadsheet(j,3:3-1+numel(fns2)) = fns2;
                    spreadsheet(j,3+numel(fns2)) = {'END'};
                    j=j+1;

                    cols = cellfun(@(fn) val.(fn)(:), fieldnames(val), 'UniformOutput', false);
                    mat = [cols{:}];
                    spreadsheet(j:j-1+size(mat,1),3:3-1+size(mat,2)) = num2cell(mat);
                    j=j+size(mat,1);
                    spreadsheet(j,2) = {'END'};
                    j=j+1;
                end
            else
                % write H_LIST
                if size(val,1) > 1 || iscell(val)
                    if iscell(val)
                        val = val(:).';   % keep as cell row
                    else
                        val = val(:).';
                        val = num2cell(val);
                    end
                    spreadsheet(j,1) = {f};
                    spreadsheet(j,2) = {'H_LIST'};
                    spreadsheet(j,3:3-1+numel(val)) = val;
                    spreadsheet(j,3+size(S.(f),1)) = {'END'};
                    j=j+1;
                % write normal value
                else
                    spreadsheet(j,1) = {f};
                    spreadsheet(j,2) = {val};
                    j=j+1;
                end
            end
        end

        spreadsheet(j,1) = {'CLASS_END'};
        j=j+3;

    end
    
end


if exist([result_path run_name '/' run_name '.xlsx'], 'file')
    delete([result_path run_name '/' run_name '.xlsx']);
end

xlswrite([result_path run_name '/' run_name '.xlsx'], spreadsheet)

end
