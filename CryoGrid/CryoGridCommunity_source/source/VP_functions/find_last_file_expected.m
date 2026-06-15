function expected = find_last_file_expected(providerInit)
%FIND_LAST_FILE_EXPECTED  Construct expected CryoGrid output file list
%
% This function generates the list of expected "_last_timestep" output file
% names based on the PROVIDER configuration. Each file corresponds to one
% tile-run combination and its associated forcing end time.
%
%
% INPUT
% -----
% providerInit   (PROVIDER)
%     CryoGrid PROVIDER object containing TILE and FORCING configuration.
%
%
% OUTPUT
% ------
% expected       (string array)
%     Expected output filenames in tile AND chronological order:
%       <run_name>_tile<k>_run<r>_<YYYYMMDD>_last_timestep
%
%
% DESCRIPTION
% -----------
% The function:
%   - Iterates over RUN_INFO_CLASS tile definitions
%   - Extracts tile indices and run indices
%   - Retrieves forcing end_time for each tile
%   - Converts end_time to YYYYMMDD format
%   - Constructs expected output filenames
%
% These filenames are later compared to actual simulation outputs to detect
% completion status.
%

expected = strings(0,1);

for i = 1:size(providerInit.RUN_INFO_CLASS.PARA.tile_class,1)
    nTiles = providerInit.RUN_INFO_CLASS.PARA.tile_class_index(i,1);
    nRuns = providerInit.RUN_INFO_CLASS.PARA.number_of_runs_per_tile(i,1);
    idxForcing = providerInit.CLASSES.TILE_1D{i,1}.PARA.forcing_class_index;
    if ~isequal(idxForcing,[])
        endTime = providerInit.CLASSES.FORCING_seb_mat{idxForcing,1}.PARA.end_time;
        endTime = yyyymmdd(datetime(endTime'));
        expected(end+1,1) = sprintf("%s_tile%d_run%d_%d_last_timestep", providerInit.PARA.run_name, nTiles, nRuns, endTime);
    end
end

end
