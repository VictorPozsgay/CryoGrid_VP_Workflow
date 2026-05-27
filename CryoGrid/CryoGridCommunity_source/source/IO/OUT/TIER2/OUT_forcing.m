%========================================================================
% CryoGrid OUT class OUT_all
% CryoGrid OUT class defining storage format of the output 
% OUT_all stores identical copies of all GROUND classses (including STATVAR, TEMP, PARA) in the
% stratigraphy for each output timestep, while lateral classes are not stored.
% The user can specify the save date and the save interval (e.g. yearly
% files), as well as the output timestep (e.g. 6 hourly). The output files
% are in Matlab (".mat") format.
% S. Westermann, T. Ingeman-Nielsen, J. Scheer, June 2021
%========================================================================


classdef OUT_forcing < OUT_BASE
 

    properties

    end
    
    
    methods
        
        %initialization
        
        function out = provide_PARA(out)         

            out.PARA.tag = [];
            out.PARA.tag2 = [];

        end

        function out = finalize_init(out, tile)
            if ~isempty(out.PARA.tag) && sum(isnan(out.PARA.tag))>0
                out.PARA.tag = [];
            end

            out.SAVE_TIME = tile.FORCING.PARA.start_time;
            out.OUTPUT_TIME = Inf;
            out.TEMP.keyword = 'forcing';
        end
            
        function out = store_OUT(out, tile)

            if tile.t >= out.SAVE_TIME
                out.TEMP.tag = ['_' out.PARA.tag '_' out.PARA.tag2 '_'];
                out.TEMP.tag = strrep(out.TEMP.tag, '___', '_');
                out.TEMP.tag = strrep(out.TEMP.tag, '__', '_');
                if strcmp(out.TEMP.tag(end), '_')
                    out.TEMP.tag = out.TEMP.tag(1:end-1);
                end


                if ~(exist([tile.PARA.result_path tile.PARA.run_name])==7)
                    mkdir([tile.PARA.result_path tile.PARA.run_name])
                end


                fn = fieldnames(tile.FORCING.DATA);
                for i=1:size(fn,1)
                    FORCING.data.(fn{i,1}) = tile.FORCING.DATA.(fn{i,1});
                end
                FORCING.identifier = tile.RUN_INFO.PPROVIDER.PARA.identifier; 
                save([tile.PARA.result_path tile.PARA.run_name '/' tile.PARA.run_name '_' out.TEMP.keyword out.TEMP.tag '.mat'], 'FORCING')

                out.SAVE_TIME = Inf;
            end
        end


        %-------------param file generation-----
        function out = param_file_info(out)
            out = provide_PARA(out);

            out.PARA.STATVAR = [];
            out.PARA.options = [];
            out.PARA.class_category = 'OUT';
           
            out.PARA.default_value.output_timestep = {0.25};
            out.PARA.comment.output_timestep = {'timestep of output [days]'};

            out.PARA.default_value.save_date = {'01.09.'};
            out.PARA.comment.save_date = {'date (dd.mm.) when output file is written'};
            
            out.PARA.default_value.save_interval = {1};
            out.PARA.comment.save_interval = {'interval of output files [years]'};
            
            out.PARA.default_value.tag = {''};
            out.PARA.comment.tag = {'additional tag added to file name'};
        end
        
        
%         function xls_out = write_excel(out)
%             % XLS_OUT  Is a cell array corresponding to the class-specific content of the parameter excel file (refer to function write_controlsheet).
%             
%             xls_out = {'OUT','index',NaN,NaN;'OUT_all',1,NaN,NaN;'output_timestep',0.250000000000000,'[days]',NaN;'save_date','01.09.','provide in format dd.mm.',NaN;'save_interval',1,'[y]','if left empty, the entire output will be written out at the end';'OUT_END',NaN,NaN,NaN};
%         end
        
    end
end