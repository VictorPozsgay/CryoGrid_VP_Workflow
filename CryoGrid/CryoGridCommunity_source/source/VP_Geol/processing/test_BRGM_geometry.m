function test_BRGM_geometry(GEO)
%TEST_BRGM_GEOMETRY Validate BRGM GEO050K_HARM geology structure.
%
% TEST_BRGM_GEOMETRY(GEO) performs basic quality checks on the structure
% returned by read_BRGM_geology.
%
% Checks:
%   - dataset size
%   - geometry class/type
%   - empty geometries
%   - zero/invalid areas
%   - missing attributes
%   - attribute uniqueness
%
% Input:
%   GEO : structure returned by read_BRGM_geology


fprintf("\n================================================\n")
fprintf("BRGM geometry validation\n")
fprintf("================================================\n")


%% Dataset

fprintf("\nDataset size\n")
fprintf("----------------\n")

N = numel(GEO.Shape);

fprintf("Number of geometries: %d\n",N)



%% Geometry checks

fprintf("\nGeometry checks\n")
fprintf("----------------\n")

fprintf("Geometry class: %s\n",class(GEO.Shape))


% Geometry type

try

    fprintf("Geometry type: %s\n",string(GEO.Shape.Geometry(1)))

catch

    fprintf("Geometry type unavailable\n")

end



% Empty geometries

empty_geom = false(N,1);

for i = 1:N
    empty_geom(i) = isempty(GEO.Shape(i));
end

fprintf("Empty geometries: %d\n",sum(empty_geom))



% Area

try

    A = area(GEO.Shape);

    invalid_area = isnan(A) | A<=0;

    fprintf("Zero/invalid area polygons: %d\n",sum(invalid_area))

catch ME

    fprintf("Area check failed: %s\n",ME.message)

end



%% Attributes

fprintf("\nAttribute checks\n")
fprintf("----------------\n")


fields = [
    "CODE_LEG"
    "NOTATION"
    "DESCR"
];


for k=1:numel(fields)

    f = fields(k);

    if isfield(GEO,f)

        v = string(GEO.(f));

        missing = ismissing(v) | v=="";

        fprintf("%s missing: %d\n",f,sum(missing))

    else

        fprintf("%s missing from GEO\n",f)

    end

end



%% Statistics

fprintf("\nAttribute statistics\n")
fprintf("----------------\n")


if isfield(GEO,"NOTATION")

    fprintf("Unique NOTATION: %d\n", ...
        numel(unique(string(GEO.NOTATION))))

end


if isfield(GEO,"CODE_LEG")

    fprintf("Unique CODE_LEG: %d\n", ...
        numel(unique(string(GEO.CODE_LEG))))

end



%% CRS

fprintf("\nCoordinate reference system\n")
fprintf("----------------\n")

if isfield(GEO,"CRS")

    disp(GEO.CRS)

else

    fprintf("CRS not stored in GEO structure\n")

end



fprintf("\nValidation finished\n")
fprintf("================================================\n")

end