function [TNew, TInit, TNext, TRestart, TAll, result, dictDtEnd] = create_automatic_loops(TNew, TInit, TNext, TRestart, result_path, GenParamsStruct)

numLoops = GenParamsStruct.num_loops + 1;
[~, folder_name] = fileparts(join_rel_path(result_path));

TAll = TInit;

dictDtEnd = dictionary();

mask = find((TAll.sup == "FORCING") & (TAll.cls == "FORCING_seb_mat"));
for i = 1:numel(mask)
    dtEnd = reading_line_block(TAll, "FORCING", "FORCING_seb_mat", TAll{mask(i),"idx"}, "end_time");
    dictDtEnd(TAll{mask(i),"idx"}) = yyyymmdd(datetime(dtEnd{:}));
end


for n = 2:numLoops
    TNextTemp = TNext;

    if n==2
        dtEnd = dictDtEnd(1);
    else
        dtEnd = dictDtEnd(2);
    end

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

    [TNextTemp, idxBlock] = modify_blocks(TNext, TNextTemp, false, ...
        "TILE", "TILE_1D", 3, ops);
    TNextTemp.idx(idxBlock) = 2*n-1;

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
