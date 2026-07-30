function build_SAFRAN_per_massif(safran_path)
%BUILD_SAFRAN_PER_MASSIF Build one forcing file for each SAFRAN grid point.
%
% DESCRIPTION
%   Reads all yearly SAFRAN meteorological NetCDF files contained in
%   SAFRAN/raw/, concatenates the complete time series and creates one
%   CryoGrid-compatible forcing MAT file for every unique
%   massif/elevation/slope/aspect combination.
%
%   Each output file contains:
%
%       • forcing metadata
%       • SAFRAN massif polygon
%       • meteorological time series
%
%   Duplicate timestamps are removed automatically and the resulting time
%   series are checked for temporal continuity before being written to
%   SAFRAN/per_massif/.
%
% INPUT
%   safran_path
%       Path to:
%
%           SAFRAN/
%
%       containing:
%
%           raw/
%           shapefile/
%
% OUTPUT
%   Creates one MAT file per SAFRAN forcing point in:
%
%           SAFRAN/per_massif/
%
% SEE ALSO
%   PREPARE_FORCING, MERGE_SAFRAN_ERA5.
% 
% NOTE:
% SAFRAN forcing files may contain additional massif identifiers
% (e.g. massif 30) that are not included in the Alpine massif shapefile.
% These massifs are retained in the forcing dataset but have no polygon.


%% ========================================================================
%  Build SAFRAN forcing files
%  ========================================================================

%% Paths

raw_path    = fullfile(safran_path, "raw");
output_path = fullfile(safran_path, "per_massif");

files = dir(fullfile(raw_path,"*.nc"));
if isempty(files)
    files = dir(fullfile(raw_path,"*.NC"));
end

if isempty(files)
    error("No SAFRAN NetCDF files found in %s.", raw_path)
end

files_names = string({files.name});

Nyears = numel(files_names);

if ~isfolder(output_path)
    mkdir(output_path)
end

%% ------------------------------------------------------------------------
% Read metadata ONCE
% -------------------------------------------------------------------------

first_file = fullfile(raw_path, files_names(1));

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

existing = dir(fullfile(output_path,'*.mat'));
existing_names = string({existing.name});

if all(ismember(expected_files, existing_names))
    fprintf('SAFRAN forcing files already exist.\n');
    fprintf('Skipping build_SAFRAN_per_massif().\n');
    return
end

%% ------------------------------------------------------------------------
% Determine total number of timesteps
% -------------------------------------------------------------------------

Ntot = 0;

for j = 1:Nyears
    file = fullfile(raw_path, files_names(j));
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

empty_polygon = struct( ...
    'X', [], ...
    'Y', [], ...
    'Lon', [], ...
    'Lat', []);

FORCING_pre = repmat(struct( ...
    'massif',  [], ...
    'ZS',      [], ...
    'slope',   [], ...
    'aspect',  [], ...
    'lon',     [], ...
    'lat',     [], ...
    'polygon', empty_polygon,...
    'data',    empty_data), Npts,1);

S = read_SAFRAN_massifs(safran_path);

available_massifs = [S.massif_num];

missing_massifs = setdiff(unique(massif), available_massifs);

if ~isempty(missing_massifs)
    warning( ...
        "No polygons found for SAFRAN massifs: %s. Polygon information will be empty.", ...
        strjoin(string(missing_massifs),", "))
end

for i = 1:Npts

    FORCING_pre(i).massif = massif(i);
    FORCING_pre(i).ZS     = zs(i);
    FORCING_pre(i).slope  = slope(i);
    FORCING_pre(i).aspect = aspect(i);
    FORCING_pre(i).lon    = lon(i);
    FORCING_pre(i).lat    = lat(i);

    idx_massif = find(available_massifs == massif(i),1);

    % Some SAFRAN forcing points (e.g. massif 30) do not have a polygon
    % in the Alpine massif shapefile.
    if isempty(idx_massif)
        continue
    end

    FORCING_pre(i).polygon.X   = S(idx_massif).X;
    FORCING_pre(i).polygon.Y   = S(idx_massif).Y;
    FORCING_pre(i).polygon.Lon = S(idx_massif).Lon;
    FORCING_pre(i).polygon.Lat = S(idx_massif).Lat;

end

% Current insertion position for each point
cursor = ones(Npts,1);

%% ========================================================================
% Loop over yearly files
% ========================================================================

for j = 1:Nyears
    fprintf('Reading SAFRAN file %d / %d : %s\n', ...
        j, Nyears, files_names(j))
    filepath = fullfile(raw_path, files_names(j));
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
    fprintf('Writing forcing file %d / %d\n',i,Npts)
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
    save(fullfile(output_path,outfile),'FORCING','-v7.3')
end

end
