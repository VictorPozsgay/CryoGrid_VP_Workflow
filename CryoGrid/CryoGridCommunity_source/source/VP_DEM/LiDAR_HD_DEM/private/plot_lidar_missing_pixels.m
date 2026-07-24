function plot_lidar_missing_pixels(OUT,save_folder)
%PLOT_LIDAR_MISSING_PIXELS Plot missing LiDAR pixels.
%
% Uses the DEM overview figure created by plot_lidar_dem_base().
%
% Missing pixels are defined as:
%   inside massif mask AND DEM pixel is NaN
%
% INPUT
%
% OUT
%   Output structure from plot_lidar_dem_base()
%
% save_folder
%   Folder for output PNG


%% Parameters

point_factor = 5;



%% Use existing figure

axes(OUT.ax)

hold on


%% Find missing pixels

missing_all = [];


for k = 1:numel(OUT.DEM)


    Z = OUT.DEM{k};
    R = OUT.R{k};


    %% Corresponding mask
    
    token = regexp( ...
        OUT.files(k).name,...
        'DEM_massif_(\d+)',...
        'tokens');
    
    
    id = str2double(token{1}{1});
    
    
    maskfile = fullfile( ...
        OUT.files(k).folder,...
        sprintf("DEM_mask_massif_%02d.tif",id));
    
    
    if ~exist(maskfile,"file")
        error("Missing mask file: %s",maskfile)
    end
    
    
    [mask,~] = readgeoraster(maskfile);
    
    mask = logical(mask);



    %% Missing pixels inside polygon

    missing = mask & isnan(Z);



    fprintf("Massif %02d: %d missing pixels\n",...
        id,...
        nnz(missing))



    %% Coordinates

    [row,col] = find(missing);


    if isempty(row)
        continue
    end


    [x,y] = intrinsicToWorld( ...
        R,...
        col,...
        row);


    missing_all = [missing_all; x y];


end



fprintf("Total missing pixels: %d\n",...
    size(missing_all,1))



%% Plot red dots

if ~isempty(missing_all)


    keep = 1:point_factor:size(missing_all,1);


    scatter( ...
        missing_all(keep,1),...
        missing_all(keep,2),...
        20,...
        "r",...
        "filled")


end



title("LiDAR-HD DEMs - missing pixels")



%% Save

outfile = fullfile( ...
    save_folder,...
    "LiDAR_HD_DEM_missing_pixels.png");

OUT.fig.Visible = "off";

exportgraphics( ...
    OUT.fig,...
    outfile,...
    "Resolution",300);


fprintf("Saved %s\n",outfile)



end