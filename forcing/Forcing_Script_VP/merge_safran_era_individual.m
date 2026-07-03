function FORCING_3h = merge_safran_era_individual(FORCING, S)
%MERGE_SAFRAN_ERA_INDIVIDUAL Merge SAFRAN forcing with ERA5 TOA forcing.
%
% DESCRIPTION
%   Merges a single SAFRAN forcing structure with the corresponding ERA5
%   top-of-atmosphere (TOA) incoming shortwave radiation time series for
%   one massif. The function:
%
%     1. Adds massif metadata from the ERA5 structure to the SAFRAN
%        forcing structure.
%     2. Keeps only timesteps common to both datasets.
%     3. Adds the ERA5 TOA radiation as the new forcing variable S_TOA.
%     4. Adds a constant albedo_foot field (default value: 0.2).
%     5. Aggregates all forcing variables from hourly to 3-hourly
%        resolution by averaging over custom intervals:
%
%           [t1] [t2 t3 t4] [t5 t6 t7] ...
%
%        where the first timestep is preserved individually and all
%        subsequent groups contain three hourly timesteps.
%     6. Converts the final time vector from datetime to MATLAB datenum.
%     7. Verifies that the final forcing is regularly spaced every
%        exactly 3 hours.
%
% INPUTS
%   FORCING : struct
%       CryoGrid forcing structure produced from SAFRAN. The structure must
%       contain a field FORCING.data with at least:
%
%           t_span
%           Tair
%           Lin
%           Sin
%           q
%           wind
%           p
%           rainfall
%           snowfall
%
%       All time-dependent variables must have the same number of rows as
%       FORCING.data.t_span.
%
%   S : struct
%       Structure describing one massif extracted from the ERA5 TOA
%       dataset. It must contain:
%
%           massif_num
%           lat
%           lon
%           nom
%           nom_reduit
%           TOA
%           TOA_time
%
% OUTPUT
%   FORCING_3h : struct
%       CryoGrid-ready forcing structure containing:
%
%         • all original SAFRAN variables
%         • ERA5 massif metadata
%         • S_TOA
%         • albedo_foot
%         • a common time axis
%         • 3-hourly averaged forcing
%
% NOTES
%   - Both input time vectors are internally converted to UTC before
%     computing their intersection.
%
%   - The first hourly timestep is preserved individually so that the final
%     3-hourly series starts on a valid 3-hour boundary.
%
%   - All forcing variables, including rainfall and snowfall, are averaged
%     during temporal aggregation because they are stored as instantaneous
%     rates (mm day^-1) rather than accumulated precipitation.
%
%   - The function throws an error if:
%       * the original forcing is not regularly hourly,
%       * the final forcing is not regularly 3-hourly,
%       * or the first output timestep is not aligned on a 3-hour boundary.
%
% See also TIMETABLE, VARFUN, SPLITAPPLY, INTERSECT, DATENUM.

% Start from existing forcing
FORCING_new = FORCING;

%% Add massif metadata (everything except TOA and TOA_time)

meta = rmfield(S, {'TOA','TOA_time'});

fields = fieldnames(meta);

for i = 1:numel(fields)
    FORCING_new.(fields{i}) = meta.(fields{i});
end

FORCING.data.t_span.TimeZone = 'UTC';
S.TOA_time.TimeZone = 'UTC';

%% Find common timestamps

[t_common, idxF, idxTOA] = intersect( ...
    FORCING.data.t_span, ...
    S.TOA_time);

% Optional sanity check
fprintf('Keeping %d common timesteps\n', numel(t_common));

%% Restrict all FORCING.data fields to common timesteps

data_fields = fieldnames(FORCING.data);

for i = 1:numel(data_fields)

    f = data_fields{i};

    % Only subset time-dependent variables
    if size(FORCING.data.(f),1) == numel(FORCING.data.t_span)
        FORCING_new.data.(f) = FORCING.data.(f)(idxF,:);
    end

end

%% Replace t_span by common times
FORCING_new.data.t_span = t_common;

%% Add S_TOA
FORCING_new.data.S_TOA = S.TOA(idxTOA);

%% Add albedo_foot
albedo_foot = 0.2;
albedo_foot = albedo_foot * ones(size(FORCING_new.data.t_span,1), 1);
FORCING_new.data.albedo_foot = albedo_foot;

%% Go from hourly to 3-hourly
if numel(unique(diff(FORCING_new.data.t_span(:),1))) == 1
    % step 1: create timetable
    TT = timetable(FORCING_new.data.t_span);

    fields = fieldnames(FORCING_new.data);

    for i = 1:numel(fields)
        f = fields{i};
        if ~strcmp(f,'t_span')
            TT.(f) = FORCING_new.data.(f);
        end
    end

    % step 2: create index
    N = height(TT);

    group = uint32(1):uint32(N);
    group = arrayfun(@(x) idivide(x+1,3) + 1, group);

    TT.Group = group';

    % step 3: group
    TT3 = varfun(@mean, TT, 'GroupingVariables','Group');
    t_out = splitapply(@max, TT.Time, TT.Group);

    % step 4: rebuild clean timetable
    TT3.Time = t_out;
    TT3.Group = [];

    % rename variables (remove "mean_" prefix)
    vars = TT3.Properties.VariableNames;

    for i = 1:numel(vars)
        if startsWith(vars{i}, 'mean_')
            TT3.Properties.VariableNames{i} = extractAfter(vars{i}, 5);
        end
    end

    % step 5: back to struct
    FORCING_3h = FORCING_new;

    FORCING_3h.data.t_span = TT3.Time;

    for i = 1:numel(fields)
        f = fields{i};
        if ~strcmp(f,'t_span')
            FORCING_3h.data.(f) = TT3.(f);
        end
    end

    % step 6: datetime to datenum
    FORCING_3h.data.t_span = datenum(FORCING_3h.data.t_span);

    problem = false;

    if numel(unique(diff(FORCING_3h.data.t_span(:)))) == 1
        if ~(unique(diff(FORCING_3h.data.t_span(:))) == 3/24)
            problem = true;
        end
    else
        problem = true;
    end

    if problem
        error('There is an error with the final timesteps! Not evenly 3-hourly spaced.')
    end

    if ~mod(FORCING_3h.data.t_span(1), 3/24) == 0
        error('The first timestep is not a multiple of 3h.')
    end
    
else
    error('There is an error with the inital timesteps! Not evenly hourly spaced.')
end

end
