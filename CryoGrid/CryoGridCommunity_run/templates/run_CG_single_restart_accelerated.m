%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Begin user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%

[file_path,file_name] = fileparts(mfilename('fullpath'));

while ~strcmp(file_name,'CryoGrid')
    [file_path,file_name]=fileparts(file_path);
    ROOT_PATH = char(fullfile(file_path,file_name));
end

CG_FORCING_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_forcing/"));
CG_RESULTS_PATH = char(fullfile(ROOT_PATH,"CryoGridCommunity_results/"));
CG_RUN_PATH     = char(fullfile(ROOT_PATH,"CryoGridCommunity_run/"));
CG_SOURCE_PATH  = char(fullfile(ROOT_PATH,"CryoGridCommunity_source/"));


%% The 4 parameters needed to run a simulation
init_format   = 'EXCEL3D'; % choose the option corresponding to the parameter file format
run_name      = 'FORCING_seb_toElevation_Richards'; % name of parameter file (without file extension) AND name of subfolder (in result_path) within which it is located
result_path   = char(fullfile(CG_RESULTS_PATH,'templates\test_SAFRAN\'));
constant_file = 'CONSTANTS_excel'; %filename of file storing constants


%%%%%%%%%%%%%%%%%%%%%%%% end user-modified part %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
%                             do not change
% -------------------------------------------------------------------------

% add source code path
addpath(genpath(CG_SOURCE_PATH));

%create and load PROVIDER
provider = PROVIDER;
provider = assign_paths(provider, init_format, run_name, result_path, constant_file);
provider = read_const(provider);
provider = read_parameters(provider);

%restart
out_path = char(fullfile(result_path, run_name, '\'));
t_end_spinup = char(datetime(provider.CLASSES.FORCING_seb_toElevation{1,1}.PARA.end_time','Format','yyyyMMdd'));
t_end_run = char(datetime(provider.CLASSES.FORCING_seb_toElevation{2,1}.PARA.end_time','Format','yyyyMMdd'));

tag_out_w_run_number = '';
if isfield(provider.CLASSES,'tag_out_w_run_number')
    if any(strcmp(provider.CLASSES.tag_out_w_run_number{1,1}.PARA.target_class_name, 'OUT_FDD_TDD'))
        tag_out_w_run_number = '_1';
    end
end

expected_files = struct();

expected_files.tile1 = {[run_name '_tile1_last_timestep_' t_end_spinup '.mat']};
expected_files.tile2 = {[run_name '_OUT_FDD_TDD' tag_out_w_run_number '.mat']};
expected_files.tile3 = {[run_name '_tile3_last_timestep_' t_end_spinup '.mat']};
expected_files.tile4 = {
    [run_name '_ground_' t_end_run '.mat']
    [run_name '_snow_' t_end_run '.mat']
};


ground_files   = dir(fullfile(out_path, [run_name '_ground_*.mat']));
snow_files     = dir(fullfile(out_path, [run_name '_snow_*.mat']));
timestep_files = dir(fullfile(out_path, [run_name '_tile4_last_timestep_*.mat']));

ground_dates   = regexp({ground_files.name},'(?<=_ground_)\d{8}(?=\.mat$)','match','once');
snow_dates     = regexp({snow_files.name},'(?<=_snow_)\d{8}(?=\.mat$)','match','once');
timestep_dates = regexp({timestep_files.name},'(?<=_tile4_last_timestep_)\d{8}(?=\.mat$)','match','once');

common_dates = intersect(intersect(ground_dates, snow_dates), timestep_dates);

if ~isempty(common_dates)
    last_date = common_dates{end};
    date_vec  = datevec(datetime(last_date, 'InputFormat', 'yyyyMMdd') + days(1));
    date_vec  = date_vec(1:3)';
    last_file = [run_name '_tile4_last_timestep_' last_date '.mat'];
else
    last_date = [];
    date_vec  = [];
    last_file = [];
end

if ~all(cellfun(@(f) isfile(fullfile(out_path,f)), expected_files.tile4))
    provider.CLASSES.TILE_1D{5,1}.PARA.restart_file_path = out_path;

    if all(cellfun(@(f) isfile(fullfile(out_path,f)), expected_files.tile3))
        if ~isempty(last_date) && length(last_date) == 8
            provider.CLASSES.TILE_1D{5,1}.PARA.restart_file_name = last_file;
            provider.CLASSES.TILE_1D = provider.CLASSES.TILE_1D(5);
            provider.CLASSES.FORCING_seb_toElevation{2,1}.PARA.start_time = date_vec;
            provider.RUN_INFO_CLASS.PARA.tile_class = provider.RUN_INFO_CLASS.PARA.tile_class(1);
            provider.RUN_INFO_CLASS.PARA.tile_class_index = 1;
            provider.RUN_INFO_CLASS.PARA.number_of_runs_per_tile = 1;
        else
            provider.CLASSES.TILE_1D{5,1}.PARA.restart_file_name = expected_files.tile3{1};
            provider.CLASSES.TILE_1D = provider.CLASSES.TILE_1D([5 4]);
            provider.RUN_INFO_CLASS.PARA.tile_class = provider.RUN_INFO_CLASS.PARA.tile_class([1 2]);
            provider.RUN_INFO_CLASS.PARA.tile_class_index = [1;2];
            provider.RUN_INFO_CLASS.PARA.number_of_runs_per_tile = [1;1];
        end
    else
        if all(cellfun(@(f) isfile(fullfile(out_path,f)), expected_files.tile2))
            provider.CLASSES.TILE_1D = provider.CLASSES.TILE_1D([3 4]);
            provider.RUN_INFO_CLASS.PARA.tile_class = provider.RUN_INFO_CLASS.PARA.tile_class([1 2]);
            provider.RUN_INFO_CLASS.PARA.tile_class_index = [1;2];
            provider.RUN_INFO_CLASS.PARA.number_of_runs_per_tile = [1;1];
        else
            if all(cellfun(@(f) isfile(fullfile(out_path,f)), expected_files.tile1))
                provider.CLASSES.TILE_1D{5,1}.PARA.restart_file_name = expected_files.tile1{1};
                provider.CLASSES.TILE_1D = provider.CLASSES.TILE_1D([5 2 3 4]);
            end
        end
    end

    % create RUN_INFO class
     [run_info, provider] = run_model(provider);
    % run model
     [run_info, tile] = run_model(run_info);

end

%% ADD MERGING OF ALL OUT_CG FILES WHEN FINISHED

% toc