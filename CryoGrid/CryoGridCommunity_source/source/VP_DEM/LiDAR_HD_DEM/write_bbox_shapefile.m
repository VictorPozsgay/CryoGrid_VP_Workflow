function S = write_bbox_shapefile(parameterFile)
% -------------------------------------------------------------------------
% Create a complete polygon shapefile from rectangular bounding boxes
%
% INPUT
%   parameterFile : Path to MATLAB parameter script (.m)
%
% REQUIRED PARAMETERS
%   B             : Nx4 matrix [xmin ymin xmax ymax], in metres
%   massif_num    : Nx1 vector of custom massif identifiers
%   outputFile    : Output shapefile path (without extension)
%
% OPTIONAL PARAMETERS
%   names         : Nx1 cell array of polygon names
%   reducedNames  : Nx1 cell array of shortened names
%
% COORDINATE SYSTEM
%   RGF93 / Lambert-93 (EPSG:2154)
%
% OUTPUT
%   S             : Structure array compatible with MATLAB shaperead
%
% FILES CREATED
%   .shp, .shx, .dbf, .prj, .qpj, .cpg
% -------------------------------------------------------------------------

%% 1. Load parameters

if ~isfile(parameterFile)
    error('Parameter file not found: %s', parameterFile);
end

[~, ~, ext] = fileparts(parameterFile);

if ~strcmpi(ext, '.m')
    error('Parameter file must be a MATLAB .m script.');
end

run(parameterFile);

%% 2. Validate required parameters

requiredParameters = {'B', 'massif_num', 'outputFile'};

for k = 1:numel(requiredParameters)

    if ~exist(requiredParameters{k}, 'var')
        error('Parameter file must define %s.', ...
            requiredParameters{k});
    end

end

if isempty(B) || size(B, 2) ~= 4 || ...
        ~isnumeric(B) || any(~isfinite(B), 'all')

    error('B must be a non-empty Nx4 matrix of finite coordinates.');

end

n = size(B, 1);

if any(B(:, 3) <= B(:, 1)) || any(B(:, 4) <= B(:, 2))
    error('Each bounding box must have xmax > xmin and ymax > ymin.');
end

%% 3. Validate massif_num

if ~isnumeric(massif_num) || ~isvector(massif_num) || ...
        numel(massif_num) ~= n || ...
        any(~isfinite(massif_num(:))) || ...
        any(massif_num(:) < 0) || ...
        any(mod(massif_num(:), 1) ~= 0)

    error('massif_num must contain N non-negative integer identifiers.');

end

massif_num = massif_num(:);

if numel(unique(massif_num)) ~= n
    error('massif_num must contain unique identifiers.');
end

%% 4. Validate output path

if ~(ischar(outputFile) || ...
        (isstring(outputFile) && isscalar(outputFile)))

    error('outputFile must be a character vector or scalar string.');

end

outputFile = char(outputFile);

%% 5. Default attribute names

if ~exist('names', 'var') || isempty(names)

    names = arrayfun( ...
        @(k) sprintf('Massif_%d', k), ...
        massif_num, ...
        'UniformOutput', false);

end

if ~exist('reducedNames', 'var') || isempty(reducedNames)
    reducedNames = names;
end

if isstring(names)
    names = cellstr(names);
end

if isstring(reducedNames)
    reducedNames = cellstr(reducedNames);
end

if ~iscell(names) || ~iscell(reducedNames)
    error('names and reducedNames must be cell arrays or string arrays.');
end

if numel(names) ~= n || numel(reducedNames) ~= n
    error('names and reducedNames must contain exactly N entries.');
end

names = names(:);
reducedNames = reducedNames(:);

%% 6. Prepare output directory

[outputFolder, baseName, ext] = fileparts(outputFile);

if isempty(outputFolder)
    outputFolder = pwd;
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

if strcmpi(ext, '.shp')
    outputFile = fullfile(outputFolder, baseName);
else
    outputFile = fullfile(outputFolder, [baseName ext]);
end

%% 7. Initialize shapefile structure

S = repmat(struct( ...
    'Geometry',   'Polygon', ...
    'X',          [], ...
    'Y',          [], ...
    'massif_num', [], ...
    'nom',        '', ...
    'nom_reduit', '', ...
    'superficie', [], ...
    'perimetre',  []), n, 1);

%% 8. Create polygons and attributes

for k = 1:n

    xmin = B(k, 1);
    ymin = B(k, 2);
    xmax = B(k, 3);
    ymax = B(k, 4);

    % Closed rectangular polygon
    S(k).X = [xmin xmax xmax xmin xmin];
    S(k).Y = [ymin ymin ymax ymax ymin];

    % Attributes
    S(k).massif_num = massif_num(k);
    S(k).nom = char(names{k});
    S(k).nom_reduit = char(reducedNames{k});

    % Area (km²)
    S(k).superficie = ...
        (xmax - xmin) * (ymax - ymin) / 1e6;

    % Perimeter (km)
    S(k).perimetre = ...
        2 * ((xmax - xmin) + (ymax - ymin)) / 1000;

end

%% 9. Write shapefile (.shp, .shx, .dbf)

shapewrite(S, [outputFile '.shp']);

%% 10. Lambert-93 CRS (EPSG:2154)

wkt = ['PROJCS["RGF93 / Lambert-93",' ...
    'GEOGCS["RGF93",' ...
    'DATUM["Reseau_Geodesique_Francais_1993",' ...
    'SPHEROID["GRS 1980",6378137,298.257222101],' ...
    'AUTHORITY["EPSG","6171"]],' ...
    'PRIMEM["Greenwich",0],' ...
    'UNIT["degree",0.0174532925199433],' ...
    'AUTHORITY["EPSG","4171"]],' ...
    'PROJECTION["Lambert_Conformal_Conic_2SP"],' ...
    'PARAMETER["latitude_of_origin",46.5],' ...
    'PARAMETER["central_meridian",3],' ...
    'PARAMETER["standard_parallel_1",49],' ...
    'PARAMETER["standard_parallel_2",44],' ...
    'PARAMETER["false_easting",700000],' ...
    'PARAMETER["false_northing",6600000],' ...
    'UNIT["metre",1],' ...
    'AUTHORITY["EPSG","2154"]]'];

%% 11. Write projection files (.prj and .qpj)

write_text_file([outputFile '.prj'], wkt);
write_text_file([outputFile '.qpj'], wkt);

%% 12. Write character encoding (.cpg)

write_text_file([outputFile '.cpg'], 'UTF-8');

%% 13. Confirmation

fprintf('\nShapefile successfully created:\n');

extensions = {'.cpg', '.dbf', '.prj', '.qpj', '.shp', '.shx'};

for k = 1:numel(extensions)
    fprintf('  %s\n', [outputFile extensions{k}]);
end

fprintf('\nNumber of polygons: %d\n', n);
fprintf('Massif identifiers: %s\n', ...
    mat2str(massif_num'));
fprintf('Coordinate system: EPSG:2154\n\n');

end


% -------------------------------------------------------------------------
% Write text file
% -------------------------------------------------------------------------

function write_text_file(filename, content)

fid = fopen(filename, 'w');

if fid == -1
    error('Could not create file: %s', filename);
end

cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '%s\n', content);

end
