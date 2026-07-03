function read_safran(safran_path)
%READ_SAFRAN Convert SAFRAN NetCDF forcing to individual CryoGrid files.
%
% DESCRIPTION
%   Reads all yearly SAFRAN NetCDF files located in the "raw" subdirectory,
%   concatenates the meteorological time series, and creates one MAT file
%   per unique massif/elevation/slope/aspect combination in the
%   "per_massif" subdirectory. Duplicate timestamps are removed and the
%   resulting time series are checked for continuity.
%
% INPUT
%   safran_path   Folder containing the "raw" SAFRAN NetCDF files.
%
% OUTPUT
%   One MAT file per SAFRAN point containing a FORCING structure compatible
%   with the subsequent CryoGrid preprocessing workflow.
%
% See also MERGE_SAFRAN_ERA.

%% ========================================================================
%  Build SAFRAN forcing files
%  ========================================================================

%% Paths

nc_data_folder = fullfile(safran_path, "raw\");

nc_output_folder = fullfile(safran_path, "per_massif\");

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
lon = ncread(first_file,'LON');
lat = ncread(first_file,'LAT');

Npts = numel(massif);

%% ------------------------------------------------------------------------
% Build expected output list
% -------------------------------------------------------------------------

expected_files = strings(Npts,1);

for i = 1:Npts
    expected_files(i) = sprintf( ...
        'safran_forcing_massif_%d_elevation_%d_slope_%d_aspect_%d.mat', ...
        massif(i), zs(i), slope(i), aspect(i));
end

existing = dir(fullfile(nc_output_folder,'*.mat'));
existing_names = string({existing.name});

if all(ismember(expected_files, existing_names))
    fprintf('All forcing files already exist. Skipping.\n');
    return
end

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

FORCING_pre = repmat(struct( ...
    'massif', [], ...
    'ZS',     [], ...
    'slope',  [], ...
    'aspect', [], ...
    'lon', [], ...
    'lat', [], ...
    'data',   empty_data), Npts,1);

for i = 1:Npts
    FORCING_pre(i).massif = massif(i);
    FORCING_pre(i).ZS     = zs(i);
    FORCING_pre(i).slope  = slope(i);
    FORCING_pre(i).aspect = aspect(i);
    FORCING_pre(i).lon = lon(i);
    FORCING_pre(i).lat = lat(i);
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

        FORCING_pre(i).data.Tair(idx)     = Tair(i,:)';
        FORCING_pre(i).data.Lin(idx)      = LWdown(i,:)';
        FORCING_pre(i).data.Sin(idx)      = SWIN(i,:)';
        FORCING_pre(i).data.q(idx)        = Qair(i,:)';
        FORCING_pre(i).data.wind(idx)     = Wind(i,:)';
        FORCING_pre(i).data.p(idx)        = PSurf(i,:)';
        FORCING_pre(i).data.rainfall(idx) = RAINF(i,:)';
        FORCING_pre(i).data.snowfall(idx) = SNOWF(i,:)';
        FORCING_pre(i).data.t_span(idx)   = TIME(:);

        cursor(i) = cursor(i) + Nt;
    end
end

%% ========================================================================
% Sort, remove duplicates and save
% ========================================================================

for i = 1:Npts
    fprintf('Saving point %d / %d\n',i,Npts)
    S = FORCING_pre(i);

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
    FORCING = S;
    save(fullfile(nc_output_folder,outfile),'FORCING','-v7.3')
end

end
