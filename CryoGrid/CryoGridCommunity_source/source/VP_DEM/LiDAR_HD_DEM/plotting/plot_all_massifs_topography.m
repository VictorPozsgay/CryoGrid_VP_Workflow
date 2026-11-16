function plot_all_massifs_topography(output_path,bounds)
%PLOT_ALL_MASSIFS_TOPOGRAPHY
% Generate one topography overview for every available massif.

if nargin < 2
    bounds = struct();
end

dem_folder = fullfile(output_path,"DEM");

if ~isfolder(dem_folder)
    error("DEM folder not found: %s",dem_folder)
end

%% Discover massifs

files = dir(fullfile(dem_folder,"DEM_massif_*.tif"));

massif_numbers = [];

for i = 1:numel(files)

    tokens = regexp( ...
        files(i).name, ...
        '^DEM_massif_(\d+)\.tif$', ...
        'tokens', ...
        'once');

    if ~isempty(tokens)
        massif_numbers(end+1) = str2double(tokens{1});
    end

end

massif_numbers = sort(unique(massif_numbers));

if isempty(massif_numbers)
    error("No individual massif DEMs found in: %s",dem_folder)
end

fprintf("\nFound %d massifs:\n",numel(massif_numbers))
disp(massif_numbers')

%% Generate figures

for i = 1:numel(massif_numbers)

    massif_number = massif_numbers(i);

    fprintf("\n")
    fprintf("============================================================\n")
    fprintf(" Massif %02d (%d/%d)\n", ...
        massif_number,i,numel(massif_numbers))
    fprintf("============================================================\n")

    plot_massif_topography( ...
        output_path, ...
        massif_number, ...
        bounds, ...
        true);

end

fprintf("\nAll massif visualizations completed.\n")

end
