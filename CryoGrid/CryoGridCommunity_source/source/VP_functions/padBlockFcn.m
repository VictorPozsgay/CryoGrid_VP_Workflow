function B = padBlockFcn(B, maxCols)

% Pad columns
B = [B, repmat({""}, size(B,1), maxCols-size(B,2))];

% Count trailing rows that are entirely ""
trailingEmpty = 0;

for r = size(B,1):-1:1
    if all(string(B(r,:)) == "")
        trailingEmpty = trailingEmpty + 1;
    else
        break
    end
end

% Ensure at least 2 trailing empty rows
if trailingEmpty < 2
    B = [B;
        repmat({""}, 2-trailingEmpty, maxCols)];
end

end
