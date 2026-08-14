%========================================================================
% CryoGrid FORCING processing class interpolate_elevation_massif_SAFRAN
% Takes SAFRAN forcing data as input and
% 1. interpolates vertically
% 2. no horizontal interpolation but chooses the correct massif
%
% Authors:
% S. Westermann, December 2022
% V. Pozsgay, July 2026
%
%========================================================================

classdef interpolate_elevation_massif_SAFRAN < process_BASE
    

    methods
        function proc = provide_PARA(proc)

        end
        
        
        function proc = provide_CONST(proc)
            proc.CONST.Tmfw = [];
        end
        
        
        function proc = provide_STATVAR(proc)
            
        end
        
        
        function proc = finalize_init(proc, tile)

        end
        
        
        function forcing = process(proc, forcing, tile)

            safran = forcing.TEMP;

            disp('finds the correct SAFRAN massif')

            lat_point = forcing.SPATIAL.STATVAR.latitude;
            lon_point = forcing.SPATIAL.STATVAR.longitude;
            
            found = 0;
            for i = 1:length(safran)
                lat_polygon = safran(i).polygon.Lat;
                lon_polygon = safran(i).polygon.Lon;
                
                if inpolygon(lon_point, lat_point, lon_polygon, lat_polygon)
                    found = 1;
                    safran = safran(i);
                    fprintf('The massif is %s, with massif number %d \n', safran.name, safran.massif_num)
                    break
            
                end
            end

            if ~found
                error('The point (lon,lat)=(%d,%d) does not belong to any SAFRAN massif.', lon_point, lat_point)
            end

            dist_alt = abs(forcing.SPATIAL.STATVAR.altitude - safran.data.z);
            [dist_alt, ind_alt] = sort(dist_alt);

            dist_alt=dist_alt(1:2);
            ind_alt = ind_alt(1:2);
            weights_alt = 1 - dist_alt./sum(dist_alt);

            disp('interpolating SAFRAN data vertically')
            fprintf('point elevation is: %.2f m \n', forcing.SPATIAL.STATVAR.altitude)

            fprintf('nearest forcing elevations are: %.2f m and %.2f m \n', dist_alt(1), dist_alt(2))
            fprintf('with respective weights: %.3f and %.3f \n', weights_alt(1), weights_alt(2))


            forcing.DATA.Tair        = double(safran.data.Tair(:,ind_alt) * weights_alt(:));
            forcing.DATA.q           = double(safran.data.q(:,ind_alt) * weights_alt(:));
            forcing.DATA.wind        = double(safran.data.wind(:,ind_alt) * weights_alt(:));
            forcing.DATA.Sin         = double(safran.data.Sin(:,ind_alt) * weights_alt(:));
            forcing.DATA.Lin         = double(safran.data.Lin(:,ind_alt) * weights_alt(:));
            forcing.DATA.p           = double(safran.data.p(:,ind_alt) * weights_alt(:));
            forcing.DATA.rainfall    = double(safran.data.rainfall(:,ind_alt) * weights_alt(:));
            forcing.DATA.snowfall    = double(safran.data.snowfall(:,ind_alt) * weights_alt(:));
            forcing.DATA.S_TOA       = double(safran.data.S_TOA);
            forcing.DATA.timeForcing = double(safran.data.t_span);

            forcing.TEMP = [];

        end
                
    end
    
end

