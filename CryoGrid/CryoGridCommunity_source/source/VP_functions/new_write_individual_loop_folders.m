function new_write_individual_loop_folders(TRun, TDates, result_path, init_format, constant_file, ext_dict)

allExist = all(arrayfun(@(i) isfolder(join_rel_path(result_path,sprintf('loop%d', i))), 0:height(TDates)-1));

if ~allExist
    for loopIdx = 0:height(TDates)-1
        folder = result_path + "loop" + string(loopIdx);
        if ~exist(folder, 'dir')
            mkdir(folder);
        end
    
        file = TDates{loopIdx+1,"lastFile"};
    
        ops = struct([]);
    
        ops(1).param = "restart_file_path";
        ops(1).value = folder+"\";
    
        ops(2).param = "restart_file_name";
        ops(2).value = file;
    
        [TRun, ~] = modify_blocks(TRun, TRun, false, ...
            "TILE", "TILE_1D", 1, ops);
    
        % Concatenate vertically
        run = cat(1, TRun.blocks{:});
    
        % Write to Excel
        path_out = join_rel_path(folder,"loop" + string(loopIdx),'.xlsx');
        if isfile(path_out)
            try
                delete(path_out);
            catch
                warning("Could not delete file: %s", path_out);
            end
        end
        writecell(run, path_out)
    
        copyfile(join_rel_path(result_path,constant_file,ext_dict(init_format)),folder)
        
        [~, folder_name] = fileparts(join_rel_path(result_path));
        pattern = sprintf('*%s_tile%d_*.mat', folder_name, 2*loopIdx+1);
        allFiles = dir(fullfile(result_path, pattern));
        for k = 1:numel(allFiles)
            movefile(join_rel_path(result_path,allFiles(k).name),folder)
        end
    end
    
end
end