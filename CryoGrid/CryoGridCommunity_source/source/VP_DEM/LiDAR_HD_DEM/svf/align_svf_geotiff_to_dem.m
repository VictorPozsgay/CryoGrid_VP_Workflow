function align_svf_geotiff_to_dem(svf_file,dem_file)
%ALIGN_SVF_GEOTIFF_TO_DEM Align SVF GeoTIFF to Alpine DEM conventions.
%
% DESCRIPTION
%   Rewrites an existing Alpine SVF GeoTIFF using the Alpine DEM as the
%   authoritative spatial and GeoTIFF reference.
%
%   The SVF pixel values are preserved. The DEM provides the spatial
%   reference used when writing the aligned GeoTIFF.
%
%   This is intended as a final post-processing step of
%   compute_skyview_factor_alps().
%
% INPUTS
%
%   svf_file
%       Existing Alpine SVF GeoTIFF:
%
%           SVF/ALPS/SVF_ALPS.tif
%
%   dem_file
%       Reference Alpine DEM GeoTIFF:
%
%           DEM/ALPS/DEM_ALPS.tif
%
% NOTES
%
%   - No SVF calculation is performed.
%   - No ray tracing is performed.
%   - SVF pixel values are preserved exactly.
%   - The DEM defines the authoritative raster reference and CRS.
%   - A temporary file is used before replacing the original SVF.
%
% SEE ALSO
%
%   compute_skyview_factor_alps
%   create_svf_alps_geotiff
%   write_svf_tile

%% =========================================================================
% Validate inputs
% =========================================================================

if ~isfile(svf_file)
    error("SVF file not found:\n%s",svf_file)
end

if ~isfile(dem_file)
    error("DEM file not found:\n%s",dem_file)
end

%% =========================================================================
% Read DEM spatial reference
% =========================================================================

fprintf("\n")
fprintf("Aligning SVF GeoTIFF to Alpine DEM conventions...\n")

[~,Rdem] = readgeoraster(dem_file);

%% =========================================================================
% Read SVF pixel values
% =========================================================================
%
% The original SVF may not contain valid GeoTIFF spatial metadata.
% Therefore its spatial reference is deliberately ignored.

fprintf("  Reading SVF pixel values...\n")

[SVF,~] = readgeoraster(svf_file);

SVF = single(SVF);

%% =========================================================================
% Validate raster size
% =========================================================================

if ~isequal(size(SVF),Rdem.RasterSize)

    error( ...
        ["SVF and DEM raster sizes differ.\n" ...
         "SVF: %d x %d\n" ...
         "DEM: %d x %d"], ...
        size(SVF,1),size(SVF,2), ...
        Rdem.RasterSize(1),Rdem.RasterSize(2))

end

%% =========================================================================
% Temporary output
% =========================================================================

[folder,name,ext] = fileparts(svf_file);

temp_file = fullfile( ...
    folder, ...
    name + "_aligned_tmp" + ext);

if isfile(temp_file)
    delete(temp_file)
end

cleanup = onCleanup(@()delete_if_exists(temp_file));

%% =========================================================================
% Write using DEM spatial reference
% =========================================================================

fprintf("  Writing aligned GeoTIFF...\n")

geotiffwrite( ...
    temp_file, ...
    SVF, ...
    Rdem, ...
    "CoordRefSysCode",2154);

%% =========================================================================
% Validate written GeoTIFF
% =========================================================================

fprintf("  Validating aligned GeoTIFF...\n")

[SVFcheck,Rcheck] = readgeoraster(temp_file);

SVFcheck = single(SVFcheck);

% -------------------------------------------------------------------------
% Pixel values
% -------------------------------------------------------------------------

if ~isequal(SVFcheck,SVF)

    error( ...
        "SVF pixel values changed during GeoTIFF alignment.")

end

% -------------------------------------------------------------------------
% Raster size
% -------------------------------------------------------------------------

if ~isequal(Rcheck.RasterSize,Rdem.RasterSize)

    error( ...
        "Aligned SVF raster size does not match DEM.")

end

% -------------------------------------------------------------------------
% Resolution
% -------------------------------------------------------------------------

tol = 1e-6;

if abs(Rcheck.CellExtentInWorldX - ...
       Rdem.CellExtentInWorldX) > tol || ...
   abs(Rcheck.CellExtentInWorldY - ...
       Rdem.CellExtentInWorldY) > tol

    error( ...
        "Aligned SVF resolution does not match DEM.")

end

% -------------------------------------------------------------------------
% Spatial extent
% -------------------------------------------------------------------------

if any(abs(Rcheck.XWorldLimits - ...
           Rdem.XWorldLimits) > tol) || ...
   any(abs(Rcheck.YWorldLimits - ...
           Rdem.YWorldLimits) > tol)

    error( ...
        "Aligned SVF spatial extent does not match DEM.")

end

%% =========================================================================
% Replace original
% =========================================================================

delete(svf_file)

movefile( ...
    temp_file, ...
    svf_file, ...
    "f");

clear cleanup

fprintf("  SVF GeoTIFF successfully aligned to DEM.\n")
fprintf("  %s\n",svf_file)

end


function delete_if_exists(filename)

if isfile(filename)
    delete(filename)
end

end