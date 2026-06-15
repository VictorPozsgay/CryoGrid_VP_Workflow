function providerInit = shift_to_next_tile(providerInit, tileIdx)
%SHIFT_TO_NEXT_TILE  Advance simulation to next tile group

providerInit.RUN_INFO_CLASS.PARA.tile_class = providerInit.RUN_INFO_CLASS.PARA.tile_class(tileIdx+1:end);
providerInit.RUN_INFO_CLASS.PARA.tile_class_index = providerInit.RUN_INFO_CLASS.PARA.tile_class_index(tileIdx+1:end);
providerInit.RUN_INFO_CLASS.PARA.number_of_runs_per_tile = providerInit.RUN_INFO_CLASS.PARA.number_of_runs_per_tile(tileIdx+1:end);

end