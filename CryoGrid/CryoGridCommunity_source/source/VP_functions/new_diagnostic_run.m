function new_diagnostic_run(TAll, lastFileExpected, TDates, lastStruct, source_path, init_format, constant_file, result_path)

allExist = all(arrayfun(@(i) isfolder(join_rel_path(result_path,sprintf('loop%d', i))), 0:height(TDates)-1));

lastFile = lastStruct.lastFile;
lastTile = lastStruct.lastTile;
lastRun  = lastStruct.lastRun;
lastDate = lastStruct.lastDate;

if strcmp(lastFile, lastFileExpected) | allExist
    disp('Simulation already finished!')
else
    mask = (TDates.tile == lastTile) & (TDates.run == lastRun) & (TDates.endDate == lastDate);
    if any(mask)
        fprintf('Tile %d finished!\n',lastTile)
        fprintf('Restart simulation from file \n%s\n', lastFile)
        mask = (TAll.sup == "TILE") & (TAll.cls == "TILE_1D") & (TAll.idx <= lastTile);
        TAll(mask,:) = [];

        mask = (TAll.sup == "TILE") & (TAll.cls == "TILE_1D");
        idxs = num2cell(TAll{mask,'idx'})';

        ops = struct([]);
        ops(1).param = "tile_class";
        ops(1).value = repmat({"TILE_1D"},1,numel(idxs));
        ops(2).param = "tile_class_index";
        ops(2).value = idxs;
        ops(3).param = "number_of_runs_per_tile";
        ops(3).value = repmat({1},1,numel(idxs));
        [TAll, ~] = modify_blocks(TAll, TAll, false, ...
            "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ops);

        result = cat(1, TAll.blocks{:});
        write_automatic_loops(TAll, result, result_path)
    else
        if lastTile <= 1
            disp('Restart simulation from the beginning')
        else 
            fprintf('Restart simulation from file \n%s\n', lastFile)

            mask = (TAll.sup == "TILE") & (TAll.cls == "TILE_1D") & (TAll.idx < lastTile-1);
            TAll(mask,:) = [];

            mask = (TAll.sup == "TILE") & (TAll.cls == "TILE_1D");
            idxs = num2cell(TAll{mask,'idx'})';

            ops = struct([]);
            ops(1).param = "tile_class";
            ops(1).value = repmat({"TILE_1D"},1,numel(idxs));
            ops(2).param = "tile_class_index";
            ops(2).value = idxs;
            ops(3).param = "number_of_runs_per_tile";
            ops(3).value = repmat({1},1,numel(idxs));
            [TAll, ~] = modify_blocks(TAll, TAll, false, ...
                "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ops);

            ops = struct([]);
            ops(1).param = "restart_file_name";
            ops(1).value = lastFile;
            [TAll, ~] = modify_blocks(TAll, TAll, false, ...
                "TILE", "TILE_1D", lastTile-1, ops);

            mask = (TAll.sup == "FORCING") & (TAll.cls == "FORCING_seb_mat");
            max_forcing_index = max(TAll{mask,'idx'});

            vals = reading_line_block(TAll, "TILE", "TILE_1D", lastTile, "forcing_class_index");

            lineRefForcing = find((TAll.sup == "FORCING") & (TAll.cls == "FORCING_seb_mat") & (TAll.idx == vals{1}));
            lineMaxForcing = find((TAll.sup == "FORCING") & (TAll.cls == "FORCING_seb_mat") & (TAll.idx == max_forcing_index));

            Tf = TAll(lineRefForcing,:);
            Tf{1,"idx"} = vals{1};
            ops = struct([]);
            ops(1).param = "FORCING_seb_mat";
            ops(1).value = max_forcing_index+1;
            ops(2).param = "start_time";
            ops(2).value = {lastDate.Year, lastDate.Month, lastDate.Day};
            [Tf, ~] = modify_blocks(TAll, Tf, 1, ...
                "FORCING", "FORCING_seb_mat", vals{1}, ops);
            Tf{1,"idx"} = max_forcing_index+1;

            TAll = [TAll(1:lineMaxForcing,:); Tf; TAll(lineMaxForcing+1:end,:)];

            ops = struct([]);
            ops(1).param = "forcing_class_index";
            ops(1).value = max_forcing_index+1;
            [TAll, ~] = modify_blocks(TAll, TAll, false, ...
                "TILE", "TILE_1D", lastTile, ops);

            result = cat(1, TAll.blocks{:});

            write_automatic_loops(TAll, result, result_path)
        end
    end
    [~, folder_name] = fileparts(join_rel_path(result_path));
    run_CG(source_path, init_format, folder_name, ...
        extractBefore(result_path, folder_name), constant_file)
end

end
