function S = safran_massif_to_coord(safran_path)
%SAFRAN_MASSIF_TO_COORD  Identify the SAFRAN massifs and their lat/lon
% coordinates
%
% This function draws a list of all Alpine SAFRAN massifs and gets their
% lat/lon coordinates from SAFRAN
%
% The input coordinates are assumed to be expressed in geographic
% coordinates (WGS84; EPSG:4326).
%
%
% INPUTS
% ------
% safran_path     (char|string)
%     Path to the SAFRAN folder, where a shapefile/ subfolder containing
%     the massif shapefile (*.shp) are located
%
%
% OUTPUTS
% -------
% S (struct)
%     structure with a list of SAFRAN massifs and their coordinates
%
%
% ASSUMPTIONS
% -----------
% - Input coordinates are expressed in WGS84 geographic coordinates
%   (latitude/longitude in decimal degrees).
% - The shapefile contains attributes named:
%       'massif_num'
%       'nom'
% - The SAFRAN data files are contained in the same folder as the shapefile
%

shapefile_path = fullfile(safran_path, "shapefile\", "massifs_alpes_2154.shp");


% !!!!!!!!!!!!! NEED TO CONVERT TO WGS84 !!!!!!!!!!
SIn = shaperead(shapefile_path);
SIn = rmfield(SIn,{'Geometry', 'BoundingBox', 'superficie', 'perimetre'});

folder_safran_raw = fullfile(safran_path, "raw\");
files = dir(fullfile(folder_safran_raw, "*.nc"));
if isempty(files)
    error("*.nc file found in %s", folder_safran_raw);
end
forcing_file = fullfile(files(1).folder, files(1).name);

massif_num = ncread(forcing_file,'massif_number');
lon = ncread(forcing_file,'LON');
lat = ncread(forcing_file,'LAT');

T1 = unique(table(massif_num, lat, lon));

T2 = struct2table(SIn);

T = innerjoin(T1, T2, 'Keys', 'massif_num');
T = sortrows(T,"massif_num");

S = table2struct(T);

% Convert every polygon from Lambert-93 to WGS84
crsL93 = projcrs(2154);
for k = 1:numel(S)

    valid = ~isnan(S(k).X) & ~isnan(S(k).Y);

    lon_poly = nan(size(S(k).X));
    lat_poly = nan(size(S(k).Y));

    [lat_poly(valid), lon_poly(valid)] = ...
        projinv(crsL93, ...
                S(k).X(valid), ...
                S(k).Y(valid));

    S(k).Lon = lon_poly;
    S(k).Lat = lat_poly;

end

end

