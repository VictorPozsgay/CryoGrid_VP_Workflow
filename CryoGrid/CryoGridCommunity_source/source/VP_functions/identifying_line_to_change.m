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
