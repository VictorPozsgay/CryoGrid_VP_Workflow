clc; clear

% user inputs the root of the folder
baseResultsPath = ...
'D:\Utilisateurs\pozsgayv\Documents\CryoGrid_Optimization_Automatization_Workflow-main\CryoGrid\CryoGridCommunity_results\';

addpath(genpath(baseResultsPath));

% in this folder, put all the subfolder names here (run names)
% one per line, no commas
run_names = {
    'test1'
};


%  loop through all the runs
for r = 1:numel(run_names)

    run_name   = run_names{r};
    folderPath = fullfile(baseResultsPath, run_name);
    disp(['run name: ',run_name])

    % find list of all files in the folder
    listing = dir(fullfile(folderPath, ['*' run_name '*.mat']));
    files   = fullfile({listing(~[listing.isdir]).folder}, {listing(~[listing.isdir]).name});
    names   = {listing.name};
    pattern = '_\d{8}\.mat$';
    idx     = ~cellfun('isempty', regexp(names, pattern, 'once'));
    listing = listing(idx);
    files   = files(idx);
    
    % find the list of all types of outputs
    % (e.g. 'snow' or 'TwaterIce_fichier_resultats')
    % this is given by the string coming before _YYYYMMDD.mat
    pat_lead = fullfile(folderPath, run_name);
    pattern  = sprintf('(?<=%s).*(?=_[0-9]{8}\\.mat)', regexptranslate('escape', append(pat_lead,'_')));
    types    = unique(regexp(files, pattern, 'match', 'once'));

    % disp(types)

    % loop through output types
    for t = 1:numel(types)

        type = types{t};
        disp(['file name: ',type])

        % select files with the correct type only
        pattern = ['^' ...
            regexptranslate('escape', pat_lead) '_' ...
            regexptranslate('escape', type) '_\d{8}\.mat$'];
        idx = ~cellfun('isempty', regexp(files, pattern, 'once'));
        selectedFiles = files(idx);

        % load data for the first file to initialize
        tmp     = load(selectedFiles{1});
        fn_high = fieldnames(tmp);
        data    = tmp.(fn_high{1});

        % find all field names
        fn = fieldnames(data);

        % find all the field formats
        sizes = cellfun(@(f) size(data.(f)), fn, 'UniformOutput', false);
        uniqueSizes = unique(cellfun(@mat2str, sizes, 'UniformOutput', false));

        % Extract all numbers
        nums = regexp(uniqueSizes, '\d+', 'match');
        nums = [nums{:}];

        % Count unique values, corresponding to the array's dimension
        % If dim=1, the only dimension is temporal
        % If dim=2, we also have depths
        dim = numel(unique(str2double(nums)))-1;
        % disp(dim)

        % find name of timestamp ts in the shape (1xn double)
        idx = cellfun(@(f) isnumeric(data.(f)) && ismatrix(data.(f)) ...
            && size(data.(f),1) == 1, fn);
        ts = fn{idx};
        % value = data.(ts);
        disp(['The timestamp field is called: ', ts])

        % find name of depths d in the shape [mx1 double]
        % IF EXISTS
        if dim==2
            idx = cellfun(@(f) isnumeric(data.(f)) && ismatrix(data.(f)) ...
                && size(data.(f),2) == 1, fn);
            d = fn{idx};
            disp(['The depths field is called: ', d])
        end
   
        % initialize concatenated structure
        final = struct();
        for f = 1:numel(fn)
            final.(fn{f}) = [];
            if dim==2
                final.(d) = data.(d);
            end
        end

        % start the concatenation
        % disp('here we go')
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

        % delete potential duplicate timestamps
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

        out_file_name = append(run_name,'_',type,'_merged.mat');
        % disp(out_file_name)
        out_path = fullfile(folderPath, out_file_name);
        % disp(out_path)
        if isfile(out_path)
            delete(out_path)
            % disp('deleted out path')
        end
        % disp(fn_high{1})
        % disp(final)
        S = struct();
        S.(fn_high{1}) = final;
        save(fullfile(folderPath, out_file_name), ...
            '-struct', 'S', "-v7.3");

        disp("✔ Fusion terminée correctement (dimensions conservées)");
    
    end


end

clearvars