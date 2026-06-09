function [TNew, TInit, TNext, TRestart, TAll, result, dtEnd] = create_automatic_loops(TNew, TInit, TNext, TRestart, result_path, numLoops)

[~, folder_name] = fileparts(join_rel_path(result_path));

TAll = TInit;

mask = (TAll.sup == "FORCING");
rowIdx = identifying_line_to_change(TAll.blocks{mask}, ...
    "FORCING_seb_mat", 1, "end_time");
time = TAll.blocks{mask}(rowIdx,:);
iStart = find(string(time) == "H_LIST", 1);
iEnd   = find(string(time) == "END", 1);
vals = time(iStart+1:iEnd-1);
dtEnd = datetime(vals{1}, vals{2}, vals{3});
dtEnd = string(yyyymmdd(dtEnd));

for n = 2:numLoops
    TNextTemp = TNext;

    % First TILE with restart_OUT_last_timestep
    ops = struct([]);

    ops(1).param = "TILE_1D";
    ops(1).value = 2*n-2;

    ops(2).param = "restart_file_name";
    ops(2).value = string(folder_name) + "_tile" + string(2*n-3) + "_run1_" + dtEnd + "_last_timestep";

    [TNextTemp, idxBlock] = modify_blocks(TNext, TNextTemp, false, ...
        "TILE", "TILE_1D", 2, ops);
    TNextTemp.idx(idxBlock) = 2*n-2;

    % Second TILE with update_forcing_out
    ops = struct([]);

    ops(1).param = "TILE_1D";
    ops(1).value = 2*n-1;

    % ops(2).param = "out_class_index";
    % ops(2).value = {n};

    [TNextTemp, idxBlock] = modify_blocks(TNext, TNextTemp, false, ...
        "TILE", "TILE_1D", 3, ops);
    TNextTemp.idx(idxBlock) = 2*n-1;

    % % Third TILE with OUT_last_timestep
    % ops = struct([]);
    % 
    % ops(1).param = "OUT_last_timestep";
    % ops(1).value = n;
    % 
    % ops(2).param = "tag";
    % ops(2).value = "loop" + string(n);
    % 
    % [TNextTemp, idxBlock] = modify_blocks(TNext, TNextTemp, false, ...
    %     "OUT", "OUT_last_timestep", 2, ops);
    % TNextTemp.idx(idxBlock) = n;

    % Concatenate
    TAll = vertcat(TAll, TNextTemp);
end

supOrder = ["RUN_INFO"; "POINT"; "TILE"; "FORCING"; "OUT"; "GRID";
    "STRATIGRAPHY_CLASSES"; "STRATIGRAPHY_STATVAR"; "GROUND"; "SNOW";
    "LATERAL"; "LATERAL_IA"];
[~, TAll.supRank] = ismember(TAll.sup, supOrder); 
TAll.supRank(TAll.supRank == 0) = inf;
TAll = sortrows(TAll, {'supRank','idx'});

% Concatenate vertically
result = cat(1, TAll.blocks{:});

end
