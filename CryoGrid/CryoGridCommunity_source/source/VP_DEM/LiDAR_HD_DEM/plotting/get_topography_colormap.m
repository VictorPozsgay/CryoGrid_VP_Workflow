function [cmap,theoretical_clim,label] = get_topography_colormap(product)
%GET_TOPOGRAPHY_COLORMAP Standard LiDAR HD topography visualization.
%
% Returns the scientifically defined colormap, theoretical color limits,
% and colorbar label for a topographic product.
%
% Product conventions:
%
%   DEM        : turbo, 0-5000 m
%   SLOPE      : reversed parula, 0-90 degrees
%   ASPECT     : cyclic HSV, 0-360 degrees
%   SVF        : parula, 0-1
%   SVF_naive  : parula, 0-1
%
% Theoretical limits are used as a fallback when no Alpine product is
% available from which to determine actual bounds.
%
% NaN pixels are handled by the calling plotting function and are rendered
% against a white axes background.

switch upper(product)

    case "DEM"

        cmap = turbo(256);
        theoretical_clim = [0 5000];
        label = "Elevation (m)";

    case "SLOPE"

        % Reverse parula:
        %
        % low slope  -> yellow
        % high slope -> dark
        %
        % This is consistent with SVF, where high SVF is yellow.

        cmap = flipud(parula(256));
        theoretical_clim = [0 90];
        label = "Slope (degrees)";

    case "ASPECT"

        % Cyclic hue map.
        %
        % 0 and 360 degrees represent the same direction.

        n = 256;

        h = linspace(0,1,n+1);
        h(end) = [];

        cmap = hsv2rgb( ...
            [h(:), ...
             ones(n,1), ...
             ones(n,1)]);

        theoretical_clim = [0 360];
        label = "Aspect (degrees)";

    case {"SVF","SVF_NAIVE"}

        cmap = parula(256);
        theoretical_clim = [0 1];
        label = "Sky-view factor";

    otherwise

        cmap = parula(256);
        theoretical_clim = [];
        label = product;

end

end