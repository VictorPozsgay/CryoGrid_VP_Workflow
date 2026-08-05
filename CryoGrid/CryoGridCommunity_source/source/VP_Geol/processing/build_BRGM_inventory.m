function build_BRGM_inventory(forcing_path)
%BUILD_BRGM_INVENTORY Build BRGM geological unit inventory.
%
% BUILD_BRGM_INVENTORY(FORCING_PATH) creates a geological inventory from
% the merged BRGM GEO050K_HARM Alpine dataset.
%
% Geological units are defined by NOTATION. CODE_LEG is intentionally not
% used because it is not a stable identifier across departments.
%
% The inventory contains:
%
%   ID
%       Integer identifier assigned by alphabetical order of NOTATION.
%
%   NOTATION
%       Geological unit notation used by BRGM.
%
%   NPOLYGONS
%       Number of polygons associated with the notation.
%
%   AREA_m2
%       Total mapped polygon area.
%
%   DESCR
%       Cell array containing all unique descriptions associated with the
%       notation.
%
% Input:
%   forcing_path
%       Path to CryoGridCommunity_forcing/geology/BRGM_GEO050K_HARM
%
% Output:
%   Creates:
%
%   processed/BRGM_GEO050K_HARM_inventory.mat
%
%   containing:
%
%       GEOLOGY structure
%
% Example:
%
%   build_BRGM_inventory(forcing_path)
%
% Notes
% -----
% The inventory is built from the complete merged BRGM GEO050K_HARM
% dataset covering the selected departments. It therefore contains all
% geological units present in these departments, including units located
% outside the final CryoGrid DEM domain.
%
% Consequently, some inventory units may not appear in the rasterized
% geology products because the DEMs only cover the selected SAFRAN massifs
% in the Alpine domain.
%
% The inventory is kept unchanged as the master geological lookup table.
% Raster products reference these IDs directly; unused IDs are not removed
% or renumbered.
%
%


%% Paths

processed_path = fullfile(forcing_path,"processed");

input_file = fullfile(processed_path,"BRGM_GEO050K_HARM_ALPES.mat");
output_file = fullfile(processed_path,"BRGM_GEO050K_HARM_inventory.mat");


%% Restart check

if isfile(output_file)
    fprintf("Inventory already exists:\n%s\n",output_file)
    fprintf("Skipping.\n")
    return
end

%% Load merged geology

fprintf("\nLoading merged geology\n")
fprintf("---------------------\n")
load(input_file,"BRGM")
fprintf("Polygons: %d\n",numel(BRGM.X))

%% Precompute polygon areas

fprintf("\nComputing polygon areas\n")
fprintf("-----------------------\n")
npoly = numel(BRGM.X);
poly_area = zeros(npoly,1);
tic

for p = 1:npoly

    poly_area(p) = polygon_area_nan(BRGM.X{p},BRGM.Y{p});
    if mod(p,10000)==0
        fprintf("%d/%d polygons\n",p,npoly)
    end
end

fprintf("Completed in %.1f s\n",toc)

%% Sort unique geological units alphabetically

fprintf("\nBuilding notation index\n")
fprintf("----------------------\n")

notations = sort(unique(BRGM.NOTATION));
N = numel(notations);

fprintf("Unique geological units: %d\n",N)

%% Allocate inventory

GEOLOGY = struct();
GEOLOGY.ID = (1:N)';
GEOLOGY.NOTATION = notations;
GEOLOGY.NPOLYGONS = zeros(N,1);
GEOLOGY.AREA_m2 = zeros(N,1);
GEOLOGY.DESCR = cell(N,1);

%% Populate inventory

fprintf("\nComputing statistics\n")
fprintf("--------------------\n")


for i = 1:N
    notation = notations(i);
    idx = BRGM.NOTATION == notation;
    GEOLOGY.NPOLYGONS(i) = sum(idx);
    GEOLOGY.AREA_m2(i) = sum(poly_area(idx));
    GEOLOGY.DESCR{i} = cellstr(unique(BRGM.DESCR(idx)));
end

%% Metadata

GEOLOGY.source = ...
    "BRGM GEO050K_HARM S_FGEOL harmonized geological formations";
GEOLOGY.definition = "Geological units defined by BRGM NOTATION";

%% Save

fprintf("\nSaving inventory\n")
fprintf("----------------\n")

save(output_file,"GEOLOGY","-v7.3")

fprintf("Saved:\n%s\n",output_file)
fprintf("\n================================================\n")
fprintf("Inventory completed\n")
fprintf("Units: %d\n",N)
fprintf("================================================\n")

end