function TRun = create_template_loop_run(TAll, TNext, TRestart)

n = 9;
TRun = table(strings(n,1), strings(n,1), zeros(n,1), cell(n,1), ...
    'VariableNames', {'sup','cls','idx','blocks'} );


% Class 1
i = 1;
ops = struct([]);

ops(1).param = "tile_class";
ops(1).value = {"TILE_1D","TILE_1D"};

ops(2).param = "tile_class_index";
ops(2).value = {1,2};

ops(3).param = "number_of_runs_per_tile";
ops(3).value = {1,1};

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ops);
TRun.sup(i) = "RUN_INFO";
TRun.cls(i) = "RUN_1D_POINT_SPINUP";
TRun.idx(i) = 1;

% Class 2
i = 2;
ops = struct([]);

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "POINT", "POINT_SLOPE", 1, ops);
TRun.sup(i) = "POINT";
TRun.cls(i) = "POINT_SLOPE";
TRun.idx(i) = 1;

% Class 3
i = 3;
ops = struct([]);

ops(1).param = "TILE_1D";
ops(1).value = 1;

[TRun, ~] = modify_blocks(TNext, TRun, i, ...
    "TILE", "TILE_1D", 2, ops);
TRun.sup(i) = "TILE";
TRun.cls(i) = "TILE_1D";
TRun.idx(i) = 1;
% !!!!!!!!! MAYBE HAVE ONE FOR RESTART FILE PATH IF PUT INTO UNIQUE FOLDER

% Class 4
i = 4;
ops = struct([]);

ops(1).param = "TILE_1D";
ops(1).value = 2;

ops(2).param = "forcing_class_index";
ops(2).value = 1;

ops(3).param = "out_class";
ops(3).value = {"OUT_regridded","OUT_all_lateral","OUT_snow_all"};

ops(4).param = "out_class_index";
ops(4).value = {1,1,1};

[TRun, ~] = modify_blocks(TNext, TRun, i, ...
    "TILE", "TILE_1D", 3, ops);
TRun.sup(i) = "TILE";
TRun.cls(i) = "TILE_1D";
TRun.idx(i) = 2;

% Class 5
i = 5;
ops = struct([]);

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "FORCING", "FORCING_seb_mat", 1, ops);
TRun.sup(i) = "FORCING";
TRun.cls(i) = "FORCING_seb_mat";
TRun.idx(i) = 1;

rowIdx = identifying_line_to_change(TRun.blocks{i}, ...
    "FORCING_seb_mat", 1, "start_time");
time = TRun.blocks{i}(rowIdx,:);
s = string(time);
iStart = find(s == "H_LIST", 1);
iEnd   = find(s == "END", 1);
vals = time(iStart+1:iEnd-1);

dt = datetime(vals{1}, vals{2}, vals{3});
dt = dt + days(1);

vals = {year(dt), month(dt), day(dt)};

ops = struct([]);

ops(1).param = "end_time";
ops(1).value = vals;

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "FORCING", "FORCING_seb_mat", 1, ops);

% Class 6
i = 6;
ops = struct([]);

[TRun, ~] = modify_blocks(TAll, TRun, i, ...
    "OUT", "OUT_do_nothing", 1, ops);
TRun.sup(i) = "OUT";
TRun.cls(i) = "OUT_do_nothing";
TRun.idx(i) = 1;

% Class 7
i = 7;
ops = struct([]);

[TRun, ~] = modify_blocks(TRestart, TRun, i, ...
    "OUT", "OUT_regridded", 1, ops);
TRun.sup(i) = "OUT";
TRun.cls(i) = "OUT_regridded";
TRun.idx(i) = 1;

% Class 8
i = 8;
ops = struct([]);

[TRun, ~] = modify_blocks(TRestart, TRun, i, ...
    "OUT", "OUT_all_lateral", 1, ops);
TRun.sup(i) = "OUT";
TRun.cls(i) = "OUT_all_lateral";
TRun.idx(i) = 1;

% Class 9
i = 9;
ops = struct([]);

[TRun, ~] = modify_blocks(TRestart, TRun, i, ...
    "OUT", "OUT_snow_all", 1, ops);
TRun.sup(i) = "OUT";
TRun.cls(i) = "OUT_snow_all";
TRun.idx(i) = 1;

end
