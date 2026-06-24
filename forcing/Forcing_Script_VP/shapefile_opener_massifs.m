shapefile_path = "..\..\forcing\Forcing_Data\meteo\safran\massifs_alpes_2154.shp";
lat = 45.832680732450456;
lon = 6.864715384539419;

% lat = 44.92055267330358;
% lon = 6.263247068209718;

[massif_id, massif_name] = get_safran_massif(shapefile_path, lat, lon);
