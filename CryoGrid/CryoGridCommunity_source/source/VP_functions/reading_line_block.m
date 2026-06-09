function vals = reading_line_block(TIn, sup, cls, idx, param)

mask = (TIn.sup == sup) & (TIn.cls == cls) & (TIn.idx == idx);
idxBlock = find(mask);

l = identifying_line_to_change(TIn.blocks{idxBlock}, cls, idx, param);
block = TIn.blocks{idxBlock,:};
line = block(l,2:end);
line = line(~cellfun(@(x) isstring(x) && isscalar(x) && x == "", line));


if isstring(line{1}) && isscalar(line{1}) && line{1} == "H_LIST"
    idxEnd = find(cellfun(@(x) ...
        isstring(x) && isscalar(x) && x == "END", line), 1);

    if isempty(idxEnd)
        vals = line(2:end);
    else
        vals = line(2:idxEnd-1);
    end

else
    vals = line(1);
end


end
