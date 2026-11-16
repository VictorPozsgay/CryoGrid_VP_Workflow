[file_path,file_name] = fileparts(mfilename('fullpath'));

while ~strcmp(file_name,'CryoGrid')
    [file_path,file_name]=fileparts(file_path);
    ROOT_PATH = char(fullfile(file_path,file_name));
end

CG_FORCING_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_forcing"));
CG_RESULTS_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_results"));
%CG_RUN_PATH     = char(fullfile(ROOT_PATH,"CryoGridCommunity_run"));
CG_SOURCE_PATH  = char(fullfile(ROOT_PATH,"CryoGridCommunity_source"));

% add source code path
addpath(genpath(CG_SOURCE_PATH));

folder_matlab = char(fullfile(pwd,"massif_02"));
folder_must   = char(fullfile(pwd,"massif_02_must"));

run_info_matlab = load(fullfile(folder_matlab,"run_parameters.mat"));
run_info_must   = load(fullfile(folder_must,"run_parameters.mat"));

cluster_matlab = run_info_matlab.run_info.SPATIAL.RUN_INFO.CLUSTER.STATVAR.cluster_number;
cluster_must   = run_info_must.run_info.CLUSTER.STATVAR.cluster_number;

centroids_matlab = run_info_matlab.run_info.SPATIAL.RUN_INFO.CLUSTER.STATVAR.sample_centroid_index;
centroids_must   = run_info_must.run_info.CLUSTER.STATVAR.sample_centroid_index;

if sum(cluster_matlab ~= cluster_must)
    disp("Clusters are not identical")
else
    disp("Clusters are identical")
end

if sum(centroids_matlab ~= centroids_must)
    disp("Centroids are not identical")
else
    disp("Centroids are identical")
end



files_matlab = dir(fullfile(folder_matlab, '*_ground_*.mat'));
filenames_matlab = {files_matlab.name};

files_must = dir(fullfile(folder_must, '*_ground_*.mat'));
filenames_must = {files_must.name};


T_matlab_array = [];
T_must_array = [];
max_diff_T = [];
n_nan_mismatch = [];

for c = 1:numel(centroids_matlab)

    disp(c)

    pattern_matlab = sprintf('_ground_%d', centroids_matlab(c));
    idx_matlab = find(contains(filenames_matlab, pattern_matlab));
    
    disp(idx_matlab)

    if numel(idx_matlab) ~= 1
        warning('Centroid %d: found %d matching files', centroids_matlab(c), numel(idx_matlab));
        continue
    end

    data_matlab = load(fullfile(folder_matlab, filenames_matlab{idx_matlab}));
    T_matlab = data_matlab.CG_ground.T;
    T_matlab_array(:,:,end+1) = T_matlab;

    pattern_must = sprintf('_ground_%d', centroids_must(c));
    idx_must = find(contains(filenames_must, pattern_must));
    
    disp(idx_must)

    if numel(idx_must) ~= 1
        warning('Centroid %d: found %d matching files', centroids_must(c), numel(idx_must));
        continue
    end

    data_must = load(fullfile(folder_must, filenames_must{idx_must}));
    T_must = data_must.CG_ground.T;
    T_must_array(:,:,end+1) = T_must;

    % Absolute differences (NaNs included)
    diff_T = abs(T_matlab - T_must);

    % Largest difference (ignoring NaNs)
    [max_diff, linear_idx] = max(diff_T(:), [], 'omitnan');
    
    max_diff_T(end+1) = max_diff;

    nan_mismatch = xor(isnan(T_matlab), isnan(T_must));

    % Count NaN mismatches
    n_nan_mismatch(end+1) = sum(nan_mismatch(:));
end