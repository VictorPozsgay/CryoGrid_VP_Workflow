function GEO = read_BRGM_geology(filename)
%READ_BRGM_GEOLOGY Read a BRGM GEO050K_HARM surface geology shapefile.
%
%   GEO = READ_BRGM_GEOLOGY(filename)
%
%   Reads a BRGM GEO050K_HARM S_FGEOL shapefile and extracts the fields
%   required for subsequent processing onto a DEM grid.
%
%   Input
%   -----
%   filename : string
%       Path to a GEO050K_HARM_xxx_S_FGEOL_2154.shp file.
%
%   Output
%   ------
%   GEO : structure
%       Clean geological dataset containing:
%
%       GEO.Shape
%           Polygon geometry.
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
%       GEO.CRS
%           Coordinate reference system information.
%
%   Notes
%   -----
%   The BRGM data are provided in Lambert-93 (EPSG:2154).
%   This function does not modify geometries or merge geological units.
%
%   Example
%   -------
%       GEO = read_BRGM_geology( ...
%           "GEO050K_HARM_073_S_FGEOL_2154.shp");
%

%% Check input

if ~isfile(filename)
    error("File not found: %s", filename)
end

%% Read shapefile

T = readgeotable(filename);


%% Keep only useful fields

required_fields = ["Shape","CODE_LEG","NOTATION","DESCR"];

missing = setdiff(required_fields, string(T.Properties.VariableNames));

if ~isempty(missing)
    error("Missing fields: %s", strjoin(missing,", "))
end


T = T(:,cellstr(required_fields));


%% Standardize text fields

text_fields = ["CODE_LEG","NOTATION","DESCR"];

for i = 1:numel(text_fields)

    f = text_fields(i);

    if iscell(T.(f))
        T.(f) = string(T.(f));
    else
        T.(f) = string(T.(f));
    end

end


%% Store output

GEO = struct();

GEO.Shape    = T.Shape;
GEO.CODE_LEG = T.CODE_LEG;
GEO.NOTATION = T.NOTATION;
GEO.DESCR    = T.DESCR;


%% CRS information

try
    GEO.CRS = T.Shape.ProjectedCRS;
catch
    GEO.CRS = [];
end


end