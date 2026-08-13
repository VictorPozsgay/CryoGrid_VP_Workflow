function compute_naive_svf(output_path,varargin)
%COMPUTE_NAIVE_SVF Compute slope-based sky-view factor for massif products.
%
% DESCRIPTION
%   Computes the simple local slope-based sky-view factor:
%
%       SVF = (1 + cosd(SLOPE)) / 2
%
%   which is mathematically equivalent to:
%
%       SVF = cosd(SLOPE/2).^2
%
%   The function scans the SLOPE/ folder for massif-specific slope
%   products following the standard convention:
%
%       SLOPE/
%           SLOPE_massif_XX.tif
%
%   Corresponding SVF products are written to:
%
%       SVF_naive/
%           SVF_naive_massif_XX.tif
%
%   The original raster reference and Lambert-93 CRS are preserved.
%
% INPUT
%
%   output_path
%       Complete LiDAR HD DEM product folder.
%
% OPTIONS
%
%   "Overwrite"
%       Recompute existing products.
%       Default = false
%
% OUTPUT
%
%   Creates:
%
%       SVF_naive/
%           SVF_naive_massif_XX.tif
%
% NOTES
%
%   This is deliberately a simple local approximation. It does not
%   account for surrounding terrain horizons.
%
%   No resampling is performed.
%
%   NoData values are preserved as -9999.
%

%% =========================================================================
% Options
% =========================================================================

p = inputParser;

addParameter(p,"Overwrite",false)

parse(p,varargin{:})

overwrite = p.Results.Overwrite;

nodata = single(-9999);

%% =========================================================================
% Paths
% =========================================================================

slope_folder = fullfile(output_path,"SLOPE");
output_folder = fullfile(output_path,"SVF_naive");

if ~isfolder(slope_folder)
    error("SLOPE folder not found: %s",slope_folder)
end

if ~isfolder(output_folder)
    mkdir(output_folder)
end

%% =========================================================================
% Find massif slope products
% =========================================================================

files = dir(fullfile(slope_folder,"SLOPE_massif_*.tif"));

fprintf("\n")
fprintf("Computing naive slope-based SVF...\n")
fprintf("  Found %d massif slope products.\n",numel(files))

if isempty(files)
    fprintf("No slope products found. Nothing to do.\n")
    return
end

%% =========================================================================
% Process massif products
% =========================================================================

for i = 1:numel(files)

    slope_file = fullfile( ...
        files(i).folder, ...
        files(i).name);

    fprintf("  Processing %s\n",files(i).name)

    %% ---------------------------------------------------------------------
    % Determine output filename
    % ----------------------------------------------------------------------

    [~,name,~] = fileparts(files(i).name);

    % SLOPE_massif_01
    %        ↓
    % SVF_naive_massif_01

    suffix = erase(name,"SLOPE_");

    output_file = fullfile( ...
        output_folder, ...
        sprintf("SVF_naive_%s.tif",suffix));

    % Explicitly ensure that this is a character/string scalar.
    output_file = string(output_file);

    %% ---------------------------------------------------------------------
    % Restart logic
    % ----------------------------------------------------------------------

    if isfile(output_file) && ~overwrite

        fprintf("    Already exists. Skipping.\n")
        continue

    end

    %% ---------------------------------------------------------------------
    % Read slope
    % ----------------------------------------------------------------------

    [SLOPE,R] = readgeoraster(slope_file);

    SLOPE = single(SLOPE);

    %% ---------------------------------------------------------------------
    % NoData
    % ----------------------------------------------------------------------

    valid = SLOPE > -9000 & isfinite(SLOPE);

    %% ---------------------------------------------------------------------
    % Compute naive SVF
    % ----------------------------------------------------------------------

    SVF = nodata * ones(size(SLOPE),"single");

    SVF(valid) = ...
        (1 + cosd(SLOPE(valid))) / 2;

    %% ---------------------------------------------------------------------
    % Write
    % ----------------------------------------------------------------------

    geotiffwrite( ...
        output_file, ...
        SVF, ...
        R, ...
        "CoordRefSysCode",2154);

end

fprintf("\nNaive SVF computation complete.\n")
fprintf("Output folder:\n%s\n",output_folder)

end