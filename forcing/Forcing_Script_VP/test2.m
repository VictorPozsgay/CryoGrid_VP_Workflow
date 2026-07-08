out_path = "..\..\forcing\Forcing_Data\meteo\CryoGrid_ready_new";
out_name = 'FORCING_SAFRAN_ALL.mat';
if isfile(fullfile(out_path,out_name))
    fprintf('Skipping existing file.\n');
    return
end

files = dir(fullfile(out_path, "safran_forcing_massif_*.mat"));

% Preallocate (23 massifs expected)
FORCING = struct([]);

%% ============================================================
%  1. LOAD ALL FILES AND GROUP BY MASSIF
%% ============================================================

for f = 1:length(files)

    fname = fullfile(out_path, files(f).name);
    S = load(fname);
    F = S.FORCING;

    m = F.massif_num;

    % Initialize massif if first encounter
    if ~isfield(FORCING, 'name') || numel(FORCING) < m || isempty(FORCING(m).name)

        FORCING(m).massif_num = F.massif;
        FORCING(m).name       = F.nom;
        FORCING(m).lon        = F.lon;
        FORCING(m).lat        = F.lat;

        FORCING(m).data = struct();
    end

    % Extract level
    z = F.ZS;

    %% ========================================================
    %  2. APPEND LEVEL DATA
    %% ========================================================

    % Time series
    D = F.data;

    % Initialize storage on first level
    vars = fieldnames(D);

    for v = 1:length(vars)
        varname = vars{v};

        % Skip t_span (handled separately)
        if strcmp(varname, 't_span') | strcmp(varname, 'S_TOA')
            continue;
        end

        vec = D.(varname);

        % Ensure column vector
        vec = vec(:);

        % Initialize storage if needed
        if ~isfield(FORCING(m).data, varname) || isempty(FORCING(m).data.(varname))
            FORCING(m).data.(varname) = [];
        end

        % Append as new column (time × level)
        FORCING(m).data.(varname)(:, end+1) = vec;
    end

    % Store time only once (assumed identical across files)
    if ~isfield(FORCING(m).data, 't_span') || isempty(FORCING(m).data.t_span)
        FORCING(m).data.t_span = D.t_span(:);
    end

    % Store S_TOA only once (assumed identical across files)
    if ~isfield(FORCING(m).data, 'S_TOA') || isempty(FORCING(m).data.S_TOA)
        FORCING(m).data.S_TOA = D.S_TOA(:);
    end

    % Initialize storage if needed
    if ~isfield(FORCING(m).data, 'z') || isempty(FORCING(m).data.z)
        FORCING(m).data.z = [];
    end
    FORCING(m).data.z(end+1) = z;
end

valid = ~cellfun(@isempty, {FORCING.massif_num});
FORCING = FORCING(valid);

%% ============================================================
%  3. SORT VERTICAL LEVELS (CRITICAL STEP)
%% ============================================================

for m = 1:length(FORCING)

    [Zsorted, idx] = sort(FORCING(m).data.z);
    FORCING(m).data.z = Zsorted;

    vars = fieldnames(FORCING(m).data);

    for v = 1:length(vars)
        varname = vars{v};

        if size(FORCING(m).data.(varname),2) == numel(Zsorted)
            if varname == 'z'
                FORCING(m).data.(varname) = Zsorted;
            else
                FORCING(m).data.(varname) = FORCING(m).data.(varname)(:, idx);
            end
        end
    end
end

%% ============================================================
%  4. CONVERT TO SINGLE PRECISION (OPTIONAL BUT RECOMMENDED)
%% ============================================================

for m = 1:length(FORCING)

    vars = fieldnames(FORCING(m).data);

    for v = 1:length(vars)
        varname = vars{v};
        FORCING(m).data.(varname) = single(FORCING(m).data.(varname));
    end

    FORCING(m).lon = single(FORCING(m).lon);
    FORCING(m).lat = single(FORCING(m).lat);
end


%% ============================================================
%  5. CHECK DATA
%% ============================================================

inspected_files = {};
for m = 1:length(FORCING)
    for i = 1:numel(FORCING(m).data.z)
        massif_num = FORCING(m).massif_num;
        z = FORCING(m).data.z(i);
        filename = sprintf("safran_forcing_massif_%d_elevation_%d_slope_0_aspect_-1.mat",massif_num,z);
        inspected_files{end+1} = char(filename);
        fullname = fullfile(out_path, filename);
        S = load(fullname);
        F = S.FORCING;

        vars = {'lat'; 'lon'};
        for v = 1:length(vars)
            varname = vars{v};
            if ~(single(F.(varname)) == FORCING(m).(varname))
                sprintf('Problem with massif %d, elevation %d (index %d), and variable %s', m, z, i, varname)
            end
        end

        vars = fieldnames(FORCING(m).data);
        for v = 1:length(vars)
            varname = vars{v};
            if ~strcmp(varname,'z')
                data1 = single(F.data.(varname));
                data2 = single(FORCING(m).data.(varname));
                idx = min(i,size(data2,2));
                if single(max(abs(data1(:) - data2(:,idx))))
                    sprintf('Problem with massif %d, elevation %d (index %d), and variable %s', massif_num, z, i, varname)
                    return
                end
            end
        end
    end
end


% Extract filenames from the dir structure
file_names = {files.name};

% Sort both lists
file_names = sort(file_names);
inspected_files = sort(inspected_files);

% Check if they are identical
if isequal(file_names, inspected_files)
    disp('All expected files are present.');
else
    disp('Mismatch detected.');

    fprintf('Missing files:\n');
    disp(setdiff(inspected_files, file_names))

    fprintf('Unexpected files:\n');
    disp(setdiff(file_names, inspected_files))
end

%% ============================================================
%  6. SAVE FINAL STRUCTURE
%% ============================================================

save(fullfile(out_path,out_name), 'FORCING', '-v7.3');

disp("DONE: SAFRAN merged into single FORCING struct.");
