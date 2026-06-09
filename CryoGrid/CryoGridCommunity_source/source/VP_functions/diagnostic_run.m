function diagnostic_run(TAll, dtEnd, source_path, init_format, constant_file, result_path, numLoops)

[~, folder_name] = fileparts(join_rel_path(result_path));

skip = all(arrayfun(@(k) ...
    isfile(fullfile(result_path,sprintf('loop%d', 2*k-1), ...
    sprintf('%s_tile%d_run1_%s_last_timestep.mat', folder_name, 2*k-1, dtEnd))), ...
    1:numLoops));


if ~skip

    last_good_loop = 0;

    % add source code path
    addpath(genpath(source_path));

    for n = 1:numLoops+1
        % [~, folder_name] = fileparts(join_rel_path(result_path));
        file_path = result_path+"\"+folder_name+ "_tile" + string(2*n-1) + "_run1_" + dtEnd + "_last_timestep.mat";
        if isfile(file_path) 
            file_load = load(file_path);
        else
            break
        end
        OUTPUT_TIME = file_load.out.OUTPUT_TIME;
        SAVE_TIME = file_load.out.SAVE_TIME;
        if OUTPUT_TIME >= SAVE_TIME
            fprintf("All good with loop %i \n", n)
            last_good_loop = n;
        else
            break
        end
    end

    if last_good_loop < numLoops 
        fprintf("Last good loop is loop %i \n", last_good_loop)


        if last_good_loop > 0
            ops = struct([]);
            ops(1).param = "tile_class";
            ops(1).value = repmat({"TILE_1D"}, 1, 2*(numLoops-last_good_loop));

            ops(2).param = "tile_class_index";
            ops(2).value = num2cell(2*last_good_loop:2*numLoops-1);

            ops(3).param = "number_of_runs_per_tile";
            ops(3).value = num2cell(ones(1,2*(numLoops-last_good_loop)));

            [TAll, ~] = modify_blocks(TAll, TAll, false, ...
                "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ops);

            mask = (TAll.sup == "TILE") & (TAll.cls == "TILE_1D") & (TAll.idx < 2*last_good_loop);
            TAll(mask,:) = [];

            % mask = (TAll.sup == "OUT") & (TAll.cls == "OUT_last_timestep") & (TAll.idx <= last_good_loop);
            % TAll(mask,:) = [];

            % Concatenate vertically
            result = cat(1, TAll.blocks{:});

            write_automatic_loops(TAll, result, result_path)

        end

        % [~, folder_name] = fileparts(join_rel_path(result_path));
        run_CG(source_path, init_format, folder_name, ...
            extractBefore(result_path, folder_name), constant_file)

    end

else
    disp("All folders were already created, we can skip to the parallel runs.")
end

end
