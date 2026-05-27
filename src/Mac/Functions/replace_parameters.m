function replace_parameters(excel_file, lines, new_values)
% replace_parameters
%   Replace values in an Excel file at the specified lines with new values.
%
% INPUTS:
%   - excel_file : path to the Excel file
%   - lines      : structure with line numbers for each parameter
%   - new_values : structure with new values to write

    C = readcell(excel_file);
    param_names = fieldnames(new_values);

    for i = 1:length(param_names)
        param = param_names{i};
        if isfield(lines, param)
            line_idx = lines.(param);
            if ~all(isnan(line_idx))
                for k = 1:length(line_idx)
                    if ~isnan(line_idx(k))
                        % 🔁 Special case for start_time and end_time
                        if strcmp(param, 'start_time') || strcmp(param, 'end_time')
                            date_val = new_values.(param);
                            if ischar(date_val) || isstring(date_val)
                                date_val = datetime(date_val, 'InputFormat', 'dd-MMM-yyyy');
                            end

                            % Write in columns 3 (year), 4 (month), 5 (day)
                            C{line_idx(k), 3} = year(date_val);
                            C{line_idx(k), 4} = month(date_val);
                            C{line_idx(k), 5} = day(date_val);

                            fprintf('📅 Date "%s" updated ➤ %d-%d-%d (line %d)\n', ...
                                param, year(date_val), month(date_val), day(date_val), line_idx(k));
                        else
                            % 🔁 Standard case for other parameters
                            C{line_idx(k), 2} = new_values.(param);
                            fprintf('✅ Parameter "%s" updated (line %d) ➤ %g\n', ...
                                param, line_idx(k), new_values.(param));
                        end
                    end
                end
            else
                warning('⚠️ Missing line for parameter "%s"', param);
            end
        else
            warning('⚠️ Parameter "%s" does not exist in the lines structure.', param);
        end
    end

    % Cleanup: replace all 'missing' with empty strings
    for i = 1:size(C,1)
        for j = 1:size(C,2)
            if ismissing(C{i,j})
                C{i,j} = "";
            end
        end
    end

    % Write back to Excel
    writecell(C, excel_file);
end
