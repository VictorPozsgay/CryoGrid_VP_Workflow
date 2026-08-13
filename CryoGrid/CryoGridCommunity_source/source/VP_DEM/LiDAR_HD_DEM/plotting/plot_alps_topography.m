function fig = plot_alps_topography( ...
    output_path, ...
    product, ...
    save_folder, ...
    bounds)

%PLOT_ALPS_TOPOGRAPHY Plot a complete Alpine topographic product.
%
% The Alpine raster is read directly at reduced resolution using
% read_downsample_geotiff(). The full Alpine raster is never loaded.
%
% NoData conversion is performed exclusively by
% read_downsample_geotiff().
%
% Alpine-wide visualization bounds are used when available; otherwise the
% theoretical bounds from get_topography_colormap() are used.

%% ========================================================================
% Paths
% ========================================================================

product_file = fullfile( ...
    output_path, ...
    product, ...
    "ALPS", ...
    sprintf("%s_ALPS.tif",product));

if ~isfile(product_file)

    error( ...
        "Alpine %s product not found: %s", ...
        product, ...
        product_file)

end

%% ========================================================================
% Read product directly at plotting resolution
% ========================================================================

fprintf("Reading Alpine %s\n",product)

plot_factor = 5;

[Zplot,Rplot] = ...
    read_downsample_geotiff( ...
        product_file, ...
        plot_factor);

%% ========================================================================
% Coordinates
% ========================================================================

[x,y] = worldGrid(Rplot);

%% ========================================================================
% Figure
% ========================================================================

fig = figure( ...
    "Visible","on", ...
    "Color","w", ...
    "InvertHardcopy","off", ...
    "WindowState","minimized");

ax = axes(fig);

hold(ax,"on")
box(ax,"on")

set(ax, ...
    "Color","white", ...
    "XColor","k", ...
    "YColor","k");

%% ========================================================================
% Colormap
% ========================================================================

[cmap,theoretical_clim,label] = ...
    get_topography_colormap(product);

colormap(ax,cmap)

%% ========================================================================
% Color limits
% ========================================================================

field = matlab.lang.makeValidName(product);

clim_limits = [];

if isstruct(bounds) && isfield(bounds,field)

    candidate = bounds.(field);

    if isnumeric(candidate) && ...
            numel(candidate) == 2 && ...
            all(isfinite(candidate)) && ...
            candidate(2) > candidate(1)

        clim_limits = double(candidate(:))';

    end

end

if isempty(clim_limits)
    clim_limits = theoretical_clim;
end

%% ========================================================================
% Plot
% ========================================================================

h = surface( ...
    ax, ...
    x, ...
    y, ...
    zeros(size(Zplot)), ...
    double(Zplot), ...
    "EdgeColor","none");

%% ========================================================================
% Transparent NoData
% ========================================================================

h.AlphaData = ~isnan(Zplot);
h.FaceAlpha = "flat";
h.AlphaDataMapping = "none";

%% ========================================================================
% Axes
% ========================================================================

axis(ax,"image")

xlim(ax,Rplot.XWorldLimits)
ylim(ax,Rplot.YWorldLimits)

clim(ax,clim_limits)

%% ========================================================================
% Colorbar
% ========================================================================

cb = colorbar(ax);

cb.Label.String = label;

%% ========================================================================
% Labels
% ========================================================================

xlabel(ax,"Lambert-93 Easting (m)")
ylabel(ax,"Lambert-93 Northing (m)")

title( ...
    ax, ...
    sprintf("IGN LiDAR HD Alpine %s",product));

%% ========================================================================
% Alpine DEM boundary
% ========================================================================

mask_file = fullfile( ...
    output_path, ...
    "DEM", ...
    "ALPS", ...
    "DEM_ALPS_mask.tif");

if isfile(mask_file)

    fprintf("Reading Alpine DEM mask\n")

    [Mplot,Rmplot] = ...
        read_downsample_geotiff( ...
            mask_file, ...
            plot_factor);

    Mplot = Mplot > 0;

    [xm,ym] = worldGrid(Rmplot);

    contour( ...
        ax, ...
        xm, ...
        ym, ...
        double(Mplot), ...
        [1 1], ...
        "k", ...
        "LineWidth",1);

    clear Mplot Rmplot xm ym

end

%% ========================================================================
% Save
% ========================================================================

outfile = fullfile( ...
    save_folder, ...
    sprintf( ...
        "LiDAR_HD_%s_ALPS_overview.png", ...
        upper(product)));

fig.Visible = "off";

exportgraphics( ...
    fig, ...
    outfile, ...
    "Resolution",300);

fprintf("Saved %s\n",outfile)

%% ========================================================================
% Cleanup
% ========================================================================

close(fig)

end