function [TNew, TInit, TNext, TRestart] = setup_files(result_path, TNew, GenParamsStruct)

init = format_template(result_path,'TILE_LOOP_INIT','.xlsx');
next = format_template(result_path,'TILE_LOOP_NEXT','.xlsx');
restart = format_template(result_path,'RESTART','.xlsx');

TInit = cut_into_blocks(init);
TNext = cut_into_blocks(next);
TRestart = cut_into_blocks(restart);

numLoops = GenParamsStruct.num_loops + 1;

ops = struct([]);
ops(1).param = "tile_class";
ops(1).value = repmat({"TILE_1D"}, 1, 2*numLoops-1);

ops(2).param = "tile_class_index";
ops(2).value = num2cell(1:2*numLoops-1);

ops(3).param = "number_of_runs_per_tile";
ops(3).value = num2cell(ones(1,2*numLoops-1));

[TInit, ~] = modify_blocks(TInit, TInit, false, ...
    "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ops);

ops = struct([]);
ops(1).param = "restart_file_path";
ops(1).value = result_path;

[TNext, ~] = modify_blocks(TNext, TNext, false, ...
    "TILE", "TILE_1D", 2, ops);

ops = struct([]);
ops(1).param = "forcing_class_index";
ops(1).value = 2;

[TNext, ~] = modify_blocks(TNext, TNext, false, ...
    "TILE", "TILE_1D", 3, ops);


% Maximum width across all blocks
maxCols = max([ ...
    cellfun(@(x) size(x,2), TInit.blocks); ...
    cellfun(@(x) size(x,2), TNext.blocks); ...
    cellfun(@(x) size(x,2), TNew.blocks) ]);

padBlock = @(B) padBlockFcn(B, maxCols);

TInit.blocks = cellfun(padBlock, TInit.blocks, 'UniformOutput', false);
TNext.blocks = cellfun(padBlock, TNext.blocks, 'UniformOutput', false);
TNew.blocks  = cellfun(padBlock, TNew.blocks,  'UniformOutput', false);
TRestart.blocks = cellfun(padBlock, TRestart.blocks, 'UniformOutput', false);

end
