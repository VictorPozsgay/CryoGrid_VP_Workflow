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

%% Save Markdown table for GitHub README

mdfile = fullfile(save_folder,"LiDAR_HD_DEM_validation.md");

fid = fopen(mdfile,"w");

fprintf(fid,"| massif | DEM pixels | missing pixels | missing percentage |\n");
fprintf(fid,"|---:|---:|---:|---:|\n");

for i = 1:height(T)
    fprintf(fid,...
        "| %d | %d | %d | %.3f %% |\n",...
        T.massif(i),...
        T.DEM_pixels(i),...
        T.missing_pixels(i),...
        T.missing_percentage(i));
end

fclose(fid);

fprintf("Saved %s\n",mdfile)


%% Close figure

if isvalid(OUT.fig)
    close(OUT.fig)
end

end