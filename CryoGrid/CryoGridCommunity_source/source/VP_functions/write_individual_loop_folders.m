function write_individual_loop_folders(TRun, dtEnd, result_path, numLoops, init_format, constant_file, ext_dict)

for n = 1:numLoops
    folder = result_path + "loop" + string(2*n-1);
    if ~exist(folder, 'dir')
        mkdir(folder);
    end

    [~, folder_name] = fileparts(join_rel_path(result_path));
    % file = string(folder_name) + "_loop" + string(n) + "_last_timestep";
    file = string(folder_name) + "_tile" + string(2*n-1) + "_run1_" + dtEnd + "_last_timestep";

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
    path_out = join_rel_path(folder,"loop" + string(2*n-1),'.xlsx');
    if isfile(path_out)
        try
            delete(path_out);
        catch
            warning("Could not delete file: %s", path_out);
        end
    end
    % disp('Writing file')
    writecell(run, path_out)

    copyfile(join_rel_path(result_path,constant_file,ext_dict(init_format)),folder)
    movefile(join_rel_path(result_path,file,".mat"),folder)
end

end
