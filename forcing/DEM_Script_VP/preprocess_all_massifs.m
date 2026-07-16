function preprocess_all_massifs(dem_folder, shapefile_folder)
%PREPROCESS_ALL_MASSIFS Build IGN DEMs for all SAFRAN massifs.
%
% INPUT
%   dem_folder
%       Root DEM folder.
% 
%   shapefile_folder
%       Folder where the SAFRAN shapefile is located
% 
% Automatically resumes interrupted processing.
%

%% Paths
tile_index_file = fullfile(dem_folder,"tile_index.mat");
massif_file = fullfile(shapefile_folder,"massifs_alpes_2154.shp");

output_folder = fullfile(dem_folder,"massif");
plot_folder = fullfile(dem_folder,"plots");


if ~exist(output_folder,"dir")
    mkdir(output_folder)
end

if ~exist(plot_folder,"dir")
    mkdir(plot_folder)
end


%% Load/build tile index

if exist(tile_index_file,"file")
    fprintf("Loading tile index\n")
    load(tile_index_file,"TILES")
else
    fprintf("Building tile index\n")
    TILES = build_dem_tile_index(dem_folder);
end


%% Load massifs

MASSIFS = shaperead(massif_file);
fprintf("\nProcessing %d massifs\n\n",numel(MASSIFS))


plot_dem_tiles_safran_massif_shapes(dem_folder,shapefile_folder,plot_folder)

%% Loop

for k = 1:numel(MASSIFS)

    massif_num  = MASSIFS(k).massif_num;
    massif_name = MASSIFS(k).nom;

    outfile = fullfile(output_folder,sprintf("massif_%02d.mat",massif_num));
    rawfile = fullfile(output_folder,sprintf("massif_%02d_raw.mat",massif_num));
    plotfile = fullfile(plot_folder,sprintf("massif_%02d.png",massif_num));
    slopeplotfile  = fullfile(plot_folder,sprintf("massif_%02d_slope.png",massif_num));
    aspectplotfile = fullfile(plot_folder,sprintf("massif_%02d_aspect.png",massif_num));

    fprintf("\n====================\n")
    fprintf("Massif index : %02d/%02d\n",k,numel(MASSIFS))
    fprintf("Massif number: %02d\n",massif_num)
    fprintf("Massif name  : %s\n",massif_name)
    fprintf("====================\n")

    % Step 1: raw mosaic checkpoint
    if ~exist(rawfile,"file")
        fprintf("Selecting DEM tiles\n")
        tiles = find_massif_tiles(TILES,MASSIFS(k));
        fprintf("%d tiles selected\n",height(tiles))
        fprintf("Reading DEM tiles\n")
        [Z,R] = read_dem_tiles(tiles);

        RAW.Z = Z;
        RAW.R = R;
        RAW.tiles = tiles;
        RAW.massif_num = massif_num;
        RAW.massif_name = massif_name;
        RAW.creation_date = datetime;

        % Save checkpoint immediately
        save(rawfile,"RAW","-v7.3")
        fprintf("Saved raw mosaic checkpoint\n")
    end

    % Step 2: clipping and saving
    if ~exist(outfile,"file")
        fprintf("Clipping to massif polygon\n")
        fprintf("Loading existing raw mosaic\n")
        load(rawfile,"RAW");
        Z = RAW.Z;
        R = RAW.R;

        [Z,R] = clip_dem_to_massif(Z,R,MASSIFS(k));

        DEM.Z = Z;
        DEM.R = R;

        DEM.massif_num = massif_num;
        DEM.massif_name = massif_name;
        DEM.creation_date = datetime;
        DEM.source = "IGN RGE ALTI 5m";
        DEM.tiles = RAW.tiles(:,["filename","xmin","ymin"]);
        DEM.crs = "EPSG:2154";

        save(outfile,"DEM","-v7.3")
        fprintf("Saved intermediate DEM\n")
    end

    % Step 3: compute DEM metrics
    if exist(outfile,"file")
        fprintf("Loading existing clipped file\n")
        load(outfile,"DEM");

        required_fields = ["slope_deg"; "aspect_deg"];

        if all(isfield(DEM,required_fields))
            fprintf("DEM metrics already present -> skipping\n")
        else
            fprintf("Computing DEM metrics\n")
            DEM = compute_dem_metrics(DEM);
            save(outfile,"DEM","-v7.3")
            fprintf("Saved final DEM (with computed DEM metrics)\n")
        end
    end

    % Step 4: preview
    if ~(exist(plotfile,"file") && ...
            exist(slopeplotfile,"file") && ...
            exist(aspectplotfile,"file"))
        fprintf("Producing preview plot\n")
        fprintf("Loading existing clipped file\n")
        load(outfile,"DEM");
        if ~exist(plotfile,"file")
            plot_dem_preview(DEM,MASSIFS(k),plotfile);
        end
        if ~exist(slopeplotfile,"file")
            plot_dem_preview(DEM,MASSIFS(k),slopeplotfile,"slope");
        end
        if ~exist(aspectplotfile,"file")
            plot_dem_preview(DEM,MASSIFS(k),aspectplotfile,"aspect");
        end
    end

end

% Step 5: preview (all massifs at one)
allplotfile = fullfile(plot_folder,"all_massif_dems.png");
if ~exist(allplotfile,"file")
    fprintf("Plot all massif DEMs together for quality control\n")
    plot_all_massif_dems(dem_folder, shapefile_folder, allplotfile);
end


fprintf("\nDONE\n")

end
