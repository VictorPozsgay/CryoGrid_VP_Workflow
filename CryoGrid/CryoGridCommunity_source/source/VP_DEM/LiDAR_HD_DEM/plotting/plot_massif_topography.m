function plot_massif_topography(output_path,massif_number,bounds)
%PLOT_MASSIF_TOPOGRAPHY
% Plot all available topographic products for one SAFRAN massif.
%
% Product rasters are read directly at reduced resolution using
% read_downsample_geotiff().
%
% NoData conversion is performed only by read_downsample_geotiff().
%
% Alpine-wide bounds are used whenever available.

%% ========================================================================
% Validation
% ========================================================================

if ~isfolder(output_path)

    error( ...
        "LiDAR HD DEM product folder not found:\n%s", ...
        output_path)

end

if ~isscalar(massif_number) || ...
        ~isfinite(massif_number) || ...
        massif_number ~= round(massif_number) || ...
        massif_number < 1

    error("massif_number must be a positive integer.")

end

if nargin < 3 || isempty(bounds)

    bounds = struct();

elseif ~isstruct(bounds)

    warning( ...
        "Invalid bounds input. Using theoretical plotting bounds.")

    bounds = struct();

end

%% ========================================================================
% Paths
% ========================================================================

diagnostics_folder = fullfile( ...
    output_path, ...
    "diagnostics");

if ~isfolder(diagnostics_folder)
    mkdir(diagnostics_folder)
end

massif_string = sprintf("%02d",massif_number);

%% ========================================================================
% Discover products
% ========================================================================

fprintf( ...
    "\nSearching massif %s topography products...\n", ...
    massif_string)

folders = dir(output_path);

products = {};

for i = 1:numel(folders)

    if ~folders(i).isdir
        continue
    end

    name = folders(i).name;

    if startsWith(name,".")
        continue
    end

    if strcmpi(name,"MASK")
        continue
    end

    product_file = fullfile( ...
        output_path, ...
        name, ...
        sprintf( ...
            "%s_massif_%s.tif", ...
            name, ...
            massif_string));

    if isfile(product_file)
        products{end+1} = name;
    end

end

if isempty(products)

    fprintf( ...
        "No topography products found for massif %s.\n", ...
        massif_string)

    return

end

fprintf( ...
    "Found %d products for massif %s:\n", ...
    numel(products), ...
    massif_string)

disp(products')

%% ========================================================================
% Read massif mask at plotting resolution
% ========================================================================

plot_factor = 5;

mask_file = fullfile( ...
    output_path, ...
    "DEM", ...
    sprintf("DEM_mask_massif_%s.tif",massif_string));

dem_file = fullfile( ...
    output_path, ...
    "DEM", ...
    sprintf("DEM_massif_%s.tif",massif_string));

if isfile(mask_file)

    fprintf( ...
        "Reading DEM mask massif %s\n", ...
        massif_string)

    [MASKplot,Rmaskplot] = ...
        read_downsample_geotiff( ...
            mask_file, ...
            plot_factor);

    MASKplot = MASKplot > 0;

elseif isfile(dem_file)

    fprintf( ...
        "DEM mask not found. Using DEM as fallback mask.\n")

    [DEMmask,Rmaskplot] = ...
        read_downsample_geotiff( ...
            dem_file, ...
            plot_factor);

    MASKplot = isfinite(DEMmask);

    clear DEMmask

else

    error( ...
        "Neither DEM nor DEM mask found for massif %s.", ...
        massif_string)

end

%% ========================================================================
% Figure
% ========================================================================

nProducts = numel(products);

nCols = ceil(sqrt(nProducts));
nRows = ceil(nProducts/nCols);

fig = figure( ...
    "Name", ...
    sprintf("Massif %s topography",massif_string), ...
    "Color","w", ...
    "InvertHardcopy","off", ...
    "Units","normalized", ...
    "Position",[0.05 0.05 0.90 0.85]);

tiledlayout( ...
    nRows, ...
    nCols, ...
    "TileSpacing","compact", ...
    "Padding","compact");

%% ========================================================================
% Plot products
% ========================================================================

for i = 1:nProducts

    product = products{i};

    fprintf( ...
        "Reading %s massif %s\n", ...
        product, ...
        massif_string)

    product_file = fullfile( ...
        output_path, ...
        product, ...
        sprintf( ...
            "%s_massif_%s.tif", ...
            product, ...
            massif_string));

    %% Read directly at plotting resolution

    [Aplot,Rplot] = ...
        read_downsample_geotiff( ...
            product_file, ...
            plot_factor);

    %% Validate sampled grid

    if ~isequal(size(Aplot),size(MASKplot))

        error( ...
            "Grid mismatch for %s massif %s.", ...
            product, ...
            massif_string)

    end

    %% Apply massif mask

    Aplot(~MASKplot) = NaN;

    %% Product visualization

    [cmap,theoretical_clim,label] = ...
        get_topography_colormap(product);

    ax = nexttile;

    hold(ax,"on")
    box(ax,"on")

    set(ax, ...
        "Color","white", ...
        "XColor","k", ...
        "YColor","k");

    %% Coordinates

    [x,y] = worldGrid(Rplot);

    %% Plot

    h = surface( ...
        ax, ...
        x, ...
        y, ...
        zeros(size(Aplot)), ...
        double(Aplot), ...
        "EdgeColor","none");

    h.AlphaData = ~isnan(Aplot);
    h.FaceAlpha = "flat";
    h.AlphaDataMapping = "none";

    %% Colormap

    colormap(ax,cmap)

    %% Bounds

    field = matlab.lang.makeValidName(product);

    clim_product = theoretical_clim;

    if isfield(bounds,field)

        candidate = bounds.(field);

        if isnumeric(candidate) && ...
                numel(candidate) == 2 && ...
                all(isfinite(candidate)) && ...
                candidate(1) < candidate(2)

            clim_product = double(candidate(:))';

        end

    end

    clim(ax,clim_product)

    %% Axes

    axis(ax,"image")

    xlim(ax,Rplot.XWorldLimits)
    ylim(ax,Rplot.YWorldLimits)

    %% Labels

    title( ...
        ax, ...
        strrep(product,"_","\_"), ...
        "Interpreter","tex")

    xlabel(ax,"Easting (m)")
    ylabel(ax,"Northing (m)")

    %% Colorbar

    cb = colorbar(ax);

    cb.Label.String = label;

    %% Cleanup current product

    clear Aplot Rplot x y h cb
    clear cmap theoretical_clim label
    clear field candidate clim_product

end

%% ========================================================================
% Overall title
% ========================================================================

sgtitle( ...
    sprintf( ...
        "LiDAR HD topography — SAFRAN massif %s", ...
        massif_string), ...
    "FontWeight","bold");

%% ========================================================================
% Save
% ========================================================================

outfile = fullfile( ...
    diagnostics_folder, ...
    sprintf( ...
        "LiDAR_HD_massif_%s_topography.png", ...
        massif_string));

fig.Visible = "off";

exportgraphics( ...
    fig, ...
    outfile, ...
    "Resolution",200);

fprintf( ...
    "Saved %s\n", ...
    outfile)

close(fig)

end