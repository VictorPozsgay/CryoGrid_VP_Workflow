function rasterize_BRGM_geology(geology_path,dem_folder)
%RASTERIZE_BRGM_GEOLOGY Rasterize BRGM geology onto DEM grids.
%
% Rasterizes BRGM GEO050K_HARM geological polygons onto each DEM massif
% grid. The output grid contains GEOLOGY.ID values corresponding to the
% geological inventory.
%
% Input:
%
% geology_path
%     Path to:
%     geology/BRGM_GEO050K_HARM
%
% dem_folder
%     Folder containing:
%     DEM_massif_XX.tif
%
% Output:
%
% processed/raster/
%     GEOLOGY_massif_XX.tif
%
% Values:
%
%     1:N     BRGM geology inventory ID
%     -9999   No geological assignment
%
% A restart log is maintained:
%
%     processed/raster/rasterization_log.mat
%
%
% Example:
%
% rasterize_BRGM_geology(geology_path,dem_folder)
%
% Notes
% -----
% Rasterization is performed only over available DEM massifs. Geological
% units outside these DEM domains are ignored and remain present only in
% the inventory.
%
% The output rasters use the inventory IDs as integer classes:
%
%   >0       BRGM geological unit ID
%   -9999    NoData / no geological assignment
%
% Not all inventory units are necessarily represented in every raster.
%
%

%% Paths

processed_path = fullfile(geology_path,"processed");
output_folder  = fullfile(processed_path,"raster");

if ~isfolder(output_folder)
    mkdir(output_folder)
end

log_file = fullfile(output_folder,"rasterization_log.mat");

if isfile(log_file)
    fprintf("\nGeology rasterization already completed.\n")
    fprintf("Skipping.\n")
    return
end


%% Load geology

fprintf("\nLoading BRGM geology\n")
fprintf("--------------------\n")

load(fullfile(processed_path,"BRGM_GEO050K_HARM_ALPES.mat"),"BRGM")
fprintf("Polygons: %d\n",numel(BRGM.X))


%% Load inventory

fprintf("\nLoading geological inventory\n")
fprintf("---------------------------\n")

load(fullfile(processed_path,"BRGM_GEO050K_HARM_inventory.mat"),"GEOLOGY")
fprintf("Units: %d\n",numel(GEOLOGY.ID))


%% Build notation lookup

fprintf("\nBuilding notation lookup\n")
fprintf("-----------------------\n")

notation_to_id = containers.Map( ...
    cellstr(GEOLOGY.NOTATION), ...
    num2cell(GEOLOGY.ID));


%% Find DEMs dynamically

fprintf("\nSearching DEM files\n")
fprintf("-------------------\n")

files = dir(fullfile(dem_folder,"DEM_massif_*.tif"));

if isempty(files)
    error("No DEM_massif_*.tif files found")
end

massif_names = strings(numel(files),1);

for i = 1:numel(files)
    token = regexp(files(i).name,...
        "DEM_massif_(\d+)\.tif",...
        "tokens","once");
    massif_names(i) = string(token{1});
end

fprintf("Massifs found:\n")
disp(massif_names)

%% Load log

if isfile(log_file)
    load(log_file,"LOG")
else
    LOG = struct();
end

%% Process massifs

for m = 1:numel(files)
    massif = massif_names(m);
    output_file = fullfile(output_folder,"GEOLOGY_massif_"+massif+".tif");

    fprintf("\n----------------------------------------\n")
    fprintf("Massif %s\n",massif)
    fprintf("----------------------------------------\n")

    %% Restart

    if isfile(output_file)
        fprintf("Already processed\n")
        continue
    end

    %% Read DEM

    fprintf("Loading DEM\n")
    dem_file = fullfile(dem_folder,files(m).name);
    [Z,R] = readgeoraster(dem_file);
    valid_dem = Z ~= -9999;

    %% Raster grid coordinates

    [X,Y] = worldGrid(R);
    geology = int16(-9999 .* ones(size(Z)));

    %% Select candidate polygons

    fprintf("Selecting polygons\n")
    xmin = R.XWorldLimits(1);
    xmax = R.XWorldLimits(2);
    ymin = R.YWorldLimits(1);
    ymax = R.YWorldLimits(2);
    candidates = find( ...
        BRGM.bounds_xmin <= xmax & ...
        BRGM.bounds_xmax >= xmin & ...
        BRGM.bounds_ymin <= ymax & ...
        BRGM.bounds_ymax >= ymin );

    fprintf("Candidate polygons: %d / %d\n",...
        numel(candidates),...
        numel(BRGM.X))

    %% Rasterize polygons

    tic

    for p = 1:numel(candidates)
        i = candidates(p);
        x = BRGM.X{i};
        y = BRGM.Y{i};
        if isempty(x)
            continue
        end

        %% Polygon bounding box in world coordinates

        valid = ~(isnan(x) | isnan(y));

        xmin_poly = min(x(valid));
        xmax_poly = max(x(valid));
        ymin_poly = min(y(valid));
        ymax_poly = max(y(valid));

        %% Convert polygon bounds to raster coordinates

        [c1,r1] = worldToIntrinsic(R,xmin_poly,ymax_poly);
        [c2,r2] = worldToIntrinsic(R,xmax_poly,ymin_poly);

        col1 = max(1,floor(min(c1,c2)));
        col2 = min(size(Z,2),ceil(max(c1,c2)));

        row1 = max(1,floor(min(r1,r2)));
        row2 = min(size(Z,1),ceil(max(r1,r2)));

        % Polygon does not intersect raster

        if col1 > col2 || row1 > row2
            continue
        end

        %% Local grid

        local_mask = false(row2-row1+1,col2-col1+1);

        %% Split rings

        sep = isnan(x) | isnan(y);
        edges = [0; find(sep(:)); numel(x)+1];

        for r = 1:numel(edges)-1
            ind = edges(r)+1:edges(r+1)-1;
            if numel(ind)<3
                continue
            end
            [c,rw] = worldToIntrinsic( ...
                R,...
                x(ind),...
                y(ind));

            % Convert to local window coordinates

            c = c - col1 + 1;
            rw = rw - row1 + 1;
            ring_mask = poly2mask( ...
                c,...
                rw,...
                size(local_mask,1),...
                size(local_mask,2));
            if r == 1
                % exterior ring
                local_mask = local_mask | ring_mask;
            else
                % holes
                local_mask = local_mask & ~ring_mask;
            end
        end

        %% Write geology ID

        if any(local_mask(:))
            id = notation_to_id(char(BRGM.NOTATION(i)));
            tmp = geology(row1:row2,col1:col2);
            tmp(local_mask) = int16(id);
            geology(row1:row2,col1:col2) = tmp;
        end

        if mod(p,1000)==0
            fprintf("%d/%d polygons (%.1f s)\n",...
                p,numel(candidates),toc)
        end
    end

    %% Preserve DEM no-data

    geology(~valid_dem) = int16(-9999);

    %% Write

    fprintf("Saving raster\n")
    geotiffwrite(output_file,geology,R,"CoordRefSysCode",2154);

    %% Log

    if isempty(LOG) || ~isfield(LOG,"massif")
        k = 1;
    else
        k = numel(LOG.massif) + 1;
    end

    LOG.massif(k) = str2double(massif);
    LOG.n_polygons(k) = numel(candidates);
    LOG.n_assigned(k) = sum(geology(:)~=-9999);
    LOG.n_unclassified(k) = sum(geology(:)==-9999);
    LOG.date{k} = datestr(now);

    save(log_file,"LOG")
    fprintf("Saved:\n%s\n",output_file)

end

fprintf("\n================================================\n")
fprintf("Rasterization completed\n")
fprintf("================================================\n")

end