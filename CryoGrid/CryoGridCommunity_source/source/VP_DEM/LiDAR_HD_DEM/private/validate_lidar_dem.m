function T = validate_lidar_dem(dem_folder)

%VALIDATE_LIDAR_DEM
%
% Create automatic QC table for LiDAR-HD DEM massifs.
%
% Output:
%
% massif
% DEM_pixels
% missing_pixels
% missing_percentage
%


%% Files

files = dir(fullfile( ...
    dem_folder,...
    "DEM_massif_*.tif"));


n = numel(files);


if n==0
    error("No DEM files found")
end



%% Output storage

massif_id = zeros(n,1);
DEM_pixels = zeros(n,1);
missing_pixels = zeros(n,1);


%% Loop

for k = 1:n


    fprintf("Processing %s\n",files(k).name)



    %% ID

    token = regexp( ...
        files(k).name,...
        'DEM_massif_(\d+)',...
        'tokens');

    id = str2double(token{1}{1});

    massif_id(k)=id;



    %% Read DEM

    [Z,~] = readgeoraster( ...
        fullfile(files(k).folder,files(k).name));


    Z = single(Z);



    %% Read mask

    mask_file = fullfile( ...
        dem_folder,...
        sprintf("DEM_mask_massif_%02d.tif",id));


    mask = readgeoraster(mask_file);

    mask = logical(mask);



    %% Missing pixels

    no_data = isnan(Z) | Z<=-9000;


    missing = mask & no_data;



    %% Total

    DEM_pixels(k)=nnz(mask);

    missing_pixels(k)=nnz(missing);


end


%% Table

T = table( ...
    massif_id,...
    DEM_pixels,...
    missing_pixels,...
    100*missing_pixels./DEM_pixels,...
    'VariableNames', { ...
        'massif', ...
        'DEM_pixels', ...
        'missing_pixels', ...
        'missing_percentage' ...
    });



%% Sort

T = sortrows(T,"massif");


end