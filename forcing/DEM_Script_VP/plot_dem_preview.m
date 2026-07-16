function plot_dem_preview(DEM,massif,filename,variable)
%PLOT_DEM_PREVIEW Fast DEM preview.
%
% Downsamples DEM for plotting only.

if nargin < 4
    variable = "elevation";
end

switch lower(variable)
    case "elevation"
        Z = DEM.Z;
        cb_label = "Elevation (m a.s.l.)";
        plot_title = "Elevation";
    case "slope"
        Z = DEM.slope_deg;
        cb_label = "Slope (°)";
        plot_title = "Slope";
    case "aspect"
        Z = DEM.aspect_deg;
        cb_label = "Aspect (°)";
        plot_title = "Aspect";
    otherwise
        error("Unknown variable '%s'.",variable)
end

R = DEM.R;

%% Downsampling factor

factor = 10;   % 5m -> 50m
[Zsmall,Rsmall] = downsample_dem(Z,R,factor);

%% Plot

fig = figure("Visible","off");
hold on

% Coordinates of pixel centers

x = Rsmall.XWorldLimits(1) + ...
    Rsmall.CellExtentInWorldX/2 + ...
    (0:size(Zsmall,2)-1)*Rsmall.CellExtentInWorldX;

y = Rsmall.YWorldLimits(2) - ...
    Rsmall.CellExtentInWorldY/2 - ...
    (0:size(Zsmall,1)-1)*Rsmall.CellExtentInWorldY;


% Replace NaN temporarily by minimum elevation

Zplot = Zsmall;
nan_mask = isnan(Zplot);

Zplot(nan_mask) = min(Zsmall,[],'all','omitnan');


% Plot

h = imagesc(x,y,Zplot);
set(gca,"YDir","normal")
axis equal tight


% Make NaN pixels transparent

set(h,"AlphaData",~nan_mask)


% Grey background

ax = gca;
ax.Color = [0.9 0.9 0.9];


% DEM colours

switch lower(variable)
    case "elevation"
        demcmap(Zsmall)
    case "slope"
        colormap(parula)
        clim([0 90])
    case "aspect"
        hsv(360);
        colormap(hsv(360))
        clim([0 360])
end

% Massif outline

mapshow(massif,...
    "FaceColor","none",...
    "EdgeColor","r",...
    "LineWidth",1.5)

% Labels

xlabel("Lambert-93 Easting (m)")
ylabel("Lambert-93 Northing (m)")

cb = colorbar;
cb.Label.String = cb_label;

title(sprintf("%s\nMassif %02d\n%s", ...
    plot_title,...
    DEM.massif_num,...
    DEM.massif_name), ...
    "Interpreter","none")

exportgraphics(fig,filename,"Resolution",200)
close(fig)

end
