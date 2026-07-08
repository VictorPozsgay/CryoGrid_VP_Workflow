function [massif_id, massif_name] = get_safran_massif(safran_path, lat, lon)
%GET_SAFRAN_MASSIF  Identify the SAFRAN massif containing a geographic point
%
% This function determines which SAFRAN massif polygon contains a given
% latitude/longitude coordinate.
% 
% Input coordinates are WGS84 (latitude/longitude).
% The SAFRAN polygons (stored in Lambert-93) are converted once to WGS84
% when the shapefile is first loaded.
%
% For efficiency, the shapefile is loaded only once and stored in memory
% using a persistent variable. Subsequent calls using the same shapefile
% reuse the already loaded polygons.
%
%
% INPUTS
% ------
% safran_path     (char|string)
%     Path to the SAFRAN folder, where a shapefile/ subfolder containing
%     the massif shapefile (*.shp) are located
%
% lat             (double)
%     Latitude of the point in decimal degrees (WGS84).
%
% lon             (double)
%     Longitude of the point in decimal degrees (WGS84).
%
%
% OUTPUTS
% -------
% massif_id       (double)
%     SAFRAN massif identifier ('massif_num' attribute).
%
%     Returns NaN if the point does not belong to any polygon.
%
% massif_name     (string)
%     Full SAFRAN massif name ('nom' attribute).
%
%     Returns an empty string if the point does not belong to any polygon.
%
%
% ASSUMPTIONS
% -----------
% - The shapefile geometry is expressed in Lambert-93 (EPSG:2154).
% - Input coordinates are expressed in WGS84 geographic coordinates
%   (latitude/longitude in decimal degrees).
% - The shapefile contains attributes named:
%       'massif_num'
%       'nom'
%
%
% SEE ALSO
% --------
% shaperead, projcrs, projfwd, inpolygon

shapefile_path = fullfile(safran_path,"shapefile","massifs_alpes_2154.shp");

persistent S_cached cached_path

% -------------------------------------------------------------------------
% Load and project shapefile only once
% -------------------------------------------------------------------------
if isempty(S_cached) || ~strcmp(string(shapefile_path), cached_path)

    S_cached = shaperead(shapefile_path);
    cached_path = string(shapefile_path);

    crsL93 = projcrs(2154);

    % Convert every polygon from Lambert-93 to WGS84
    for k = 1:numel(S_cached)

        valid = ~isnan(S_cached(k).X) & ~isnan(S_cached(k).Y);

        lon_poly = nan(size(S_cached(k).X));
        lat_poly = nan(size(S_cached(k).Y));

        [lat_poly(valid), lon_poly(valid)] = ...
            projinv(crsL93, ...
                    S_cached(k).X(valid), ...
                    S_cached(k).Y(valid));

        S_cached(k).Lon = lon_poly;
        S_cached(k).Lat = lat_poly;

    end

end

% -------------------------------------------------------------------------
% Default outputs
% -------------------------------------------------------------------------
massif_id = NaN;
massif_name = "";

% -------------------------------------------------------------------------
% Search containing polygon
% -------------------------------------------------------------------------
for k = 1:numel(S_cached)

    if inpolygon(lon, lat, ...
                 S_cached(k).Lon, ...
                 S_cached(k).Lat)

        massif_id = S_cached(k).massif_num;
        massif_name = string(S_cached(k).nom);
        return

    end

end

end