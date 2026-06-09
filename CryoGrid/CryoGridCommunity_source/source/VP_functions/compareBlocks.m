function tf = compareBlocks(blocksInit, blocksCheck)

tf = true;

% 1. same number of blocks
if numel(blocksInit) ~= numel(blocksCheck)
    tf = false;
    return;
end

% 2. compare each block
for i = 1:numel(blocksInit)

    A = string(blocksInit{i});
    B = string(blocksCheck{i});

    if ~isequal(size(A), size(B))
        tf = false;
        return;
    end

    if ~all(A == B, 'all')
        tf = false;
        return;
    end

end

end
