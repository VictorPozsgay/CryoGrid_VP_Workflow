function TInit = duplicate_forcing_init(TInit, ref_forcing_index)

mask = (TInit.sup == "FORCING") & (TInit.cls == "FORCING_seb_mat");
max_forcing_index = max(TInit{mask,'idx'});

lineRefForcing = find((TInit.sup == "FORCING") & (TInit.cls == "FORCING_seb_mat") & (TInit.idx == ref_forcing_index));
lineMaxForcing = find((TInit.sup == "FORCING") & (TInit.cls == "FORCING_seb_mat") & (TInit.idx == max_forcing_index));

Tf = TInit(lineRefForcing,:);
Tf{1,"idx"} = ref_forcing_index;

ops = struct([]);
ops(1).param = "FORCING_seb_mat";
ops(1).value = max_forcing_index+1;
[Tf, ~] = modify_blocks(TInit, Tf, 1, ...
    "FORCING", "FORCING_seb_mat", ref_forcing_index, ops);
Tf{1,"idx"} = max_forcing_index+1;

TInit = [TInit(1:lineMaxForcing,:); Tf; TInit(lineMaxForcing+1:end,:)];

endTime = reading_line_block(TInit, "FORCING", "FORCING_seb_mat", ref_forcing_index, "start_time");
endTime = datetime(endTime{:}) + days(1);

ops = struct([]);
ops(1).param = "end_time";
ops(1).value = {endTime.Year, endTime.Month, endTime.Day};
[TInit, ~] = modify_blocks(TInit, TInit, false, ...
    "FORCING", "FORCING_seb_mat", ref_forcing_index, ops);

end
