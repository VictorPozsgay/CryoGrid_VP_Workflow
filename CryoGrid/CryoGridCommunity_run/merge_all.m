clc; clear

% user inputs the root of the folder
baseResultsPath = '..\CryoGridCommunity_results\templates';
% in this folder, put all the subfolder names here (run names)
% one per line, no commas
run_names = {
    'no_spinup'
};


baseResultsPath = char(java.io.File(fullfile(baseResultsPath)).getCanonicalPath());
addpath(genpath(baseResultsPath));

function files = read_files(folderPath, run_name)

% find list of all files in the folder
listing = dir(fullfile(folderPath, ['*' run_name '*.mat']));
files   = fullfile({listing(~[listing.isdir]).folder}, {listing(~[listing.isdir]).name});
names   = {listing.name};
pattern = '_\d{8}\.mat$';
idx     = ~cellfun('isempty', regexp(names, pattern, 'once'));
files   = files(idx);

end

function types = read_types(folderPath, run_name, files)

% find the list of all types of outputs
% (e.g. 'snow' or 'TwaterIce_fichier_resultats')
% this is given by the string coming before _YYYYMMDD.mat
pat_lead  = fullfile(folderPath, run_name);
pattern   = sprintf('(?<=%s).*(?=_[0-9]{8}\\.mat)', regexptranslate('escape', append(pat_lead,'_')));
types = unique(regexp(files, pattern, 'match', 'once'));

end

function selectedFiles = select_files(folderPath, run_name, type, files)

% select files with the correct type only
pat_lead = fullfile(folderPath, run_name);
pattern = ['^' ...
    regexptranslate('escape', pat_lead) '_' ...
    regexptranslate('escape', type) '_\d{8}\.mat$'];
idx = ~cellfun('isempty', regexp(files, pattern, 'once'));
selectedFiles = files(idx);

end

function [fn, fn_high, data] = init_first_file(selectedFiles)

% load data for the first file to initialize
tmp     = load(selectedFiles{1});
fn_high = fieldnames(tmp);
fn_high = fn_high{1};
data    = tmp.(fn_high);
if isstruct(data)
    % find all field names
    fn = fieldnames(data);
else
    fn = [];
    % error('Loaded variable is not a structure.');
end

end

function final = init_merge_struct(fn, d, data)

% initialize concatenated structure
final = struct();
for f = 1:numel(fn)
    final.(fn{f}) = [];
    if strcmp(d,'depths')
        final.(d) = data.(d);
    end
end

end

function [final, fn] = concat_files(selectedFiles, ts, d, final)

% start the concatenation
for k = 1:numel(selectedFiles)
    % disp(['current file: ', selectedFiles{k}])
    % load data for the current file
    tmp  = load(selectedFiles{k});
    fn   = fieldnames(tmp);
    data = tmp.(fn{1});
    fn = fieldnames(data);
    for f = 1:numel(fn)
        if ~strcmp(fn{f},d)
            % disp(['current field name: ', fn{f}])
            len_ts = numel(data.(ts));
            if size(data.(fn{f}),1) == len_ts
                final.(fn{f}) = [final.(fn{f}) ; data.(fn{f})];
            else
                final.(fn{f}) = [final.(fn{f}) , data.(fn{f})];
            end
        end
    end
end

end

function final = del_duplicate_timesteps(final, ts, d, fn)

% delete potential duplicate timestamps
disp('Deleting potential duplicate timestamps')
len_orig = numel(final.(ts));
[unique_ts, idx] = unique(final.(ts), 'first');
for f = 1:numel(fn)
    if ~strcmp(fn{f},d)
        [m, n] = size(final.(fn{f}));
        if len_orig == m
            final.(fn{f}) = final.(fn{f})(idx, :);
        elseif len_orig == n
            final.(fn{f}) = final.(fn{f})(:, idx);
        end
    end
end

end

function write_merged(folderPath, run_name, type, fn_high, final)

disp('Writing merged structure to file')
out_file_name = append(run_name,'_',type,'_merged.mat');
% disp(out_file_name)
out_path = fullfile(folderPath, out_file_name);
% disp(out_path)
if isfile(out_path)
    delete(out_path)
end
S = struct();
S.(fn_high) = final;
save(fullfile(folderPath, out_file_name), ...
    '-struct', 'S', "-v7.3");

disp("✔ Successful concatenation ");
disp("--------------------------------------------------------------------")
disp("--------------------------------------------------------------------")

end

function full_merge_write(folderPath, run_name, type, selectedFiles, ts, d, data, fn, fn_high)

final = init_merge_struct(fn, d, data);
[final, fn] = concat_files(selectedFiles, ts, d, final);
final = del_duplicate_timesteps(final, ts, d, fn);
write_merged(folderPath, run_name, type, fn_high, final)

end

ts = 'timestamp';

%  loop through all the runs
for r = 1:numel(run_names)

    run_name   = run_names{r};
    folderPath = fullfile(baseResultsPath, run_name);
    disp(['run name: ',run_name])

    files = read_files(folderPath, run_name);
    types = read_types(folderPath, run_name, files);

    % loop through output types
    for t = 1:numel(types)

        type = types{t};
        disp(['file name: ',type])

        selectedFiles = select_files(folderPath, run_name, type, files);

        % load data for the first file to initialize
        [fn, fn_high, data] = init_first_file(selectedFiles);
        disp(['Workspace parameter name: ', fn_high])

        if strcmp(fn_high, 'CG_ground') || strcmp(fn_high, 'OUT_TwaterIce')
            d  = 'depths';
            full_merge_write(folderPath, run_name, type, selectedFiles, ts, d, data, fn, fn_high)
        
        elseif strcmp(fn_high, 'CG_snow')
            d  = [];
            full_merge_write(folderPath, run_name, type, selectedFiles, ts, d, data, fn, fn_high)

        else
            fprintf('Unexpected variable name: %s\n', fn_high);
        end
    
    end

end

% clearvars