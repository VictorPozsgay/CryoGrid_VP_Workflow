%run header first

simFile = CG_ground;

% check if 'depths_below_ground_surface' is populated
rel_depth_exists = numel(CG_ground.depths_below_ground_surface) > 0;

surface_altitude = [];

if rel_depth_exists
    surface_altitude = CG_ground.depths(1)+CG_ground.depths_below_ground_surface(1);
else
    if CG_ground.timestamp(end)-CG_ground.timestamp(1) >= 365
        depths_no_nan = all(~isnan(CG_ground.class_number), 2);
        dy = CG_ground.depths(1)-CG_ground.depths(2);
        surface_altitude = max(CG_ground.depths(depths_no_nan)) + dy;
    else
        error('Not enough time to infer ground elevation, please input it.')
    end
end

% surface_altitude = 2840; %in m a.s.l., should normally match the the parameter "altitude" in TILE_1D_standard 
start_height_above_ground = 4; %in m
end_depth_below_ground = 30; %in m

yearDisplay = false; % false or integer e.g. 1980
calenderYear = true; % hydrology year if false

source_path = '../CryoGridCommunity_source';
addpath(genpath(source_path));

potential_vars = {'T'; 'waterIce'; 'water'; 'ice'; 'Xice'; 'Xwater';
    'XwaterIce'; 'waterPotential'; 'class_number'};

variableList = fieldnames(simFile);
mask = ismember(variableList,potential_vars);
variableList = variableList(mask);

t = simFile.timestamp;
y = simFile.depths;

function tlims = set_tlims(t, yearDisplay, calenderYear)

if ~islogical(yearDisplay)
    if calenderYear
        tStart = datenum(yearDisplay,1,1,0,0,0);
        tEnd   = datenum(yearDisplay,12,31,23,59,59);
    else
        tStart = datenum(yearDisplay-1,9,1,0,0,0);
        tEnd   = datenum(yearDisplay,8,31,23,59,59);
    end
else
    tStart = t(1);
    tEnd   = t(end);
end

tlims = [tStart tEnd];

end

function ylims = set_ylims(surface_altitude, end_depth_below_ground, ...
    start_height_above_ground)

ylims = [surface_altitude-end_depth_below_ground
    surface_altitude+start_height_above_ground];

end

function dateDisp = date_display(yearDisplay)

if ~islogical(yearDisplay)
    dateDisp = 'mmm yy';
else
    dateDisp = 'yyyy';
end

end

function [t_sub, y_sub, var_sub] = resize_var(var, t, y, tlims, ylims)

tmask = t >= tlims(1) & t <= tlims(2);
t_sub = t(tmask);
ymask = y >= ylims(1) & y <= ylims(2);
y_sub = y(ymask);
var_sub = var(ymask,tmask);

end

tlims = set_tlims(t, yearDisplay, calenderYear);
ylims = set_ylims(surface_altitude, end_depth_below_ground, ...
    start_height_above_ground);
dateDisp = date_display(yearDisplay);

for i=1:numel(variableList)
    varName = variableList{i};
    var = simFile.(varName);
    [t_sub, y_sub, var_sub] = resize_var(var, t, y, tlims, ylims);
    figure
    h = imagesc(t_sub, y_sub, var_sub);

    axis xy tight
    set(gca,'Color',[1 1 1])
    set(h,'AlphaData',~isnan(var_sub))
    colorbar
    hold on

    if strcmp(varName, 'T')
        colormap(turbo)
        clim = max(abs(var_sub(:)),[],'omitnan');
        if ~isempty(clim) && clim > 0
            caxis([-clim clim])
        end

        freezeMask  = var_sub < 0;
        contourf(t_sub, y_sub, freezeMask , [0.5 0.5], 'k', 'FaceAlpha', 0.05);

    end

    
    % datetick('x',dateDisp,'keeplimits')
    if exist('datetick','file')
        datetick('x',dateDisp,'keeplimits')
    end

    xlabel('Time')
    ylabel('Depth / Elevation')

    title(strrep(varName,'_','\_'))
    
    datacursormode on
end


