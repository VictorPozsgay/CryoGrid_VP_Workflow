function merge_BRGM_departments(geology_path)
%MERGE_BRGM_DEPARTMENTS Merge BRGM GEO050K_HARM geology layers.
%
%   merge_BRGM_departments(geology_path)
%
%   Reads the BRGM GEO050K_HARM S_FGEOL shapefiles for the Alpine
%   departments and creates a single merged geological dataset.
%
%   The output is optimized for DEM rasterization:
%
%       BRGM.X{i}
%       BRGM.Y{i}
%
%   contain the original polygon vertices (Lambert-93), with NaN
%   separators between rings/holes.
%
%   Output:
%
%       geology/BRGM_GEO050K_HARM/processed/
%           BRGM_GEO050K_HARM_ALPES.mat
%
%   Structure:
%
%       BRGM.X
%       BRGM.Y
%       BRGM.CODE_LEG
%       BRGM.NOTATION
%       BRGM.DESCR
%       BRGM.DEPARTMENT
%       BRGM.bounds_xmin
%       BRGM.bounds_xmax
%       BRGM.bounds_ymin
%       BRGM.bounds_ymax
%       BRGM.CRS
%
%   Notes:
%       Geometry is stored as explicit vertices rather than mappolyshape.
%       This allows efficient rasterization with poly2mask.
%

%% Paths

root = fullfile(geology_path,"raw");
output_folder = fullfile(geology_path,"processed");

if ~exist(output_folder,"dir")
    mkdir(output_folder)
end

output_file = fullfile(output_folder,"BRGM_GEO050K_HARM_ALPES.mat");

%% Restart check

if isfile(output_file)

    fprintf("\nMerged BRGM dataset already exists:\n%s\n", ...
        output_file)

    fprintf("Skipping merge.\n")

    return

end

%% Departments

departments = departments_list();

if isempty(departments)
    error("No departments returned by departments_list()")
end

departments = string(departments);

fprintf("\n")
fprintf("================================================\n")
fprintf("BRGM geology merge\n")
fprintf("================================================\n\n")


fprintf("Departments to merge:\n")
disp(departments)

%% Read all departments

fprintf("Reading geology layers\n")
fprintf("---------------------\n")

X = {};
Y = {};

CODE_LEG = strings(0,1);
NOTATION = strings(0,1);
DESCR = strings(0,1);
DEPARTMENT = strings(0,1);

bounds_xmin = [];
bounds_xmax = [];
bounds_ymin = [];
bounds_ymax = [];

tic

for d = 1:numel(departments)
    dep = departments(d);
    fprintf("Department %s\n",dep)
    dep_folder = sprintf("%03d",str2double(dep));
    shpfile = fullfile( ...
        root,...
        dep_folder,...
        "GEO050K_HARM_"+dep_folder+"_S_FGEOL_2154.shp");

    if ~isfile(shpfile)
        error("Missing shapefile: %s",shpfile)
    end

    GEO = read_BRGM_geology(shpfile);
    n = numel(GEO.X);

    % Append geometry

    X = [X; GEO.X];
    Y = [Y; GEO.Y];

    % Append metadata

    CODE_LEG = [
        CODE_LEG;
        GEO.CODE_LEG
        ];

    NOTATION = [
        NOTATION;
        GEO.NOTATION
        ];

    DESCR = [
        DESCR;
        GEO.DESCR
        ];


    DEPARTMENT = [
        DEPARTMENT;
        repmat(dep,n,1)
        ];

    % Compute bounds immediately

    xmin = zeros(n,1);
    xmax = zeros(n,1);
    ymin = zeros(n,1);
    ymax = zeros(n,1);

    for i = 1:n
        xx = GEO.X{i};
        yy = GEO.Y{i};

        xx = xx(~isnan(xx));
        yy = yy(~isnan(yy));

        xmin(i) = min(xx);
        xmax(i) = max(xx);

        ymin(i) = min(yy);
        ymax(i) = max(yy);
    end

    bounds_xmin = [
        bounds_xmin;
        xmin
        ];

    bounds_xmax = [
        bounds_xmax;
        xmax
        ];

    bounds_ymin = [
        bounds_ymin;
        ymin
        ];

    bounds_ymax = [
        bounds_ymax;
        ymax
        ];

end

fprintf("\n")

%% Build structure

fprintf("Building merged structure\n")
fprintf("------------------------\n")

BRGM = struct();

BRGM.X = X;
BRGM.Y = Y;

BRGM.CODE_LEG = CODE_LEG;
BRGM.NOTATION = NOTATION;
BRGM.DESCR = DESCR;

BRGM.DEPARTMENT = DEPARTMENT;

BRGM.bounds_xmin = bounds_xmin;
BRGM.bounds_xmax = bounds_xmax;

BRGM.bounds_ymin = bounds_ymin;
BRGM.bounds_ymax = bounds_ymax;

BRGM.CRS = projcrs(2154);

BRGM.source = ...
    "BRGM GEO050K_HARM S_FGEOL harmonized geological formations";

%% Save

fprintf("\nSaving merged dataset\n")
fprintf("--------------------\n")

save(output_file,"BRGM","-v7.3")

fprintf("Saved:\n%s\n",output_file)

fprintf("\n")
fprintf("================================================\n")
fprintf("Merge completed\n")
fprintf("Polygons: %d\n",numel(BRGM.X))
fprintf("================================================\n\n")

end