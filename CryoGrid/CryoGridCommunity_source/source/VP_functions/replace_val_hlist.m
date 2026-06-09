function sheet = replace_val_hlist(sheet, rowIdx, param, value)

arguments
    sheet
    rowIdx
    param
    value
end

vec = {param};

if iscell(value)
    vec = [vec, {"H_LIST"}, value, {"END"}];
else
    vec = [vec, {value}];
end

% CAREFUL: make sure the table is wide enough!!!
sheet(:, end+1:numel(vec)) = repmat({""}, size(sheet,1), ...
    numel(vec)-size(sheet,2));
vec = [vec, repmat({""}, 1, size(sheet,2)-numel(vec))];
sheet(rowIdx, 1:(numel(vec))) = vec;

end
