function replace_initial_temp(excel_file, row, new_value)
%REPLACE_INITIAL_TEMP
%   Replaces the initial temperature value in column 3 starting from a given row
%   until a non-numeric cell is found in column 2.
%
% INPUTS:
%   - excel_file : path to the Excel file
%   - row        : starting row index (0-based in original function, MATLAB index used internally)
%   - new_value  : new value to write in column 3

    % Read the Excel file as a cell array
    C = readcell(excel_file);

    % Check that the starting row is within bounds
    if row + 1 > size(C, 1)
        error('❌ Row %d is out of bounds.', row + 1);
    end

    current_row = row + 1;
    n_rows = size(C, 1);

    while current_row <= n_rows
        val_col2 = C{current_row, 2};

        % Check if the cell contains a numeric value (finite number)
        if isnumeric(val_col2) && isfinite(val_col2)
            C{current_row, 3} = new_value;
            fprintf('🔄 Value replaced at row %d, column 3 ➤ %g\n', current_row, new_value);
            current_row = current_row + 1;
        else
            % Stop when a non-numeric cell is found in column 2
            break;
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

    % Save the updated Excel file
    writecell(C, excel_file);
end
