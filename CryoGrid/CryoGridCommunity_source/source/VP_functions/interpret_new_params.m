function [TNew, S] = interpret_new_params(result_path)

newParams = format_template(result_path,'NEW_PARAMS','.xlsx');

TNew = cut_into_blocks(newParams);

mask = (TNew.sup == "NEW_PARAMS");
block = TNew.("blocks"){mask,:};
col = block(:,1);

% Find indices
iStart = find(cellfun(@(x) x == "NEW_PARAMS", col), 1, 'last');
iEnd   = find(cellfun(@(x) x == "CLASS_END",  col), 1);

% Field names strictly between them
fields = string(col(iStart+1:iEnd-1));

% Create empty structure
S = cell2struct(cell(size(fields)), cellstr(fields), 1);

for i = 1:numel(fields)
    f = fields(i);
    disp(f)
    v = reading_line_block(TNew, "NEW_PARAMS", "NEW_PARAMS", 1, f);
    if numel(v) == 1
        v = v{1};
    end
    S.(f) = v;
end

end
