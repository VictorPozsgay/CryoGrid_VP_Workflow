function FORCING_3h = merge_SAFRAN_ERA5_individual(FORCING, ERA5_massif)
%MERGE_SAFRAN_ERA5_INDIVIDUAL Merge SAFRAN forcing with ERA5 TOA forcing.
%
% DESCRIPTION
%   Merges one SAFRAN forcing structure with the corresponding ERA5
%   top-of-atmosphere (TOA) incoming shortwave radiation time series for
%   one SAFRAN massif.
%
%   The function:
%
%     1. Adds ERA5 massif metadata to the SAFRAN forcing structure.
%
%     2. Keeps only timestamps common to both SAFRAN and ERA5 datasets.
%
%     3. Adds ERA5 TOA radiation as:
%
%            data.S_TOA
%
%     4. Optionally adds a constant surface albedo footprint:
%
%            data.albedo_foot
%
%        with a default value of 0.2.
%        This field is currently disabled in the implementation.
%
%     5. Aggregates the forcing from hourly to 3-hourly resolution by
%        averaging the forcing variables.
%
%        Rainfall and snowfall are averaged as well because SAFRAN provides
%        these variables as instantaneous rates (mm day^-1).
%
%     6. Converts the final time vector from datetime to MATLAB datenum for
%        compatibility with the CryoGrid forcing format.
%
%     7. Checks that the final forcing time series is regularly spaced at
%        exactly 3-hour intervals.
%
%
% INPUTS
%   FORCING
%       SAFRAN forcing structure produced by:
%
%           build_SAFRAN_per_massif()
%
%       The structure must contain:
%
%           data.t_span
%           data.Tair
%           data.Lin
%           data.Sin
%           data.q
%           data.wind
%           data.p
%           data.rainfall
%           data.snowfall
%
%
%   ERA5_massif
%       ERA5 massif structure produced by:
%
%           interpolate_ERA5_to_massifs()
%
%       The structure must contain:
%
%           massif_num
%           lat
%           lon
%           TOA
%           TOA_time
%
%
% OUTPUT
%   FORCING_3h
%       CryoGrid-compatible forcing structure containing:
%
%           • SAFRAN meteorological forcing
%           • ERA5 TOA radiation
%           • massif metadata
%           • optional albedo_foot
%
%       The forcing is provided at 3-hour temporal resolution.
%
%
% NOTES
%   - SAFRAN and ERA5 timestamps are internally converted to UTC before
%     computing their intersection.
%
%   - The function assumes that the input SAFRAN forcing is regularly
%     hourly spaced.
%
%   - The first aggregation step preserves the original grouping strategy:
%
%          [t1] [t2 t3 t4] [t5 t6 t7] ...
%
%   - The function throws an error if:
%
%       * the original forcing is not hourly spaced,
%       * the final forcing is not regularly 3-hourly spaced,
%       * the first timestep is not aligned on a 3-hour boundary.
%
%
% SEE ALSO
%   MERGE_SAFRAN_ERA5, BUILD_SAFRAN_PER_MASSIF,
%   INTERPOLATE_ERA5_TO_MASSIFS.


% Start from existing forcing
FORCING_new = FORCING;

%% Add massif metadata (everything except TOA and TOA_time)

meta = rmfield(ERA5_massif, {'TOA','TOA_time'});

fields = fieldnames(meta);

for i = 1:numel(fields)
    FORCING_new.(fields{i}) = meta.(fields{i});
end

FORCING.data.t_span.TimeZone = 'UTC';
ERA5_massif.TOA_time.TimeZone = 'UTC';

%% Find common timestamps

[t_common, idxF, idxTOA] = intersect( ...
    FORCING.data.t_span, ...
    ERA5_massif.TOA_time);

fprintf('Keeping %d common timesteps\n', numel(t_common));

%% Restrict all FORCING.data fields to common timesteps

data_fields = fieldnames(FORCING.data);

for i = 1:numel(data_fields)

    f = data_fields{i};

    if size(FORCING.data.(f),1) == numel(FORCING.data.t_span)
        FORCING_new.data.(f) = FORCING.data.(f)(idxF,:);
    end

end

%% Replace t_span by common times

FORCING_new.data.t_span = t_common;

%% Add ERA5 TOA radiation

FORCING_new.data.S_TOA = ERA5_massif.TOA(idxTOA);

% %% Add albedo footprint
% 
% albedo_foot = 0.2;
% albedo_foot = albedo_foot * ones(size(FORCING_new.data.t_span,1),1);
% 
% FORCING_new.data.albedo_foot = albedo_foot;

%% Aggregate hourly forcing to 3-hourly forcing

if numel(unique(diff(FORCING_new.data.t_span(:),1))) == 1

    TT = timetable(FORCING_new.data.t_span);

    fields = fieldnames(FORCING_new.data);

    for i = 1:numel(fields)

        f = fields{i};

        if ~strcmp(f,'t_span')
            TT.(f) = FORCING_new.data.(f);
        end

    end

    N = height(TT);

    group = uint32(1):uint32(N);
    group = arrayfun(@(x) idivide(x+1,3)+1, group);

    TT.Group = group';

    TT3 = varfun(@mean, TT, 'GroupingVariables','Group');

    t_out = splitapply(@max, TT.Time, TT.Group);


    TT3.Time = t_out;
    TT3.Group = [];


    vars = TT3.Properties.VariableNames;

    for i = 1:numel(vars)

        if startsWith(vars{i},'mean_')
            TT3.Properties.VariableNames{i} = ...
                extractAfter(vars{i},5);
        end

    end


    FORCING_3h = FORCING_new;

    FORCING_3h.data.t_span = TT3.Time;


    for i = 1:numel(fields)

        f = fields{i};

        if ~strcmp(f,'t_span')
            FORCING_3h.data.(f)=TT3.(f);
        end

    end


    %% Convert datetime to datenum

    FORCING_3h.data.t_span = datenum(FORCING_3h.data.t_span);


    %% Validate timestep

    problem = false;

    if numel(unique(diff(FORCING_3h.data.t_span(:)))) == 1

        if ~(unique(diff(FORCING_3h.data.t_span(:))) == 3/24)
            problem = true;
        end

    else

        problem = true;

    end


    if problem
        error('Final forcing timesteps are not evenly 3-hourly.')
    end


    if ~mod(FORCING_3h.data.t_span(1),3/24)==0
        error('The first timestep is not aligned on a 3-hour boundary.')
    end


else

    error('Initial forcing timesteps are not evenly hourly.')

end

end