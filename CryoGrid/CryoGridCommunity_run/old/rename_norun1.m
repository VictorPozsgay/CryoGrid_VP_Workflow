folder = '..\CryoGridCommunity_results\templates\restart_broken\hidden';

files = dir(fullfile(folder, '*.mat'));

for k = 1:numel(files)
    oldName = files(k).name;

    tokens = regexp(oldName, '^(.+)_run1_(.+)\.mat$', 'tokens', 'once');
    if ~isempty(tokens)
        newName = sprintf('%s_%s.mat', tokens{1}, tokens{2});

        fprintf('Renaming %s -> %s\n', oldName, newName);
        movefile(fullfile(folder, oldName), fullfile(folder, newName));
    end
end