classdef DA_OBS_read_ERT < matlab.mixin.Copyable
    
    properties
        PARA
        CONST
        STATVAR
        TEMP
    end
    
    methods

        function obs  = provide_PARA(obs)

            obs.PARA.obs_filename = [];
            obs.PARA.obs_folder = [];

            obs.PARA.target_dates = []; %Matrix with yyyy mm dd in rows and different dates in column
            obs.PARA.logarithmic = [];
        end
        
        function obs = provide_CONST(obs)
            
        end
        
        function obs = provide_STATVAR(obs)
            
        end
        
        function obs = finalize_init(obs, tile)
            obs.TEMP.obs_loaded = 0;
        end

        function obs = read_observations(obs, tile)

            if ~obs.TEMP.obs_loaded
                temp=load([obs.PARA.obs_folder obs.PARA.obs_filename]);
                a = fieldnames(temp);
                a = a{1,1};
                electrode_positions = temp.(a).electrode_positions;
                electrode_spacings = [electrode_positions(:,2)-electrode_positions(:,1) electrode_positions(:,4)-electrode_positions(:,3)];
                timestamp = temp.(a).timestamp;
                potentials = temp.(a).potentials;

                target_dates = datenum(obs.PARA.target_dates(:,1), obs.PARA.target_dates(:,2), obs.PARA.target_dates(:,3));

                obs.STATVAR.time = [];
                obs.STATVAR.observations = [];
                obs.STATVAR.obs_variance = [];

                for i=1:size(target_dates,1)

                    time_pos = find(floor(timestamp) == target_dates(i,1));
                    
                    if ~isempty(time_pos)
                        %move to 1D
                        unique_electrode_spacings = unique(electrode_spacings, 'rows');
                        potentials_averaged = potentials(1,:).*0;
                        variance_potentials = potentials(1,:).*0;

                        for j=1:size(unique_electrode_spacings,1)
                            electrode_pos = find(electrode_spacings(:,1) == unique_electrode_spacings(j,1) & electrode_spacings(:,2) == unique_electrode_spacings(j,2));

                            all_potentials = potentials(time_pos, electrode_pos);
                            all_potentials = all_potentials(:);
                            all_potentials(all_potentials<=0) = [];

                            if obs.PARA.logarithmic
                                median_potential_this_electrode_spacing = median(log(all_potentials(:)));
                                variance_potential_this_electrode_spacing = std(log(all_potentials(:))).^2;
                            else
                                median_potential_this_electrode_spacing = median(all_potentials(:));
                                variance_potential_this_electrode_spacing = std(all_potentials(:)).^2;
                            end

                            potentials_averaged(1, electrode_pos) = median_potential_this_electrode_spacing;
                            variance_potentials(1, electrode_pos) = variance_potential_this_electrode_spacing;
                        end
                        obs.STATVAR.time = [obs.STATVAR.time; target_dates(i,1)];
                        obs.STATVAR.observations = [obs.STATVAR.observations; potentials_averaged];
                        obs.STATVAR.obs_variance = [obs.STATVAR.obs_variance; variance_potentials];
                    end
                end

                obs.TEMP.obs_loaded = 1;
                
            end
        end

    end
end

