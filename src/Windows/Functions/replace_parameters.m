function replace_parameters(excel_file, rows, new_values)
%REPLACE_PARAMETERS
%   Replaces parameters in an Excel file at specified rows with new values.
%
% INPUTS:
%   - excel_file : path to the Excel file
%   - rows       : structure with field names corresponding to parameters,
%                  containing row indices in the Excel file
%   - new_values : structure with new values for each parameter

    % Read the Excel file as a cell array
    C = readcell(excel_file);
    param_names = fieldnames(new_values);

    for i = 1:length(param_names)
        param = param_names{i};
        if isfield(rows, param)
            row_idx = rows.(param);
            if ~all(isnan(row_idx))
                for k = 1:length(row_idx)
                    if ~isnan(row_idx(k))
                        % 🔁 Special case for start_time and end_time
                        if strcmp(param, 'start_time') || strcmp(param, 'end_time')
                            date_val = new_values.(param);
                            if ischar(date_val) || isstring(date_val)
                                date_val = datetime(date_val, 'InputFormat', 'dd-MMM-yyyy');
                            end

                            % Write into columns 3 (year), 4 (month), 5 (day)
                            C{row_idx(k), 3} = year(date_val);
                            C{row_idx(k), 4} = month(date_val);
                            C{row_idx(k), 5} = day(date_val);

                            fprintf('📅 Date "%s" updated ➤ %d-%d-%d (row %d)\n', ...
                                param, year(date_val), month(date_val), day(date_val), row_idx(k));
                        else
                            % 🔁 Standard case for other parameters
                            C{row_idx(k), 2} = new_values.(param);
                            fprintf('✅ Parameter "%s" updated (row %d) ➤ %g\n', ...
                                param, row_idx(k), new_values.(param));
                        end
                    end
                end
            else
                warning('⚠️ Row missing for "%s"', param);
            end
        else
            warning('⚠️ Parameter "%s" does not exist in the row dictionary.', param);
        end
    end

    % Cleanup: replace all missing entries with empty strings
    for i = 1:size(C,1)
        for j = 1:size(C,2)
            if ismissing(C{i,j})
                C{i,j} = '';
            end
        end
    end

    % Write back to Excel
    writecell(C, excel_file);
end
