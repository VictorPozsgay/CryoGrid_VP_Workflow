function [providerInit, runBool] = checkpoint_manager(providerInit, result_path, run_name)
%CHECKPOINT_MANAGER  Automatic restart handler for CryoGrid simulations
%
% This function inspects existing simulation outputs and automatically
% determines whether a CryoGrid spinup simulation:
%   (1) completed successfully
%   (2) is partially complete and must resume
%
% If a restart is required, the PROVIDER object is safely modified so that:
%   - simulation resumes at correct tile/run boundary
%   - forcing chain is extended if needed
%   - restart files are uniquely assigned
%
% This replaces manual restart logic based on RUN_INFO_CLASS truncation.
%
%
% INPUTS
% ------
% providerInit  (PROVIDER)
%     Fully initialized CryoGrid PROVIDER object.
%
% result_path   (char|string)
%     Path to simulation output directory.
%
% run_name      (char|string)
%     Simulation name (folder + file prefix).
%
%
% OUTPUTS
% -------
% providerInit  (PROVIDER)
%     Updated provider ready to continue simulation if incomplete,
%     otherwise unchanged if simulation is complete.
%
% runBool       (bool)
%     Whether or not to run the simulation with the given provider
%
%
% OVERVIEW
% --------
% 1. Scan filesystem for completed "_last_timestep" files
% 2. Extract last completed tile/run/date
% 3. Compare against expected simulation structure
% 4. Decide restart mode:
%       - COMPLETE
%       - TILE BREAK (resume next tile)
%       - WITHIN-TILE BREAK (resume same tile)
% 5. Apply minimal safe modifications to providerInit
%
%
% SEE ALSO
% --------
% find_last_file_expected, find_last_file_out_last_timestep
%

expected = find_last_file_expected(providerInit);
lastInfo = find_last_file_out_last_timestep(result_path, run_name);

runBool = true;

% CASE 0: nothing found
if strcmp(lastInfo.lastFile,"")
    warning('No output found. Starting fresh simulation.');
    return;
end

% CASE 1: simulation complete
if strcmp(lastInfo.lastFile, expected(end))
    disp('Simulation successfully completed.');
    runBool = false;
    return;
end

% locate tile index in RUN_INFO
tileIdx = find(providerInit.RUN_INFO_CLASS.PARA.tile_class_index == lastInfo.lastTile, 1);

if isempty(tileIdx)
    error('Restart tile index not found in RUN_INFO_CLASS.');
end

% CASE 2: tile fully completed → resume next tile
if ismember(lastInfo.lastFile, expected)

    providerInit = shift_to_next_tile(providerInit, tileIdx);

    fprintf('Tile %d completed. Restarting at next tile.\n', lastInfo.lastTile);
    fprintf('Last file: %s\n', lastInfo.lastFile);

% CASE 3: interruption within tile → resume same tile
else

    providerInit = restart_within_tile(providerInit, tileIdx, lastInfo);

    fprintf('Interrupted within tile %d.\n', lastInfo.lastTile);
    fprintf('Restarting from: %s\n', lastInfo.lastFile);

end

end
