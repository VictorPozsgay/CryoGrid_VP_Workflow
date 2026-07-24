%========================================================================
% CryoGrid MASK class MASK_shapefile
% Selects a region of interest from a polygon shapefile.
%
% The shapefile can be provided in any projected coordinate system
% specified through an EPSG code. Polygon coordinates are automatically
% transformed to WGS84 before masking.
%
% V. Pozsgay, 2026
%========================================================================

classdef MASK_shapefile < matlab.mixin.Copyable

    properties
        PARENT
        PARA
        CONST
        STATVAR
    end

    methods

        function mask = provide_PARA(mask)

            mask.PARA.shapefile_path = [];
            mask.PARA.shapefile_name = [];

            % EPSG code of the shapefile CRS
            mask.PARA.shapefile_epsg = 2154;

            % Optional polygon selector
            % Example: SAFRAN massif number
            mask.PARA.massif_num = [];

            % Same behaviour as MASK_kml
            mask.PARA.additive = [];

        end


        function mask = provide_STATVAR(mask)
        end


        function mask = provide_CONST(mask)
        end


        function mask = finalize_init(mask)
        end


        function mask = apply_mask(mask)

            % Read shapefile
            shp = shaperead(fullfile(mask.PARA.shapefile_path, ...
                mask.PARA.shapefile_name));

            % Optional massif selection
            if ~isempty(mask.PARA.massif_num) && ~any(isnan(mask.PARA.massif_num))

                if ~isfield(shp,'massif_num')
                    error(['Field "massif_num" not found in ' ...
                           'shapefile.']);
                end

                idx = [shp.massif_num] == mask.PARA.massif_num;

                if ~any(idx)
                    error('Massif %d not found in shapefile.', ...
                        mask.PARA.massif_num)
                end

                shp = shp(idx);
            end

            % Coordinate system
            crs = projcrs(mask.PARA.shapefile_epsg);

            % Build mask
            mask_temp = false(size(mask.PARENT.STATVAR.mask));

            for i = 1:numel(shp)
                % Remove NaN separators if present
                valid = ~(isnan(shp(i).X) | isnan(shp(i).Y));

                X = shp(i).X(valid);
                Y = shp(i).Y(valid);

                % Project polygon to WGS84
                [lat_poly, lon_poly] = projinv(crs, X, Y);

                mask_temp = mask_temp | inpolygon( ...
                    mask.PARENT.STATVAR.longitude, ...
                    mask.PARENT.STATVAR.latitude, ...
                    lon_poly, ...
                    lat_poly);
            end

            % Apply mask
            if mask.PARA.additive
                mask.PARENT.STATVAR.mask = ...
                    mask.PARENT.STATVAR.mask | mask_temp;
            else
                mask.PARENT.STATVAR.mask = ...
                    mask.PARENT.STATVAR.mask & mask_temp;
            end

        end


        %------------- param file generation -----------------------------

        function mask = param_file_info(mask)

            mask = provide_PARA(mask);

            mask.PARA.STATVAR = [];
            mask.PARA.class_category = 'MASK';
            mask.PARA.default_value = [];
            mask.PARA.comment = [];

            mask.PARA.default_value.shapefile_epsg = {2154};
            mask.PARA.comment.shapefile_epsg = ...
                {'EPSG code of shapefile coordinate system'};

            mask.PARA.default_value.massif_num = {''};
            mask.PARA.comment.massif_num = ...
                {'optional polygon selector (e.g. SAFRAN massif number)'};

            mask.PARA.default_value.additive = {0};
            mask.PARA.comment.additive = ...
                {'1 = union with existing mask, 0 = intersection'};

        end

    end

end