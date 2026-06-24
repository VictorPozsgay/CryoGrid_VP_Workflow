% % Find all combinations
% FORCING_VP = struct('data',[]);
% FORCING_VP.data = struct( ...
%     'Tair', [], ...
%     'Lin', [], ...
%     'Sin', [], ...
%     'q', [], ...
%     'wind', [], ...
%     'p', [], ...
%     'rainfall', [], ...
%     'snowfall', [], ...
%     't_span',  []);
% 
% nc_data_folder = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\forcing\Forcing_Data\meteo\safran\";
% nc_output_folder = "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\forcing\Forcing_Data\safran_ready";
% files_list = [
%     dir(fullfile(nc_data_folder, '*.NC')); ...
%     ];
% files_names = string({files_list.name});
% 
% for j = 1:length(files_names)
%     disp(j)
%     filepath = fullfile(nc_data_folder, files_names(j));
%     disp(filepath)
%     info = ncinfo(filepath);
% 
%     % Read variables
%     massif = ncread(filepath, 'massif_number');
%     zs     = ncread(filepath, 'ZS');
%     slope  = ncread(filepath, 'slope');
%     aspect = ncread(filepath, 'aspect');
%     time   = ncread(filepath, 'time');
% 
%     % Weather data
%     Tair       = ncread(filepath, 'Tair');
%     LWdown     = ncread(filepath, 'LWdown');
%     DIR_SWdown = ncread(filepath, 'DIR_SWdown');
%     SCA_SWdown = ncread(filepath, 'SCA_SWdown');
%     Qair       = ncread(filepath, 'Qair');
%     Wind       = ncread(filepath, 'Wind');
%     Rainf      = ncread(filepath, 'Rainf');
%     Snowf      = ncread(filepath, 'Snowf');
%     PSurf      = ncread(filepath, 'PSurf');
% 
%     % Units
%     at_names   = {info.Attributes.Name};
%     starttime  = datetime(info.Attributes(1, strcmp(at_names, 'time_coverage_start')).Value, 'Format', 'uuuu-MM-dd''T''HH:mm:ss');
%     finishtime = datetime(info.Attributes(1, strcmp(at_names, 'time_coverage_end')).Value, 'Format', 'uuuu-MM-dd''T''HH:mm:ss');
%     TIME       = starttime + hours(time);
% 
%     if TIME(end) ~= finishtime
%         disp('Discrepency with the final time')
%     end
% 
%     TAIR = Tair - 273.15;
%     WIND = Wind;
%     WIND(Wind < 0.1) = 0.1;
% 
%     ro_rain = 1000;
%     RAINF = Rainf * (1 / ro_rain) * 1000 * (24 * 60 * 60);
%     SNOWF = Snowf * (1 / ro_rain) * 1000 * (24 * 60 * 60);
%     SWIN  = DIR_SWdown + SCA_SWdown;
% 
% 
%     % for i = 1:info.Dimensions(2).Length
%     for i = 1:1
%         output_file = sprintf('safran_forcing_massif_%d_elevation_%d_slope_%d_aspect_%d.mat', ...
%             massif(i), zs(i), slope(i), aspect(i));
%         if isfile(fullfile(nc_output_folder, output_file))
%             S = load(fullfile(nc_output_folder, output_file));
%         else
%             S = FORCING_VP;
%         end
% 
%         S.data.Tair     = [S.data.Tair; Tair(i,:)'];
%         S.data.Lin      = [S.data.Lin; LWdown(i,:)'];
%         S.data.Sin      = [S.data.Sin; SWIN(i,:)'];
%         S.data.q        = [S.data.q; Qair(i,:)'];
%         S.data.wind     = [S.data.wind; WIND(i,:)'];
%         S.data.p        = [S.data.p; PSurf(i,:)'];
%         S.data.rainfall = [S.data.rainfall; RAINF(i,:)'];
%         S.data.snowfall = [S.data.snowfall; SNOWF(i,:)'];
%         S.data.t_span   = [S.data.t_span; TIME(:)];
% 
%         save(fullfile(nc_output_folder,output_file), '-struct', 'S');
%     end
% end
% 
% % for i = 1:info.Dimensions(2).Length
% for i = 1:1
%     S = load(fullfile(nc_output_folder, output_file));
% 
%     [S.data.t_span, idx] = sort(S.data.t_span);
% 
%     fields = fieldnames(S.data);
%     for k = 1:numel(fields)
%         f = fields{k};
%         if ~strcmp(f,'t_span') && size(S.data.(f),1)==numel(idx)
%             S.data.(f) = S.data.(f)(idx,:);
%         end
%     end
% 
%     % Remove duplicates, keeping first occurrence
%     [~, ia] = unique(S.data.t_span,'stable');
% 
%     S.data.t_span = S.data.t_span(ia);
% 
%     for k = 1:numel(fields)
%         f = fields{k};
%         if ~strcmp(f,'t_span') && size(S.data.(f),1)>=max(ia)
%             S.data.(f) = S.data.(f)(ia,:);
%         end
%     end
% 
%     if ~isscalar(unique(diff(S.data.t_span(:),1)))
%         error('There might be some gaps!')
%     end
% 
% 
%     save(fullfile(nc_output_folder,'newstruct.mat'), '-struct', 'S');
% end


%% ========================================================================
%  Build SAFRAN forcing files
%  ========================================================================

clear

%% Paths

nc_data_folder = ...
    "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\forcing\Forcing_Data\meteo\safran\";

nc_output_folder = ...
    "D:\Utilisateurs\pozsgayv\Documents\CryoGrid_VP_Workflow\forcing\Forcing_Data\safran_ready\";

files_list = dir(fullfile(nc_data_folder,'*.NC'));
files_names = string({files_list.name});

Nyears = numel(files_names);

%% ------------------------------------------------------------------------
% Read metadata ONCE
% -------------------------------------------------------------------------

first_file = fullfile(nc_data_folder, files_names(1));

massif = ncread(first_file,'massif_number');
zs     = ncread(first_file,'ZS');
slope  = ncread(first_file,'slope');
aspect = ncread(first_file,'aspect');

Npts = numel(massif);

%% ------------------------------------------------------------------------
% Determine total number of timesteps
% -------------------------------------------------------------------------

Ntot = 0;

for j = 1:Nyears
    file = fullfile(nc_data_folder, files_names(j));
    time = ncread(file,'time');
    Ntot = Ntot + numel(time);
end

fprintf('Total number of timesteps: %d\n',Ntot)

%% ------------------------------------------------------------------------
% Preallocate forcing structures
% -------------------------------------------------------------------------

empty_data = struct( ...
    'Tair',     nan(Ntot,1,'single'), ...
    'Lin',      nan(Ntot,1,'single'), ...
    'Sin',      nan(Ntot,1,'single'), ...
    'q',        nan(Ntot,1,'single'), ...
    'wind',     nan(Ntot,1,'single'), ...
    'p',        nan(Ntot,1,'single'), ...
    'rainfall', nan(Ntot,1,'single'), ...
    'snowfall', nan(Ntot,1,'single'), ...
    't_span',   NaT(Ntot,1));

FORCING = repmat(struct( ...
    'massif', [], ...
    'ZS',     [], ...
    'slope',  [], ...
    'aspect', [], ...
    'data',   empty_data), Npts,1);

for i = 1:Npts
    FORCING(i).massif = massif(i);
    FORCING(i).ZS     = zs(i);
    FORCING(i).slope  = slope(i);
    FORCING(i).aspect = aspect(i);
end

% Current insertion position for each point
cursor = ones(Npts,1);

%% ========================================================================
% Loop over yearly files
% ========================================================================

for j = 1:Nyears
    fprintf('Processing %d / %d : %s\n', ...
        j, Nyears, files_names(j))
    filepath = fullfile(nc_data_folder, files_names(j));
    info = ncinfo(filepath);

    % Read time
    time = ncread(filepath,'time');
    at_names = {info.Attributes.Name};
    starttime = datetime( ...
        info.Attributes(strcmp(at_names,'time_coverage_start')).Value,...
        'Format','uuuu-MM-dd''T''HH:mm:ss');
    TIME = starttime + hours(time);
    Nt = numel(TIME);

    % Read meteorological variables
    Tair       = single(ncread(filepath,'Tair') - 273.15);
    LWdown     = single(ncread(filepath,'LWdown'));
    DIR_SWdown = single(ncread(filepath,'DIR_SWdown'));
    SCA_SWdown = single(ncread(filepath,'SCA_SWdown'));
    SWIN       = DIR_SWdown + SCA_SWdown;
    Qair       = single(ncread(filepath,'Qair'));
    Wind       = single(ncread(filepath,'Wind'));
    Wind(Wind < 0.1) = 0.1;
    PSurf      = single(ncread(filepath,'PSurf'));
    Rainf      = single(ncread(filepath,'Rainf'));
    Snowf      = single(ncread(filepath,'Snowf'));
    RAINF = Rainf * 86400;
    SNOWF = Snowf * 86400;

    % Store data
    for i = 1:Npts
        idx = cursor(i):(cursor(i)+Nt-1);

        FORCING(i).data.Tair(idx)     = Tair(i,:)';
        FORCING(i).data.Lin(idx)      = LWdown(i,:)';
        FORCING(i).data.Sin(idx)      = SWIN(i,:)';
        FORCING(i).data.q(idx)        = Qair(i,:)';
        FORCING(i).data.wind(idx)     = Wind(i,:)';
        FORCING(i).data.p(idx)        = PSurf(i,:)';
        FORCING(i).data.rainfall(idx) = RAINF(i,:)';
        FORCING(i).data.snowfall(idx) = SNOWF(i,:)';
        FORCING(i).data.t_span(idx)   = TIME(:);

        cursor(i) = cursor(i) + Nt;
    end
end

%% ========================================================================
% Sort, remove duplicates and save
% ========================================================================

for i = 1:Npts
    fprintf('Saving point %d / %d\n',i,Npts)
    S = FORCING(i);

    % Sort
    [S.data.t_span, idx] = sort(S.data.t_span);
    fields = fieldnames(S.data);

    for k = 1:numel(fields)
        f = fields{k};
        if ~strcmp(f,'t_span')
            S.data.(f) = S.data.(f)(idx,:);
        end
    end

    % Remove duplicates
    [~,ia] = unique(S.data.t_span,'stable');
    S.data.t_span = S.data.t_span(ia);
    for k = 1:numel(fields)
        f = fields{k};
        if ~strcmp(f,'t_span')
            S.data.(f) = S.data.(f)(ia,:);
        end
    end

    % Check for missing timesteps
    dt = unique(diff(S.data.t_span));
    if numel(dt) ~= 1
        error('Gaps detected in forcing time series')
    end

    % Save
    outfile = sprintf( ...
        'safran_forcing_massif_%d_elevation_%d_slope_%d_aspect_%d.mat', ...
        S.massif, S.ZS, S.slope, S.aspect);
    save(fullfile(nc_output_folder,outfile),'-struct','S','-v7.3')
end