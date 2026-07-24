function crop_dem_by_massifs(dem_file, shapefile_file, output_folder)
%CROP_DEM_BY_MASSIFS Crop a DEM into individual massif GeoTIFF files.
%
%
% DESCRIPTION
%   Reads a large DEM and a SAFRAN massif shapefile, both assumed to use
%   the same projected coordinate system (typically Lambert-93 EPSG:2154).
%   The DEM is cropped separately for each polygon and saved as an
%   individual GeoTIFF file.
%
%   Pixels outside the massif polygon are set to NaN.
%
% INPUTS
%   dem_file
%       Path to the input DEM GeoTIFF.
%
%   shapefile_file
%       Path to the massif polygon shapefile.
%       Must contain a "massif_num" attribute.
%
%   output_folder
%       Folder where cropped DEM files are written.
%
% OUTPUT
%   One GeoTIFF per massif:
%
%       DEM_massif_<massif_num>.tif
%
%
% NOTES
%   The DEM and shapefile must use the same projected CRS.
%   No reprojection is performed.
%
% V. Pozsgay, 2026

% Read input data
fprintf('Reading DEM...\n')
[Z,R] = readgeoraster(dem_file);
Z = single(Z);
fprintf('DEM size: %d x %d pixels\n',size(Z,1),size(Z,2))
fprintf('Reading shapefile...\n')
S = shaperead(shapefile_file);

% Create output folder
if ~exist(output_folder,'dir')
    mkdir(output_folder)
end

% DEM coordinates
[X,Y] = worldGrid(R);

% Loop over massifs
for i = 1:numel(S)
    fprintf('\nMassif %d / %d\n',i,numel(S))
    massif_num  = S(i).massif_num;
    massif_name = S(i).nom;
    outfile = fullfile(output_folder, sprintf('DEM_massif_%02d.tif',massif_num));

    if ~isfile(outfile)   
        fprintf('Massif number: %d\n',massif_num)
        fprintf('Massif name: %s\n',massif_name)

        % Bounding box crop
        bbox = S(i).BoundingBox;
    
        x_min = bbox(1,1);
        y_min = bbox(1,2);
    
        x_max = bbox(2,1);
        y_max = bbox(2,2);
    
        col = find(X(1,:) >= x_min & X(1,:) <= x_max);
        row = find(Y(:,1) >= y_min & Y(:,1) <= y_max);
    
        if isempty(row) || isempty(col)
            warning('Massif %d outside DEM. Skipping.',massif_num)
            continue
        end
    
        Z_crop = Z(row,col);
        X_crop = X(row,col);
        Y_crop = Y(row,col);
    
        % Polygon mask
        mask = inpolygon(X_crop, Y_crop, S(i).X,  S(i).Y);
        Z_crop(~mask) = NaN;

        % Create cropped spatial reference
        R_crop = R;
        R_crop.RasterSize = size(Z_crop);
        R_crop.XWorldLimits = [ ...
            X_crop(1,1)-R.CellExtentInWorldX/2, ...
            X_crop(1,end)+R.CellExtentInWorldX/2];
        R_crop.YWorldLimits = [ ...
            Y_crop(end,1)-R.CellExtentInWorldY/2, ...
            Y_crop(1,1)+R.CellExtentInWorldY/2];
    
        % Save
        fprintf('Saving %s\n',outfile)
        geotiffwrite(outfile,Z_crop,R_crop,'CoordRefSysCode',2154)
    else
        fprintf('Skipping massif number: %d\n',massif_num)
        fprintf('Skipping massif name: %s\n',massif_name)
    end

end

fprintf('\nDone.\n')

end
