function bounds = get_topography_bounds(output_path,products)
%GET_TOPOGRAPHY_BOUNDS
% Determine Alpine visualization bounds for LiDAR HD products.
%
% DESCRIPTION
%   Scans the complete Alpine products and determines the actual finite
%   data range for each product.
%
%   The resulting bounds are intended to be reused by both:
%
%       plot_alps_topography()
%       plot_massif_topography()
%
%   ASPECT always uses the cyclic [0 360] range.
%
%   SVF and SVF_naive deliberately use exactly the same colorbar limits.
%   The common SVF range is constructed from:
%
%       1. The actual ray-traced SVF range.
%       2. The SVF range implied by the Alpine SLOPE range.
%
%   This guarantees that SVF and SVF_naive can be compared directly.
%
%   Large GeoTIFFs are scanned in blocks so the complete Alpine raster
%   does not need to be kept in memory.
%
% INPUTS
%
%   output_path
%       Root LiDAR HD DEM product folder.
%
%   products
%       Cell array containing Alpine product names, e.g.:
%
%           {'ASPECT','DEM','SLOPE','SVF','SVF_naive'}
%
% OUTPUT
%
%   bounds
%       Structure containing the visualization limits for each product.
%
% NOTES
%
%   If a product is unavailable or cannot be scanned, the theoretical
%   limits from get_topography_colormap() are used.
%

fprintf("\nDetermining Alpine product bounds...\n")

bounds = struct();

%% ========================================================================
% Step 1 - Determine actual Alpine bounds
% ========================================================================

for i = 1:numel(products)

    product = products{i};

    product_file = fullfile( ...
        output_path, ...
        product, ...
        "ALPS", ...
        sprintf("%s_ALPS.tif",product));

    % Get theoretical fallback.
    [~,theoretical_clim,~] = ...
        get_topography_colormap(product);

    %% -------------------------------------------------------------
    % Missing product
    % --------------------------------------------------------------

    if ~isfile(product_file)

        fprintf( ...
            "  %s not found -> using theoretical bounds.\n", ...
            product)

        bounds.(matlab.lang.makeValidName(product)) = ...
            theoretical_clim;

        continue

    end

    fprintf("  Scanning %s...\n",product)

    %% -------------------------------------------------------------
    % Scan raster
    % --------------------------------------------------------------

    [amin,amax] = scan_geotiff_minmax(product_file);

    %% -------------------------------------------------------------
    % Determine visualization bounds
    % --------------------------------------------------------------

    switch upper(product)

        case "ASPECT"

            % Aspect is cyclic.
            %
            % 0 and 360 represent the same direction, therefore the
            % colorbar must always span the complete cyclic range.

            clim = [0 360];

        otherwise

            if isfinite(amin) && ...
               isfinite(amax) && ...
               amin ~= amax

                clim = [amin amax];

            else

                clim = theoretical_clim;

            end

    end

    bounds.(matlab.lang.makeValidName(product)) = clim;

    fprintf( ...
        "    %s : [%g %g]\n", ...
        product, ...
        clim(1), ...
        clim(2))

end

%% ========================================================================
% Step 2 - Construct common SVF bounds
% ========================================================================

% SLOPE is required to determine the corresponding naive-SVF range.

if isfield(bounds,"SLOPE") && ...
   ~isempty(bounds.SLOPE)

    slope_min = bounds.SLOPE(1);
    slope_max = bounds.SLOPE(2);

else

    % Theoretical fallback.
    slope_min = 0;
    slope_max = 90;

end

%% ------------------------------------------------------------------------
% SVF corresponding to the SLOPE limits
% -------------------------------------------------------------------------

% Naive SVF:
%
%     SVF = (1 + cos(slope)) / 2

svf_from_slope_max = ...
    (1 + cosd(slope_max)) / 2;

svf_from_slope_min = ...
    (1 + cosd(slope_min)) / 2;

%% ------------------------------------------------------------------------
% Actual ray-traced SVF bounds
% -------------------------------------------------------------------------

if isfield(bounds,"SVF") && ...
   ~isempty(bounds.SVF) && ...
   all(isfinite(bounds.SVF))

    svf_min_actual = bounds.SVF(1);
    svf_max_actual = bounds.SVF(2);

else

    % Theoretical fallback.
    svf_min_actual = 0;
    svf_max_actual = 1;

end

%% ------------------------------------------------------------------------
% Common range
% -------------------------------------------------------------------------

% Minimum:
%
%   Take the lower of:
%
%       actual ray-traced SVF minimum
%       naive SVF at maximum slope
%
% Maximum:
%
%   Take the higher of:
%
%       actual ray-traced SVF maximum
%       naive SVF at minimum slope

svf_min = min( ...
    svf_min_actual, ...
    svf_from_slope_max);

svf_max = max( ...
    svf_max_actual, ...
    svf_from_slope_min);

% Keep within the physically meaningful SVF range.

svf_min = max(0,min(1,svf_min));
svf_max = max(0,min(1,svf_max));

%% ------------------------------------------------------------------------
% Apply identical bounds
% -------------------------------------------------------------------------

bounds.SVF = [svf_min svf_max];

bounds.SVF_naive = [svf_min svf_max];

fprintf( ...
    "  Common SVF range     : [%g %g]\n", ...
    svf_min,svf_max)

fprintf( ...
    "  Common SVF_naive range: [%g %g]\n", ...
    svf_min,svf_max)

fprintf("Alpine bounds determined.\n")

end


function [vmin,vmax] = scan_geotiff_minmax(filename)
%SCAN_GEOTIFF_MINMAX
% Scan a GeoTIFF in row blocks and return finite-data min/max.
%
% The complete raster is never retained in memory.

info = imfinfo(filename);

nRows = info.Height;
nCols = info.Width;

% Number of rows processed at once.
block_rows = 1000;

vmin = Inf;
vmax = -Inf;

for row_start = 1:block_rows:nRows

    row_end = min( ...
        row_start + block_rows - 1, ...
        nRows);

    A = imread( ...
        filename, ...
        "PixelRegion", ...
        {[row_start row_end],[1 nCols]});

    A = double(A);

    valid = isfinite(A) & A > -9000;

    if any(valid(:))

        values = A(valid);

        local_min = min(values);
        local_max = max(values);

        if local_min < vmin
            vmin = local_min;
        end

        if local_max > vmax
            vmax = local_max;
        end

    end

    clear A values valid

end

if isinf(vmin)

    vmin = NaN;
    vmax = NaN;

end

end