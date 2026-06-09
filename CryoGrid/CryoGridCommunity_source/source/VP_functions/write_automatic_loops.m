function write_automatic_loops(TAll, result, result_path)

TCheck = cut_into_blocks(result);
tfa = all(all(TAll{:,1:3} == TCheck{:,1:3}));
tfb = compareBlocks(TAll.blocks(:), TCheck.blocks(:));

if ~tfa
    disp("Something went wrong with the ordering")
else
    disp("All good with the ordering")
end

if ~tfb
    disp("Something went wrong with the blocks")
else
    disp("All good with the blocks")
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if tfa && tfb
    % Write to Excel
    [~, folder_name] = fileparts(join_rel_path(result_path));
    path_out = join_rel_path(result_path,folder_name,'.xlsx');
    if isfile(path_out)
        try
            delete(path_out);
        catch
            warning("Could not delete file: %s", path_out);
        end
    end
    disp('Writing file')
    writecell(result, path_out)
end

end
