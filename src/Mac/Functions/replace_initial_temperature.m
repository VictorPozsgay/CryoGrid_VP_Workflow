function replace_initial_temperature(excel_file, start_line, new_value)
% replace_initial_temperature
%   Replace the initial temperature values in an Excel file starting from
%   a given line until the next non-numeric row in column 2.
%
% INPUTS:
%   - excel_file : path to the Excel file
%   - start_line : line number to start replacing (0-based in original logic)
%   - new_value  : new value to write in column 3

    % Read the Excel file as a cell array
    C = readcell(excel_file);

    % Check that the start line is within the file limits
    if start_line + 1 > size(C, 1)
        error('❌ Line %d is out of bounds.', start_line + 1);
    end

    current_line = start_line + 1;
    n_lines = size(C, 1);

    while current_line <= n_lines
        value_col2 = C{current_line, 2};

        % Check if the cell contains a numeric value
        if isnumeric(value_col2) && isfinite(value_col2)
            C{current_line, 3} = new_value;
            fprintf('🔄 Value replaced at line %d, column 3 ➤ %g\n', current_line, new_value);
            current_line = current_line + 1;
        else
            % Stop as soon as a non-numeric cell in column 2 is found
            break;
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

    % Save back to Excel
    writecell(C, excel_file);
end
