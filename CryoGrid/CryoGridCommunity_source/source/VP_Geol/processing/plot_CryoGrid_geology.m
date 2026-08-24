function plot_CryoGrid_geology(brgm_path)
%PLOT_CRYOGRID_GEOLOGY Plot and save CryoGrid geology classes.
%
%   PLOT_CRYOGRID_GEOLOGY(BRGM_PATH) reads the converted CryoGrid geology
%   rasters from:
%
%       fullfile(brgm_path,"processed","raster_CryoGrid")
%
%   and saves one PNG map per massif in:
%
%       fullfile(brgm_path,"processed","plots")
%
%   Every 5th pixel is plotted in both directions. Only one figure is
%   open at a time and is closed immediately after saving.
%
%   Existing plots are skipped. If all expected plots already exist,
%   the function returns immediately without reading any raster.
%
%   CryoGrid codes:
%
%       0       UNKNOWN
%       1       BEDROCK
%       2       SEDIMENT
%       3       TILL
%       4       SCREE
%       5       ICE
%       6       ORGANIC
%       7       WATER
%       -9999   NoData
%
% =========================================================================

%% Paths

processed_path = fullfile(brgm_path,"processed");
raster_path    = fullfile(processed_path,"raster_CryoGrid");
plots_path     = fullfile(processed_path,"plots");

if ~isfolder(raster_path)
    error("CryoGrid raster directory not found: %s",raster_path);
end

files = dir(fullfile(raster_path,"GEOLOGY_massif_*.tif"));

if isempty(files)
    error("No CryoGrid geology rasters found in: %s",raster_path);
end

if ~isfolder(plots_path)
    mkdir(plots_path);
end

%% Check existing outputs

output_files = fullfile( ...
    plots_path, ...
    replace(string({files.name}),".tif",".png"));

output_exists = isfile(output_files);

if all(output_exists)

    fprintf("\n");
    fprintf("============================================================\n");
    fprintf("CRYOGRID GEOLOGY PLOTS ALREADY EXIST\n");
    fprintf("============================================================\n");
    fprintf("Plots found : %d / %d\n",numel(files),numel(files));
    fprintf("Output directory:\n%s\n",plots_path);

    return

end

%% Plotting options

subsample = 5;

%% CryoGrid classes

codes = 0:7;

class_names = [ ...
    "UNKNOWN"
    "BEDROCK"
    "SEDIMENT"
    "TILL"
    "SCREE"
    "ICE"
    "ORGANIC"
    "WATER"];

class_colors = [ ...
    0.75 0.75 0.75   % UNKNOWN
    0.45 0.25 0.10   % BEDROCK
    0.80 0.65 0.45   % SEDIMENT
    0.65 0.45 0.25   % TILL
    0.90 0.90 0.90   % SCREE
    0.40 0.75 1.00   % ICE
    0.20 0.60 0.20   % ORGANIC
    0.10 0.35 0.80]; % WATER

%% Process one massif at a time

for k = 1:numel(files)

    filename = fullfile(files(k).folder,files(k).name);
    output_file = output_files(k);

    %% Skip existing plot

    if isfile(output_file)

        fprintf( ...
            "Massif %d / %d - already exists, skipping\n", ...
            k,numel(files));

        continue

    end

    fprintf( ...
        "Massif %d / %d\n", ...
        k,numel(files));

    %% Read raster

    [A,R] = readgeoraster(filename);

    A = double(A);
    original_size = size(A);

    %% Subsample

    rows = 1:subsample:original_size(1);
    cols = 1:subsample:original_size(2);

    A_plot = A(rows,cols);
    plot_size = size(A_plot);

    %% Build matching spatial reference

    R_plot = maprefcells( ...
        R.XWorldLimits, ...
        R.YWorldLimits, ...
        plot_size, ...
        "ColumnsStartFrom",R.ColumnsStartFrom, ...
        "RowsStartFrom",R.RowsStartFrom);

    %% Remove NoData and unexpected values

    valid = A_plot ~= -9999;

    unexpected = valid & ~ismember(A_plot,codes);

    if any(unexpected(:))

        warning( ...
            "%s contains unexpected CryoGrid codes: %s", ...
            files(k).name, ...
            mat2str(unique(A_plot(unexpected))'));

        A_plot(unexpected) = NaN;

    end

    A_plot(~valid) = NaN;

    %% Create figure

    fig = figure( ...
        "Visible","off", ...
        "Color","w", ...
        "Name",erase(files(k).name,".tif"));

    ax = axes(fig);

    mapshow( ...
        A_plot, ...
        R_plot, ...
        "DisplayType","texturemap");

    axis image
    axis tight

    xlabel("Easting (m)");
    ylabel("Northing (m)");

    colormap(ax,class_colors);
    clim([-0.5 7.5]);

    %% Title

    massif_number = regexp( ...
        files(k).name, ...
        "\d+", ...
        "match", ...
        "once");

    title( ...
        sprintf("CryoGrid geology — Massif %s",massif_number), ...
        "Interpreter","none");

    %% Colorbar

    cb = colorbar;

    cb.Ticks = codes;
    cb.TickLabels = class_names;
    cb.Label.String = "CryoGrid geology class";

    %% Save

    exportgraphics( ...
        fig, ...
        output_file, ...
        "Resolution",150);

    %% Close immediately

    close(fig);

end

%% Summary

fprintf("\n");
fprintf("============================================================\n");
fprintf("CRYOGRID GEOLOGY PLOTS COMPLETED\n");
fprintf("============================================================\n");
fprintf("Rasters found : %d\n",numel(files));
fprintf("Plots created : %d\n",nnz(~output_exists));
fprintf("Plots skipped : %d\n",nnz(output_exists));
fprintf( ...
    "Subsampling   : every %d pixels in both directions\n", ...
    subsample);
fprintf("Output directory:\n%s\n",plots_path);

end