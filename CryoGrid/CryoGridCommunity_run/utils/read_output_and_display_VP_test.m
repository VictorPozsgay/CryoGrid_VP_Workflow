function read_output_and_display_VP_test(CG_ground, options)
%PLOT_CG_GROUND Plot CryoGrid ground variables as time-depth images.
%
%
% INPUT
%   CG_ground
%       CryoGrid ground simulation structure CG_ground from OUT_regridded
%       class
%
% NAME-VALUE OPTIONS
%
%   'start_height_above_ground'
%       Height above the inferred ground surface to plot [m].
%       Default: 0
%       If 0, the plot extends to the highest available elevation.
%
%   'end_depth_below_ground'
%       Depth below the inferred ground surface to plot [m].
%       Default: 0
%       If 0, the plot extends to the lowest available elevation.
%
%   'yearDisplay'
%       false -> plot the complete simulation.
%       integer -> plot only the specified year.
%       Default: false
%
%   'calenderYear'
%       true  -> calendar year (January-December).
%       false -> hydrological year (September-August).
%       Default: true
%
%   'surface_altitude'
%       Ground-surface elevation [m a.s.l.].
%       Default: []
%       If empty, the surface altitude is inferred from CG_ground.
%
% EXAMPLES
%
%   plot_CG_ground(CG_ground)
%
%   plot_CG_ground(CG_ground, ...
%       'start_height_above_ground', 4, ...
%       'end_depth_below_ground', 30)
%
%   plot_CG_ground(CG_ground, 'yearDisplay', 1980)
%
%   plot_CG_ground(CG_ground, ...
%       'yearDisplay', 1980, ...
%       'calenderYear', false)
%
%   plot_CG_ground(CG_ground, ...
%       'surface_altitude', 2840, ...
%       'start_height_above_ground', 4, ...
%       'end_depth_below_ground', 30)

%% Input arguments

arguments
    CG_ground struct

    options.start_height_above_ground (1,1) double = 0
    options.end_depth_below_ground    (1,1) double = 0

    options.yearDisplay = false
    options.calenderYear (1,1) logical = true

    options.surface_altitude (1,1) double = NaN
end

%% Determine surface altitude

if isnan(options.surface_altitude)

    % Check if depths_below_ground_surface is populated
    rel_depth_exists = ...
        isfield(CG_ground, 'depths_below_ground_surface') && ...
        ~isempty(CG_ground.depths_below_ground_surface);

    if rel_depth_exists

        surface_altitude = ...
            CG_ground.depths(1) + ...
            CG_ground.depths_below_ground_surface(1);

    else

        % Infer the surface altitude from a sufficiently long simulation
        if CG_ground.timestamp(end) - CG_ground.timestamp(1) >= 365

            depths_no_nan = ...
                all(~isnan(CG_ground.class_number), 2);

            dy = CG_ground.depths(1) - CG_ground.depths(2);

            surface_altitude = ...
                max(CG_ground.depths(depths_no_nan)) + dy;

        else

            error(['Surface altitude could not be inferred because ' ...
                'the simulation is shorter than one year. ' ...
                'Please provide ''surface_altitude'' explicitly.']);

        end
    end

else

    surface_altitude = options.surface_altitude;

end

%% Determine time limits

tlims = set_tlims( ...
    CG_ground.timestamp, ...
    options.yearDisplay, ...
    options.calenderYear);

%% Determine vertical limits

ylims = set_ylims( ...
    CG_ground.depths, ...
    surface_altitude, ...
    options.end_depth_below_ground, ...
    options.start_height_above_ground);

%% Date display format

dateDisp = date_display(options.yearDisplay);

%% Variables to plot

potential_vars = { ...
    'T'
    'waterIce'
    'water'
    'ice'
    'Xice'
    'Xwater'
    'XwaterIce'
    'waterPotential'
    'class_number'
    };

variableList = fieldnames(CG_ground);

variableList = variableList( ...
    ismember(variableList, potential_vars));

%% Time and vertical coordinates

t = CG_ground.timestamp;
y = CG_ground.depths;

%% Plot each available variable

for i = 1:numel(variableList)

    varName = variableList{i};
    var = CG_ground.(varName);

    [t_sub, y_sub, var_sub] = resize_var( ...
        var, t, y, tlims, ylims);

    figure

    h = imagesc(t_sub, y_sub, var_sub);

    axis xy tight

    set(gca, 'Color', [1 1 1])
    set(h, 'AlphaData', ~isnan(var_sub))

    colorbar
    hold on

    %% Temperature-specific formatting

    if strcmp(varName, 'T')

        colormap(turbo)

        clim = max(abs(var_sub(:)), [], 'omitnan');

        if ~isempty(clim) && clim > 0
            caxis([-clim clim])
        end

        freezeMask = var_sub < 0;

        contourf( ...
            t_sub, y_sub, freezeMask, ...
            [0.5 0.5], ...
            'k', ...
            'FaceAlpha', 0.05);

    end

    %% Date formatting

    if exist('datetick', 'file')
        datetick('x', dateDisp, 'keeplimits')
    end

    xlabel('Time')
    ylabel('Depth / Elevation')

    title(strrep(varName, '_', '\_'))

    datacursormode on

end

end


%% ========================================================================
function tlims = set_tlims(t, yearDisplay, calenderYear)

if ~islogical(yearDisplay)

    if calenderYear

        tStart = datenum(yearDisplay, 1, 1, 0, 0, 0);
        tEnd   = datenum(yearDisplay, 12, 31, 23, 59, 59);

    else

        tStart = datenum(yearDisplay - 1, 9, 1, 0, 0, 0);
        tEnd   = datenum(yearDisplay, 8, 31, 23, 59, 59);

    end

else

    tStart = t(1);
    tEnd   = t(end);

end

tlims = [tStart tEnd];

end


%% ========================================================================
function ylims = set_ylims( ...
    depths, ...
    surface_altitude, ...
    end_depth_below_ground, ...
    start_height_above_ground)

% Upper limit
if start_height_above_ground == 0

    upper_limit = max(depths);

else

    upper_limit = ...
        surface_altitude + start_height_above_ground;

end

% Lower limit
if end_depth_below_ground == 0

    lower_limit = min(depths);

else

    lower_limit = ...
        surface_altitude - end_depth_below_ground;

end

ylims = [lower_limit upper_limit];

end


%% ========================================================================
function dateDisp = date_display(yearDisplay)

if ~islogical(yearDisplay)

    dateDisp = 'mmm yy';

else

    dateDisp = 'yyyy';

end

end


%% ========================================================================
function [t_sub, y_sub, var_sub] = resize_var( ...
    var, t, y, tlims, ylims)

tmask = t >= tlims(1) & t <= tlims(2);

t_sub = t(tmask);

ymask = y >= ylims(1) & y <= ylims(2);

y_sub = y(ymask);

var_sub = var(ymask, tmask);

end