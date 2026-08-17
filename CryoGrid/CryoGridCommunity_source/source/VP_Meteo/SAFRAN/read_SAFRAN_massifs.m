function S = read_SAFRAN_massifs(safran_path)
%READ_SAFRAN_MASSIFS Read SAFRAN massif polygons and centroid coordinates.
%
% DESCRIPTION
%   Reads the SAFRAN massif shapefile together with one SAFRAN NetCDF file
%   to build a structure containing:
%
%       • massif identifier
%       • massif name
%       • polygon coordinates in Lambert-93
%       • polygon coordinates in WGS84
%       • SAFRAN forcing point coordinates (centroid)
%
%   The shapefile provides the massif polygons, while the SAFRAN NetCDF
%   file provides the centroid coordinates associated with each massif.
%   Polygon coordinates are converted from Lambert-93 (EPSG:2154) to
%   geographic coordinates (WGS84).
%
% INPUT
%   safran_path
%       Path to:
%
%           SAFRAN/
%
%       containing:
%
%           raw/
%           shapefile/
%
% OUTPUT
%   S
%       Structure array with one element per SAFRAN massif containing:
%
%           massif_num     Massif identifier
%           nom            Massif name
%           X              Polygon X coordinates (Lambert-93)
%           Y              Polygon Y coordinates (Lambert-93)
%           Lon            Polygon longitude (WGS84)
%           Lat            Polygon latitude (WGS84)
%           lon            SAFRAN centroid longitude
%           lat            SAFRAN centroid latitude
%
% SEE ALSO
%   BUILD_SAFRAN_PER_MASSIF.

%% ------------------------------------------------------------------------
% Paths
% -------------------------------------------------------------------------

shapefile_path = fullfile( ...
    safran_path, ...
    "shapefile", ...
    "massifs_alpes_2154.shp");

if ~isfile(shapefile_path)
    error("SAFRAN shapefile not found:%s%s", newline, shapefile_path)
end

raw_path = fullfile(safran_path,"raw");

files = dir(fullfile(raw_path,"*.nc"));
if isempty(files)
    files = dir(fullfile(raw_path,"*.NC"));
end

if isempty(files)
    error("No SAFRAN NetCDF files found in %s.", raw_path)
end

forcing_file = fullfile(files(1).folder, files(1).name);

%% ------------------------------------------------------------------------
% Read massif polygons
% -------------------------------------------------------------------------

Sshape = shaperead(shapefile_path);

% Keep only useful fields
remove_fields = intersect( ...
    {'Geometry','BoundingBox','superficie','perimetre'}, ...
    fieldnames(Sshape));

if ~isempty(remove_fields)
    Sshape = rmfield(Sshape, remove_fields);
end

%% ------------------------------------------------------------------------
% Read SAFRAN centroid coordinates
% -------------------------------------------------------------------------

massif_num = ncread(forcing_file,'massif_number');
lon = ncread(forcing_file,'LON');
lat = ncread(forcing_file,'LAT');

Tcoord = unique(table(massif_num,lat,lon));

%% ------------------------------------------------------------------------
% Merge polygons and coordinates
% -------------------------------------------------------------------------

Tshape = struct2table(Sshape);

T = innerjoin(Tcoord, Tshape, 'Keys',"massif_num");
T = sortrows(T,"massif_num");

S = table2struct(T);

%% ------------------------------------------------------------------------
% Convert polygons from Lambert-93 to WGS84
% -------------------------------------------------------------------------

crsL93 = projcrs(2154);

for k = 1:numel(S)

    valid = ~isnan(S(k).X) & ~isnan(S(k).Y);

    Lon = nan(size(S(k).X));
    Lat = nan(size(S(k).Y));

    [Lat(valid), Lon(valid)] = projinv( ...
        crsL93, ...
        S(k).X(valid), ...
        S(k).Y(valid));

    S(k).Lon = Lon;
    S(k).Lat = Lat;

end

end