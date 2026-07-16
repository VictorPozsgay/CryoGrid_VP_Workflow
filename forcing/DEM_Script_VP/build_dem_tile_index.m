function TILES = build_dem_tile_index(root_folder)
%BUILD_DEM_TILE_INDEX Build spatial index of IGN RGE ALTI ASCII tiles.
%
% Reads one DEM tile to determine the exact relationship between the IGN
% filename convention and Lambert-93 coordinates, then applies this
% relationship to all tiles without opening them.
%
% INPUT
%   root_folder
%       Folder containing RGE ALTI *.asc files.
%
% OUTPUT
%   TILES
%       Table containing:
%       filename
%       folder
%       xmin xmax ymin ymax
%       nrows ncols
%       cellsize
%
% CRS:
%   Lambert-93 / EPSG:2154
%

%% Constants

tileSize = 5000; % metres


%% Find DEM files

files = dir(fullfile(root_folder,"**","*.asc"));

fprintf("Found %d DEM tiles\n",numel(files))


if isempty(files)
    error("No ASC files found")
end


%% Read first tile to determine filename convention

test_file = fullfile(files(1).folder,files(1).name);

fprintf("Reading reference tile:\n%s\n",files(1).name)

[~,R] = readgeoraster(test_file);


% Actual raster limits

actual_xmin = R.XWorldLimits(1);
actual_ymin = R.YWorldLimits(1);


% Extract filename indices

tokens = regexp( ...
    files(1).name, ...
    'RGEALTI_FXX_(\d+)_(\d+)_MNT', ...
    'tokens');


if isempty(tokens)
    error("Cannot decode filename: %s",files(1).name)
end


tokens = tokens{1};

ix = str2double(tokens{1});
iy = str2double(tokens{2});


% Filename-based coordinates

nominal_xmin = ix * 1000;
nominal_ymin = iy * 1000;


% Determine offsets

offset_x = actual_xmin - nominal_xmin;
offset_y = actual_ymin - nominal_ymin;


fprintf("\nDerived filename offsets:\n")
fprintf("X offset = %.3f m\n",offset_x)
fprintf("Y offset = %.3f m\n\n",offset_y)



%% Allocate

N = numel(files);

filename = strings(N,1);
folder   = strings(N,1);

xmin = zeros(N,1);
xmax = zeros(N,1);

ymin = zeros(N,1);
ymax = zeros(N,1);


nrows = zeros(N,1);
ncols = zeros(N,1);

cellsize = zeros(N,1);



%% Build index

for k = 1:N

    if mod(k,500)==0 || k==N
        fprintf("%d/%d\n",k,N)
    end


    filename(k) = files(k).name;
    folder(k)   = files(k).folder;


    tokens = regexp( ...
        files(k).name, ...
        'RGEALTI_FXX_(\d+)_(\d+)_MNT', ...
        'tokens');


    if isempty(tokens)
        error("Cannot decode filename: %s",files(k).name)
    end


    tokens = tokens{1};

    ix = str2double(tokens{1});
    iy = str2double(tokens{2});


    % Apply calibrated relationship

    xmin(k) = ix*1000 + offset_x;
    ymin(k) = iy*1000 + offset_y;


    xmax(k) = xmin(k) + tileSize;
    ymax(k) = ymin(k) + tileSize;


    nrows(k) = 1000;
    ncols(k) = 1000;
    cellsize(k) = 5;

end



%% Create table

TILES = table( ...
    filename,...
    folder,...
    xmin,...
    xmax,...
    ymin,...
    ymax,...
    nrows,...
    ncols,...
    cellsize,...
    'VariableNames',...
    {'filename','folder',...
     'xmin','xmax',...
     'ymin','ymax',...
     'nrows','ncols',...
     'cellsize'});



%% Save

output_file = fullfile(root_folder,"tile_index.mat");

save(output_file,"TILES","-v7.3");

fprintf("\nSaved:\n%s\n",output_file)

end
