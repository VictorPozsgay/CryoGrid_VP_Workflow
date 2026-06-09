%========================================================================
% CryoGrid OUT class OUT_last_timestep
% can be used to periodically store the entire CryoGrid stratigraphy, with 
% the ouput file getting overwritten each time. This is useful for being 
% able to recover and restart simulations (e.g. when the cluster is shut 
% down due to maintenances) in case of a long runtime. It is also posisble 
% to only store the final state of the CryoGrid stratigraphy, e.g. to run
% ensembles starting from the final state of an existing TILE class. Use
% TILE_BUILDER class "restart_OUT_last_timestep" to restart simulations.
% S. Westermann, October 2020
%========================================================================


classdef OUT_last_timestep < OUT_BASE

    properties
		
        STRATIGRAPHY
		
	end
    
    
    methods

        
        function out = provide_PARA(out)         

            out.PARA.save_timestep = []; %if empty save final state at the end of the run, so that it can serve as initial condition for new runs
            % NEW VP CODE STARTS HERE
            out.PARA.use_save_date = [];
            out.PARA.save_date = [];
            out.PARA.save_interval = [];
            % NEW VP CODE ENDS HERE
            out.PARA.tag = [];
            out.PARA.tag2 = [];

        end
		
		function out = finalize_init(out, tile)
            
            if ~isempty(out.PARA.tag) && sum(isnan(out.PARA.tag))>0
                out.PARA.tag = [];
            end
		
			forcing = tile.FORCING;
            
            % NEW VP CODE STARTS HERE
            % NEW OPTION: use save_date / save_interval scheduling
            if ~isempty(out.PARA.use_save_date) && ...
                ~isnan(out.PARA.use_save_date) && ...
                out.PARA.use_save_date == 1

                if isempty(out.PARA.save_interval) || any(isnan(out.PARA.save_interval))
                    out.SAVE_TIME = forcing.PARA.end_time;
                else
                    out.SAVE_TIME = min( ...
                        forcing.PARA.end_time, ...
                        datenum([ ...
                        out.PARA.save_date ...
                        num2str(str2num(datestr(forcing.PARA.start_time,'yyyy')) + out.PARA.save_interval)], ...
                        'dd.mm.yyyy'));
                end
                out.OUTPUT_TIME = out.SAVE_TIME;
            else
                % ORIGINAL OUT_last_timestep behaviour
                if isempty(out.PARA.save_timestep) || sum(isnan(out.PARA.save_timestep))>0
                    out.OUTPUT_TIME = forcing.PARA.end_time;
                else
                    out.OUTPUT_TIME = forcing.PARA.start_time + out.PARA.save_timestep;
                end
                out.SAVE_TIME = forcing.PARA.end_time;
            end
            % NEW VP CODE ENDS HERE
        end
        
        %-------time integration----------------
        
        function out = store_OUT(out, tile)
            t = tile.t;

            out_tag = [out.PARA.tag '_' out.PARA.tag2];
            if strcmp(out_tag(end), '_')
                out_tag = out_tag(1:end-1);
            end
            if ~isempty(out_tag) && strcmp(out_tag(1), '_')
                out_tag = out_tag(2:end);
            end
            
            if t>=out.SAVE_TIME || t >= out.OUTPUT_TIME
                
                disp([datestr(t)])
                
                run_name = tile.PARA.run_name; %tile.RUN_NUMBER;
                result_path = tile.PARA.result_path;
                                
                out.STRATIGRAPHY = copy(tile);

                if ~(exist([result_path run_name])==7)
                    mkdir([result_path result_path])
                end

                % NEW VP CODE STARTS HERE
                if isempty(out.PARA.use_save_date) || ...
                    any(isnan(out.PARA.use_save_date)) || ...
                    ~out.PARA.use_save_date
                    if isempty(out_tag) || all(isnan(out_tag))
                        save([result_path run_name '/' run_name '_last_timestep.mat'], 'out')
                    else
                        save([result_path run_name '/' run_name '_' out_tag '_last_timestep.mat'], 'out')
                    end
                % Use of a new parameter: use_save_date
                % OUT_regridded-style naming + spinup tagging
                else
                    % New save_date behaviour
                    spinup_tag = '';
                    if isprop(tile.RUN_INFO,'TEMP') && ...
                        isfield(tile.RUN_INFO.TEMP, 'spinup_index')
                        spinup_tag = sprintf('_tile%d_run%d', ...
                            tile.RUN_INFO.TEMP.tile_index, ...
                            tile.RUN_INFO.TEMP.spinup_index);
                    end

                    if isempty(out_tag)
                        filename = [run_name spinup_tag '_' datestr(t,'yyyymmdd') '_last_timestep.mat'];    
                    else
                        filename = [run_name '_' out_tag spinup_tag '_' datestr(t,'yyyymmdd') '_last_timestep.mat'];
                    end
                    save([result_path run_name '/' filename], 'out')
                end

                if isempty(out.PARA.use_save_date) || ...
                        any(isnan(out.PARA.use_save_date)) || ...
                        ~out.PARA.use_save_date
                    out.OUTPUT_TIME = out.OUTPUT_TIME + out.PARA.save_timestep;
                else
                    out.OUTPUT_TIME = out.SAVE_TIME;
                end

                if ~isempty(out.PARA.save_interval) && ...
                        ~any(isnan(out.PARA.save_interval)) && ...
                        out.PARA.save_interval > 0

                    out.SAVE_TIME = min(tile.FORCING.PARA.end_time, ...
                        datenum([out.PARA.save_date ...
                        num2str(str2num(datestr(out.SAVE_TIME,'yyyy')) + out.PARA.save_interval)], ...
                        'dd.mm.yyyy'));
                end
                % NEW VP CODE ENDS HERE                
            end
            
        end
        
                %-------------param file generation-----
        function out = param_file_info(out)
            out = provide_PARA(out);

            out.PARA.STATVAR = [];
            out.PARA.options = [];
            out.PARA.class_category = 'OUT';

            % NEW VP CODE STARTS HERE
            out.PARA.default_value.use_save_date = {0};
            out.PARA.comment.use_save_date = ...
                {'if 1, append spinup index and date to filename'};

            out.PARA.default_value.save_date = {'01.09.'};
            out.PARA.comment.save_date = {'date (dd.mm.) when output file is written'};

            out.PARA.default_value.save_interval = {1};
            out.PARA.comment.save_interval = {'interval of output files [years]'};
            % NEW VP CODE ENDS HERE
           
            out.PARA.default_value.save_timestep = {''};
            out.PARA.comment.save_timestep = {'in days, if empty save final state at the end of the run, so that it can serve as initial condition for new runs'};
            
            out.PARA.default_value.tag = {''};
            out.PARA.comment.tag = {'additional tag added to file name'};
        end

        
    end
end