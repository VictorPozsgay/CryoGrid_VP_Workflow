function lastInfo = find_last_file_out_last_timestep(result_path, run_name)
%FIND_LAST_FILE_OUT_LAST_TIMESTEP  Identify latest CryoGrid output file
%
% This function scans the simulation output directory and identifies the
% most recent "_last_timestep.mat" file based on tile index, run index,
% and simulation date.
%
%
% INPUTS
% ------
% result_path   (char|string)
%     Root directory of simulation outputs.
%
% run_name      (char|string)
%     Name of the simulation run (folder name).
%
%
% OUTPUT
% ------
% lastInfo      (struct)
%     Structure containing:
%       lastFile : filename (without extension)
%       lastTile : tile index
%       lastRun  : run index
%       lastDate : YYYYMMDD integer
%
%
% DESCRIPTION
% -----------
% The function:
%   - Searches for all "*_last_timestep.mat" files
%   - Extracts tile/run/date information using regexp
%   - Filters invalid filenames
%   - Sorts results lexicographically (tile → run → date)
%   - Returns the most recent completed simulation file
%
%
% SORTING RULE
% ------------
% Priority order:
%   1. Tile index
%   2. Run index
%   3. Date (YYYYMMDD)
%

% find last file
files = dir(fullfile(result_path, run_name, '*_last_timestep.mat*'));

lastInfo = struct("lastFile", "", "lastTile", 1, "lastRun", 1, "lastDate", 0);

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

    [~, lastInfo.lastFile] = fileparts(names{lastIdx});
    lastInfo.lastTile = nums(lastIdx, 1);
    lastInfo.lastRun  = nums(lastIdx, 2);
    lastInfo.lastDate = nums(lastIdx, 3);

end

end
