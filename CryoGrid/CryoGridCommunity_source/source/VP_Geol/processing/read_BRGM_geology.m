function GEO = read_BRGM_geology(filename)
%READ_BRGM_GEOLOGY Read a BRGM GEO050K_HARM surface geology shapefile.
%
%   GEO = READ_BRGM_GEOLOGY(filename)
%
%   Reads a BRGM GEO050K_HARM S_FGEOL shapefile using SHAPEREAD and stores
%   polygon vertices explicitly for efficient rasterization.
%
%   The previous implementation stored geometries as mappolyshape objects.
%   This version preserves the original polygon coordinates, allowing fast
%   rasterization with poly2mask.
%
%   Input
%   -----
%   filename : string
%       Path to a GEO050K_HARM_xxx_S_FGEOL_2154.shp file.
%
%   Output
%   ------
%   GEO : structure
%
%       GEO.X
%           Cell array containing polygon X coordinates (Lambert-93).
%
%       GEO.Y
%           Cell array containing polygon Y coordinates (Lambert-93).
%
%           Multiple rings and holes are separated by NaN values following
%           the ESRI shapefile convention.
%
%       GEO.CODE_LEG
%           BRGM geological legend code.
%
%       GEO.NOTATION
%           Geological notation.
%
%       GEO.DESCR
%           Geological description.
%
%       GEO.BoundingBox
%           Original polygon bounding boxes.
%
%       GEO.CRS
%           Coordinate reference system information.
%
%   Notes
%   -----
%   The BRGM data are provided in Lambert-93 (EPSG:2154).
%
%   The output is designed for rasterization:
%
%       polygon coordinates
%              |
%              v
%          poly2mask
%              |
%              v
%       geological raster
%

%% Check input

if ~isfile(filename)
    error("File not found: %s",filename)
end


%% Read shapefile

S = shaperead(filename);


%% Check required fields

required_fields = [
    "X"
    "Y"
    "CODE_LEG"
    "NOTATION"
    "DESCR"
];


available = string(fieldnames(S));

missing = setdiff(required_fields,available);

if ~isempty(missing)
    error("Missing fields: %s",strjoin(missing,", "))
end


%% Allocate output

n = numel(S);

GEO = struct();

GEO.X = cell(n,1);
GEO.Y = cell(n,1);

GEO.BoundingBox = cell(n,1);

GEO.CODE_LEG = strings(n,1);
GEO.NOTATION = strings(n,1);
GEO.DESCR = strings(n,1);


%% Copy geometry and attributes

for i = 1:n
    GEO.X{i} = S(i).X;
    GEO.Y{i} = S(i).Y;

    GEO.BoundingBox{i} = S(i).BoundingBox;

    GEO.CODE_LEG(i) = string(S(i).CODE_LEG);
    GEO.NOTATION(i) = string(S(i).NOTATION);
    GEO.DESCR(i) = string(S(i).DESCR);
end


%% CRS

% shaperead does not always store CRS information directly.
% BRGM GEO050K_HARM data are Lambert-93.

try
    GEO.CRS = projcrs(2154);
catch
    GEO.CRS = [];
end


%% Metadata

GEO.source = ...
    "BRGM GEO050K_HARM S_FGEOL harmonized geological formations";

end