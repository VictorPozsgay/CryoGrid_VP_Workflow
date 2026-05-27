function rows = find_parameter_rows(excel_file, parameters)
% find_parameter_rows
%   Finds the row indices of each parameter in the first column of the Excel sheet
%
% INPUTS :
%   - excel_file : path to the Excel file
%   - parameters : cell array of strings (e.g., {'z0', 'albedo'})
%
% OUTPUT :
%   - rows : structure with parameter names as fields. 
%            If a parameter appears multiple times (e.g., 'albedo'), the field
%            contains an array [idx1, idx2].

    T = readcell(excel_file);
    first_column = string(T(:,1));  % first column of the table
    rows = struct();

    for i = 1:length(parameters)
        name = parameters{i};
        idx = find(first_column == name);

        if isempty(idx)
            warning('⚠️ Parameter "%s" not found.', name);
            rows.(name) = NaN;
        elseif strcmpi(name, 'albedo')
            % Keep the first two occurrences
            if length(idx) >= 2
                rows.(name) = idx(1:2);
            else
                warning('⚠️ Less than 2 occurrences for "albedo".');
                rows.(name) = idx;  % return whatever is found
            end
        else
            rows.(name) = idx(1);  % for others, take the first occurrence only
        end
    end
end
