%========================================================================
% CryoGrid OUT class OUT_last_timestep_CG
% can be used to periodically store the entire CryoGrid stratigraphy, with 
% the ouput file getting overwritten each time. This is useful for being 
% able to recover and restart simulations (e.g. when the cluster is shut 
% down due to maintenances) in case of a long runtime. It is also posisble 
% to only store the final state of the CryoGrid stratigraphy, e.g. to run
% ensembles starting from the final state of an existing TILE class. Use
% TILE_BUILDER class "restart_OUT_last_timestep" to restart simulations.
% S. Westermann, October 2020
%========================================================================


classdef OUT_last_timestep_CG < OUT_BASE

    properties
        STRATIGRAPHY
    end

    methods

        function out = provide_PARA(out)
            out.PARA.save_date = [];
            out.PARA.save_interval = [];
            out.PARA.tag = [];
            out.PARA.tag2 = [];
        end

        function out = finalize_init(out, tile)

            % OUT_BASE requires output_timestep, although this class
            % uses only the calendar-based SAVE_TIME mechanism.
            out.PARA.output_timestep = inf;

            out = finalize_init@OUT_BASE(out, tile);
        end

        function out = store_OUT(out, tile)
        
            if tile.t >= out.SAVE_TIME
        
                disp(datestr(tile.t))
        
                % Store the complete TILE in the OUT object
                out.STRATIGRAPHY = copy(tile);
        
                % Build filename tag directly from PARA
                out_tag = [out.PARA.tag '_' out.PARA.tag2];
                out_tag = strrep(out_tag, '___', '_');
                out_tag = strrep(out_tag, '__', '_');
        
                % Make sure output directory exists
                result_folder = [tile.PARA.result_path tile.PARA.run_name];
                if ~(exist(result_folder,'dir') == 7)
                    mkdir(result_folder)
                end
        
                % Save the complete OUT object as variable "out"
                filename = [result_folder '/' ...
                    tile.PARA.run_name '_' out_tag ...
                    'last_timestep_' datestr(tile.t,'yyyymmdd') '.mat'];
        
                save(filename, 'out');
        
                % Schedule next calendar-based save
                if ~isempty(out.PARA.save_interval) && ...
                        sum(isnan(out.PARA.save_interval)) == 0 && ...
                        out.PARA.save_interval > 0
        
                    out.SAVE_TIME = min(tile.FORCING.PARA.end_time, ...
                        datenum([out.PARA.save_date ...
                        num2str(str2num(datestr(out.SAVE_TIME,'yyyy')) + ...
                        out.PARA.save_interval)], ...
                        'dd.mm.yyyy'));
        
                end
        
            end
        
        end
        
        function out = param_file_info(out)

            out = provide_PARA(out);

            out.PARA.STATVAR = [];
            out.PARA.options = [];
            out.PARA.class_category = 'OUT';

            out.PARA.default_value.save_date = {'01.09.'};
            out.PARA.comment.save_date = ...
                {'date (dd.mm.) when the output file is written'};

            out.PARA.default_value.save_interval = {1};
            out.PARA.comment.save_interval = ...
                {'interval between output files [years]'};

            out.PARA.default_value.tag = {''};
            out.PARA.comment.tag = ...
                {'additional tag added to file name'};

            out.PARA.default_value.tag2 = {''};
            out.PARA.comment.tag2 = ...
                {'second additional tag added to file name'};
        end

    end
end