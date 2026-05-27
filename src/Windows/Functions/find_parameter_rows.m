function rows = find_parameter_rows(excel_file, parameters)
% find_parameter_rows
%   Find the row indices of each parameter in the first column of an Excel file
%
% INPUTS:
%   - excel_file : path to the Excel file
%   - parameters : cell array of strings (e.g., {'z0', 'albedo'})
%
% OUTPUT:
%   - rows : structure with field names corresponding to parameters.
%            If a parameter appears multiple times (e.g., 'albedo'), the
%            field will contain an array [idx1, idx2].

    T = readcell(excel_file);
    first_col = string(T(:,1));  % first column of the table
    rows = struct();

    for i = 1:length(parameters)
        param_name = parameters{i};
        idx = find(first_col == param_name);

        if isempty(idx)
            warning('⚠️ Parameter "%s" not found.', param_name);
            rows.(param_name) = NaN;
        elseif strcmpi(param_name, 'albedo')
            % Keep the first two occurrences
            if length(idx) >= 2
                rows.(param_name) = idx(1:2);
            else
                warning('⚠️ Less than 2 occurrences for "albedo".');
                rows.(param_name) = idx;  % return whatever is found
            end
        else
            rows.(param_name) = idx(1);  % for other parameters, keep only the first occurrence
        end
    end
end
