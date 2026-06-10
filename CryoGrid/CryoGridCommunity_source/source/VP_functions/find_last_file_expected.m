function [lastFile, TDates] = find_last_file_expected(result_path, TIn)

[~, folder_name] = fileparts(join_rel_path(result_path));

mask = (TIn.sup == "TILE") & (TIn.cls == "TILE_1D");
idxs = num2cell(TIn{mask,'idx'})';

lastFile = '';
TDates = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','string'}, ...
    'VariableNames', {'tile','run','endDate','lastFile'});

for i = 1:numel(idxs)
    idx = idxs{i};
    vals = reading_line_block(TIn, "TILE", "TILE_1D", idx, "out_class");
    out = any(cellfun(@(x) isstring(x) && any(x == "OUT_last_timestep"), vals));
    if out
        vals = reading_line_block(TIn, "TILE", "TILE_1D", idx, "forcing_class_index");
        endTime = reading_line_block(TIn, "FORCING", "FORCING_seb_mat", vals{1}, "end_time");
        endTime = yyyymmdd(datetime(endTime{:}));
        vals = reading_line_block(TIn, "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, "number_of_runs_per_tile");
        nRun = vals{i};
        lastFile = sprintf("%s_tile%d_run%d_%d_last_timestep", folder_name, idx, nRun, endTime);
        TDates(end+1,:) = {idx, nRun, endTime, lastFile};
    end
end

end
