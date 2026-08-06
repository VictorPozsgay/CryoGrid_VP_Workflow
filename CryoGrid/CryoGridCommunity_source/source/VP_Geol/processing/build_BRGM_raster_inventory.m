function build_BRGM_raster_inventory(geology_path)
%BUILD_BRGM_RASTER_INVENTORY Build inventory of geological units present
%in CryoGrid BRGM raster products.
%
% BUILD_BRGM_RASTER_INVENTORY(GEOLOGY_PATH) creates a reduced geological
% inventory containing only BRGM geological units that are actually present
% in GEOLOGY_massif_XX.tif raster products.
%
% The original BRGM inventory is preserved. The new inventory is a derived
% product for CryoGrid applications.
%
% Output:
%
%   processed/BRGM_GEO050K_HARM_raster_inventory.mat
%
% containing:
%
%   GEOLOGY_RASTER
%
%       ID_original
%           Original BRGM inventory ID.
%
%       ID_local
%           Compact sequential ID (1:N).
%
%       NOTATION
%           BRGM geological notation.
%
%       DESCR
%           Geological descriptions.
%
%       NPOLYGONS
%           Number of source BRGM polygons.
%
%       AREA_m2
%           Total mapped polygon area.
%
% Notes:
%
%   Geological units present only outside the CryoGrid DEM domain are not
%   included.
%
% Example:
%
%   build_BRGM_raster_inventory(geology_path)
%

%% Paths

processed_path = fullfile(geology_path,"processed");
inventory_file = fullfile(processed_path, ...
    "BRGM_GEO050K_HARM_inventory.mat");
raster_folder  = fullfile(processed_path,"raster");

output_file = fullfile(processed_path, ...
    "BRGM_GEO050K_HARM_raster_inventory.mat");

%% Restart check

if isfile(output_file)
    fprintf("\nRaster inventory already exists:\n%s\n", ...
        output_file)
    fprintf("Skipping.\n")
    return
end


%% Load full inventory

fprintf("\nLoading geological inventory\n")
fprintf("---------------------------\n")

load(inventory_file,"GEOLOGY")
fprintf("Inventory units: %d\n",numel(GEOLOGY.ID))

%% Find rasterized IDs

fprintf("\nScanning geology rasters\n")
fprintf("-----------------------\n")

files = dir(fullfile(raster_folder,"GEOLOGY_massif_*.tif"));

if isempty(files)
    error("No geology rasters found.")
end

used_ids = [];

for i = 1:numel(files)
    fprintf("%s\n",files(i).name)
    G = readgeoraster(fullfile( ...
        files(i).folder,...
        files(i).name));

    ids = unique(G(G>0));
    used_ids = [used_ids; ids];
end

used_ids = unique(used_ids);
fprintf("\nRasterized geological units: %d\n", ...
    numel(used_ids))


%% Build reduced inventory

fprintf("\nBuilding reduced inventory\n")
fprintf("-------------------------\n")

[tf,loc] = ismember(used_ids,GEOLOGY.ID);

if ~all(tf)
    error("Some raster IDs are missing from inventory.")
end

GEOLOGY_RASTER = struct();
GEOLOGY_RASTER.ID_original = used_ids;
GEOLOGY_RASTER.ID_local = (1:numel(used_ids))';
GEOLOGY_RASTER.NOTATION = GEOLOGY.NOTATION(loc);
GEOLOGY_RASTER.DESCR = GEOLOGY.DESCR(loc);
GEOLOGY_RASTER.NPOLYGONS = GEOLOGY.NPOLYGONS(loc);
GEOLOGY_RASTER.AREA_m2 = GEOLOGY.AREA_m2(loc);

%% Metadata

GEOLOGY_RASTER.source = ...
    "BRGM GEO050K_HARM raster-domain inventory";
GEOLOGY_RASTER.definition = ...
    "Subset of BRGM geological units represented in CryoGrid DEM rasters";

%% Save

fprintf("\nSaving reduced inventory\n")
fprintf("-----------------------\n")

save(output_file,"GEOLOGY_RASTER","-v7.3")

fprintf("Saved:\n%s\n",output_file)

fprintf("\n================================================\n")
fprintf("Completed\n")
fprintf("Raster units: %d\n",numel(used_ids))
fprintf("================================================\n")

end