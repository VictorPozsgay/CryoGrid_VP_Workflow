%run header first

simFile = CG_ground;
surface_altitude = 2840; %in m a.s.l., should normally match the the parameter "altitude" in TILE_1D_standard 
start_height_above_ground = 4; %in m
end_depth_below_ground = 10; %in m

yearDisplay = 1960; % false or integer e.g. 1980
calenderYear = false; % hydrology year if false

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


