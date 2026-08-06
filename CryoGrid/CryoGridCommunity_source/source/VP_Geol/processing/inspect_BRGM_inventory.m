function T = inspect_BRGM_inventory(geology_path)
%INSPECT_BRGM_INVENTORY Display BRGM geological inventory as a table.
%
% Creates a readable summary from BRGM_GEO050K_HARM_inventory.mat
%
% Columns:
%   ID
%   NOTATION
%   NPOLYGONS
%   AREA_km2
%   PERCENT_AREA
%   DESCRIPTION


%% Load inventory

file = fullfile(geology_path,"processed",...
    "BRGM_GEO050K_HARM_inventory.mat");
load(file,"GEOLOGY")

%% Convert descriptions

N = numel(GEOLOGY.ID);
descr = strings(N,1);

for i = 1:N
    descr(i) = strjoin(GEOLOGY.DESCR{i}," | ");
end

%% Compute percentages

area_km2 = GEOLOGY.AREA_m2 / 1e6;
percent_area = 100 * area_km2 / sum(area_km2);

%% Build table

T = table( ...
    GEOLOGY.ID, ...
    GEOLOGY.NOTATION, ...
    GEOLOGY.NPOLYGONS, ...
    area_km2, ...
    percent_area, ...
    descr,...
    'VariableNames', [ ...
    "ID", ...
    "NOTATION", ...
    "NPOLYGONS", ...
    "AREA_km2", ...
    "PERCENT_AREA", ...
    "DESCRIPTION"]);


%% Display

fprintf("\n================================================\n")
fprintf("BRGM geological inventory summary\n")
fprintf("================================================\n\n")

fprintf("Geological units: %d\n",height(T))
fprintf("Total mapped area: %.1f km2\n\n",sum(T.AREA_km2))

% disp(sortrows(T,"AREA_km2","descend"))

end