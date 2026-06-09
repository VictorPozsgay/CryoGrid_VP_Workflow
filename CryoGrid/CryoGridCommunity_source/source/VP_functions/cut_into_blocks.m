function T = cut_into_blocks(data)

sepIdx = find(startsWith(strtrim(string(data(:,1))), "-"));
sepIdx = [sepIdx; size(data,1)+1];

nBlocks = numel(sepIdx)-1;
blocks = cell(1,nBlocks);

for i = 1:nBlocks
    blocks{i} = data(sepIdx(i):sepIdx(i+1)-1, :);    
    if ~startsWith(strtrim(string(blocks{i}(1,1))), "-")
        disp('Issue with block, not starting with "-"')
    end    
end

sup = strings(nBlocks,1);
cls = strings(nBlocks,1);
idx = zeros(nBlocks,1);

for i = 1:nBlocks
    sup(i) = string(blocks{i}{2,1});
    cls(i) = string(blocks{i}{3,1});
    idx(i) = blocks{i}{3,2};
end

T = table(sup, cls, idx);
T.blocks = blocks(:);

end
