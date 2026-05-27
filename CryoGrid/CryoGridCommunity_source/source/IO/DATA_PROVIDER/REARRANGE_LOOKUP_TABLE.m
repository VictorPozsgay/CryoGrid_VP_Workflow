%========================================================================
%
% S. Westermann, May 2026
%========================================================================

classdef REARRANGE_LOOKUP_TABLE < matlab.mixin.Copyable

    properties
        PARA
        CONST
        STATVAR
        TEMP
        PARENT
    end
    
    methods

        function data = provide_PARA(data)            
            data.PARA.variable_name = []; % name that the variable will be given
            data.PARA.lookup_table = [];
        end
        
        function data = provide_STATVAR(data)

        end
        
        function data = provide_CONST(data)
            
        end
        
        function data = finalize_init(data)
                  
        end
        
        function data = load_data(data)
            
            dataset_old = data.PARENT.STATVAR.(data.PARA.variable_name);
            dataset_new = dataset_old.*NaN;

            for i=1:size(data.PARA.lookup_table,1)
                dataset_new(find(dataset_old == data.PARA.lookup_table(i,1))) = data.PARA.lookup_table(i,2);
            end
            data.PARENT.STATVAR.(data.PARA.variable_name) = dataset_new;
        end
        

        

        
        %-------------param file generation-----
%         function point = param_file_info(point)
%             point = provide_PARA(point);
%             
%             point.PARA.STATVAR = [];
%             point.PARA.class_category = 'DATA_PROVIDER';
%             
%             point.PARA.comment.variables = {'properties calculated from DEM: altitude OR altitude, slope_angle, aspect'};
%             point.PARA.options.variables.name = 'H_LIST';
%             point.PARA.options.variables.entries_x = {'altitude' 'slope_angle' 'aspect'};
%                         
% %             point.PARA.comment.number_of_horizon_bins = {'number of angular points for which horizon is calculated; must be multiple of 4'};
% %             point.PARA.default_value.number_of_horizon_bins = {24};
%             
%             point.PARA.comment.DEM_folder = {'folder in which DEM file is located'}; 
%             
%             point.PARA.comment.DEM_filename = {'name of DEM file'}; 
%             
%             point.PARA.comment.reproject2utm = {'select 1 when using a DEM in geographic coordinates (or similar) and computing more than just altitude; select 0 to speed up altitde computation in big DEMs'};
%             point.PARA.default_value.reproject2utm = {1};
%         end
        
    end
end

