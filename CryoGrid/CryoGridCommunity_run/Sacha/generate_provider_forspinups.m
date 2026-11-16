function provider = generate_provider_forspinups (run_name, k, tile_idx)


[file_path,file_name] = fileparts(mfilename("fullpath"));

while ~strcmp(file_name,'CryoGrid')
    [file_path,file_name]=fileparts(file_path);
    ROOT_PATH = char(fullfile(file_path,file_name));
end

CG_FORCING_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_forcing/"));
CG_RESULTS_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_results/"));
CG_RUN_PATH     = char(fullfile(ROOT_PATH,"CryoGridCommunity_run/"));
CG_SOURCE_PATH  = char(fullfile(ROOT_PATH,"CryoGridCommunity_source/"));


%% BEGIN USER MODIFY PART


init_format   = 'EXCEL3D'; % choose the option corresponding to the parameter file format


%% END USER MODIFY PART


%% CREATE PROVIDER 0 FROM EXCEL FILE

%result_path   = char(fullfile(CG_RESULTS_PATH, 'templates\'));
result_path   = char(fullfile(CG_RESULTS_PATH));

constant_file = 'CONSTANTS_excel'; %filename of file storing constants


% add source code path
addpath(genpath(CG_SOURCE_PATH));

%create and load PROVIDER
provider0 = PROVIDER;
provider0 = assign_paths(provider0, init_format, run_name, result_path, constant_file);
provider0 = read_const(provider0);
provider0 = read_parameters(provider0);



%% Create new provider named provider from provider0


provider = provider0;

% Tile class
tile_class0 = provider0.RUN_INFO_CLASS.PARA.tile_class;
tile_class0 = tile_class0(:);

tile_class = [tile_class0(1:tile_idx); ...
        repmat(tile_class0(tile_idx), k, 1); ...
        tile_class0(tile_idx+1:end)];

provider.RUN_INFO_CLASS.PARA.tile_class = tile_class;

% Tile class index
n_tiles = numel(tile_class);

tile_class_index0 = provider0.RUN_INFO_CLASS.PARA.tile_class_index;

provider.RUN_INFO_CLASS.PARA.tile_class_index = ...
        cast((1:n_tiles).', 'like', tile_class_index0);

% Number of runs per tile
number_of_runs_per_tile0 = ...
        provider0.RUN_INFO_CLASS.PARA.number_of_runs_per_tile;
number_of_runs_per_tile0 = number_of_runs_per_tile0(:);

number_of_runs_per_tile = [number_of_runs_per_tile0(1:tile_idx); ...
        repmat(number_of_runs_per_tile0(tile_idx), k, 1); ...
        number_of_runs_per_tile0(tile_idx+1:end)];

provider.RUN_INFO_CLASS.PARA.number_of_runs_per_tile = ...
        number_of_runs_per_tile;

% Duplicate TILE_1D
TILE_1D0 = provider0.CLASSES.TILE_1D;

TILE_1D = [TILE_1D0(1:tile_idx); ...
        repmat(TILE_1D0(tile_idx), k, 1); ...
        TILE_1D0(tile_idx+1:end)];

for i = tile_idx+1 : tile_idx+k
    TILE_1D{i,1} = copy(TILE_1D0{tile_idx});
end

provider.CLASSES.TILE_1D = TILE_1D;


% Duplicate OUT classes
OUT_FDD_TDD0 = provider0.CLASSES.OUT_FDD_TDD;
OUT_FDD_TDD = [OUT_FDD_TDD0(1:tile_idx); ...
        repmat(OUT_FDD_TDD0(tile_idx), k, 1); ...
        OUT_FDD_TDD0(tile_idx+1:end)];


OUT_regridded0 = provider0.CLASSES.OUT_regridded;
OUT_regridded = [OUT_regridded0(1:tile_idx); ...
        repmat(OUT_regridded0(tile_idx), k, 1); ...
        OUT_regridded0(tile_idx+1:end)];

for i = tile_idx+1 : tile_idx+k
    OUT_regridded{i,1} = copy(OUT_regridded0{tile_idx});
    OUT_FDD_TDD{i,1} = copy(OUT_FDD_TDD0{tile_idx});
end

provider.CLASSES.OUT_FDD_TDD = OUT_FDD_TDD;
provider.CLASSES.OUT_regridded = OUT_regridded;

% Duplicate Init TTOP from OUT

% INIT_TTOP_from_out0 = provider0.CLASSES.INIT_TTOP_from_out;
% INIT_TTOP_from_out = [INIT_TTOP_from_out0(1:tile_idx); ...
%         repmat(INIT_TTOP_from_out0(tile_idx), k, 1); ...
%         INIT_TTOP_from_out0(tile_idx+1:end)];
% 
% for i = tile_idx+1 : tile_idx+k
%     INIT_TTOP_from_out{i,1} = copy(INIT_TTOP_from_out0{tile_idx});
% end
% 
% provider.CLASSES.INIT_TTOP_from_out = INIT_TTOP_from_out;


% Modify output tags and output class indices
for i = tile_idx : tile_idx+k

    provider.CLASSES.OUT_FDD_TDD{i,1}.PARA.tag = ...
        sprintf('tile%d', i);

    provider.CLASSES.OUT_regridded{i,1}.PARA.tag = ...
        sprintf('tile%d', i);

    provider.CLASSES.TILE_1D{i,1}.PARA.out_class_index = [i; i; 2];  % !! Modif non robuste ici. Cas particulier ou OUT_last time step en 3e position !
    % provider.CLASSES.TILE_1D{i,1}.PARA.init_steady_state_class_index = i;

    provider.CLASSES.TILE_1D{i,1}.PARA.class_index = i;
    provider.CLASSES.OUT_FDD_TDD{i,1}.PARA.class_index = i;
    provider.CLASSES.OUT_regridded{i,1}.PARA.class_index = i;


    % provider.CLASSES.INIT_TTOP_from_out{i,1}.PARA.out_file = ...
    %     sprintf('%s_OUT_FDD_TDD_tile%d', run_name, i-1);
    % provider.CLASSES.INIT_TTOP_from_out{i,1}.PARA.class_index = i;

end


save(fullfile(fullfile(result_path, run_name), [run_name '.mat']), 'provider');

end
