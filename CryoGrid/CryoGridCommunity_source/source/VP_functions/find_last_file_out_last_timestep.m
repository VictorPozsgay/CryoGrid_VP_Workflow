function ops = find_last_file_out_last_timestep(result_path)

% find last file
files = dir(fullfile(result_path, '*_last_timestep.mat*'));

ops = struct("lastFile", "", "lastTile", 1, "lastRun", 1, "lastDate", 0);

if ~isempty(files)
    names = {files.name};

    pattern = '.*tile(\d+)_run(\d+)_(\d+)_last_timestep.mat';

    tok = regexp(names, pattern, 'tokens');

    % remove files that didn't match (robustness)
    valid = ~cellfun(@isempty, tok);
    names = names(valid);
    tok = tok(valid);

    nums = cellfun(@(t) str2double(t{1}), tok, 'UniformOutput', false);
    nums = vertcat(nums{:});

    % lexicographic sort: tile → run → date
    [~, idx] = sortrows(nums, [1 2 3]);

    lastIdx = idx(end);

    [~, ops.lastFile] = fileparts(names{lastIdx});
    ops.lastTile = nums(lastIdx, 1);
    ops.lastRun  = nums(lastIdx, 2);
    ops.lastDate = nums(lastIdx, 3);

end

end
