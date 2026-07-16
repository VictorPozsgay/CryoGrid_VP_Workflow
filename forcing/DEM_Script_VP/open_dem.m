root_folder = fullfile("..\Forcing_Data\DEM_IGN\raw");
dem_folder = fullfile("..\Forcing_Data\DEM_IGN");
shapefile_folder = fullfile("..\Forcing_Data\meteo\safran\shapefile");

preprocess_all_massifs(dem_folder, shapefile_folder)
