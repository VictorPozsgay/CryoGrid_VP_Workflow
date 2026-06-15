function providerInit = restart_within_tile(providerInit, tileIdx, lastInfo)
%RESTART_WITHIN_TILE  Resume simulation inside an unfinished tile

% Truncate RUN_INFO_CLASS consistently (CRITICAL)
providerInit = shift_to_next_tile(providerInit, tileIdx-2);
% providerInit.RUN_INFO_CLASS.PARA.tile_class = providerInit.RUN_INFO_CLASS.PARA.tile_class(tileIdx-1:end);
% providerInit.RUN_INFO_CLASS.PARA.tile_class_index = providerInit.RUN_INFO_CLASS.PARA.tile_class_index(tileIdx-1:end);
% providerInit.RUN_INFO_CLASS.PARA.number_of_runs_per_tile = providerInit.RUN_INFO_CLASS.PARA.number_of_runs_per_tile(tileIdx-1:end);

% Assign restart file to previous tile
providerInit.CLASSES.TILE_1D{tileIdx-1,1}.PARA.restart_file_name = lastInfo.lastFile;

% Rebuild forcing chain safely (no aliasing)
forc = providerInit.CLASSES.FORCING_seb_mat;
forc = forc(~cellfun(@isempty, forc));
forcingIdx = providerInit.CLASSES.TILE_1D{tileIdx,1}.PARA.forcing_class_index;
newForcing = copy(forc{forcingIdx,1});
startTime = datetime(lastInfo.lastDate, "ConvertFrom", "yyyyMMdd");
newForcing.PARA.start_time = [startTime.Year; startTime.Month; startTime.Day];
newForcing.PARA.class_index = numel(forc) + 1;
providerInit.CLASSES.FORCING_seb_mat = [forc; {newForcing}];

% Re-link tile to new forcing instance
providerInit.CLASSES.TILE_1D{tileIdx,1}.PARA.forcing_class_index = newForcing.PARA.class_index;

end
