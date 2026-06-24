function [massif_id, massif_name] = get_safran_massif(shapefile_path, lat, lon)
%GET_SAFRAN_MASSIF  Identify the SAFRAN massif containing a geographic point
%
% This function determines which SAFRAN massif polygon contains a given
% latitude/longitude coordinate.
%
% The input coordinates are assumed to be expressed in geographic
% coordinates (WGS84; EPSG:4326). They are internally projected to
% Lambert-93 (EPSG:2154), which is the native coordinate reference system
% used by SAFRAN massif shapefiles distributed by Météo-France.
%
% For efficiency, the shapefile is loaded only once and stored in memory
% using a persistent variable. Subsequent calls using the same shapefile
% reuse the already loaded polygons.
%
%
% INPUTS
% ------
% shapefile_path  (char|string)
%     Path to the SAFRAN massif shapefile (*.shp).
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
% OVERVIEW
% --------
% 1. Load SAFRAN massif polygons (only once)
% 2. Convert input coordinates from WGS84 to Lambert-93
% 3. Test whether projected point falls inside each polygon
% 4. Return corresponding massif attributes
%
%
% PERFORMANCE
% -----------
% The shapefile is cached in memory using persistent variables.
% If the function is called repeatedly with the same shapefile, disk access
% occurs only during the first call.
%
% If a different shapefile path is provided, the cache is automatically
% refreshed.
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

persistent S_cached cached_path crsL93

% Load shapefile only if necessary
if isempty(S_cached) || ~strcmp(string(shapefile_path), cached_path)

    S_cached = shaperead(shapefile_path);
    cached_path = string(shapefile_path);

    % Create projection object once
    crsL93 = projcrs(2154);

end

% Convert WGS84 coordinates to Lambert-93
[x, y] = projfwd(crsL93, lat, lon);

% Default outputs
massif_id = NaN;
massif_name = "";

% Search containing polygon
for k = 1:length(S_cached)

    in = inpolygon(x, y, ...
                   S_cached(k).X, ...
                   S_cached(k).Y);

    if in
        massif_id = S_cached(k).massif_num;
        massif_name = string(S_cached(k).nom);
        return
    end

end

end
