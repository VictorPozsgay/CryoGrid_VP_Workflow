function run_lidar_diagnostics(dem_folder,safran_shp,save_folder)
%RUN_LIDAR_DIAGNOSTICS Run LiDAR DEM QC.
%
% Creates:
%   - DEM overview PNG
%   - missing pixel PNG
%   - validation CSV


if ~exist(save_folder,"dir")
    mkdir(save_folder)
end



%% DEM overview

fprintf("\nCreating DEM overview...\n")


OUT = plot_all_lidar_massifs( ...
    dem_folder,...
    safran_shp,...
    save_folder);



%% Missing pixels

fprintf("\nCreating missing pixel plot...\n")


plot_lidar_missing_pixels( ...
    OUT,...
    save_folder);



%% Validation

fprintf("\nCreating validation table...\n")


T = validate_lidar_dem(dem_folder);


disp(T)


outfile = fullfile( ...
    save_folder,...
    "LiDAR_HD_DEM_validation.csv");


writetable(T,outfile)

fprintf("Saved %s\n",outfile)


%% Close figure

if isvalid(OUT.fig)
    close(OUT.fig)
end

end