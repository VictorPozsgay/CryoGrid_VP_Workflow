function PATHS = initialize_CryoGrid_VP()
%INITIALIZE_CRYOGRID_VP Initialize the CryoGrid VP workflow.
%
%   PATHS = INITIALIZE_CRYOGRID_VP() initializes the MATLAB environment
%   for the CryoGrid VP workflow and returns the repository paths in the
%   structure PATHS.
%
%   The function is fully portable and does not rely on machine-specific
%   absolute paths. The CryoGrid repository root is located automatically
%   by traversing upward from the location of this function until the
%   "CryoGrid" directory is found.
%
%   The function:
%       1. Locates the CryoGrid repository root.
%       2. Locates the CryoGridCommunity_source/source directory.
%       3. Adds the CryoGrid source tree to the MATLAB path.
%       4. Adds the CryoGridCommunity_run directory and its subfolders
%          to the MATLAB path.
%       5. Returns the workflow paths using VP_RETURN_PATHS.
%
%   Output:
%       PATHS - Structure containing the main paths used by the CryoGrid
%               VP workflow. See VP_RETURN_PATHS for the fields provided.
%
%   Example:
%       PATHS = initialize_CryoGrid_VP();
%
%       forcing_path = PATHS.FORCING.root;
%       results_path = PATHS.RESULTS.root;
%
%   See also VP_RETURN_PATHS, ADDPATH, GENPATH.
%
%   ---------------------------------------------------------------------
%   CryoGrid VP workflow
%   ---------------------------------------------------------------------

    [file_path,file_name] = fileparts(mfilename('fullpath'));

    while ~strcmp(file_name,'CryoGrid')

        [file_path,file_name] = fileparts(file_path);

        repo_root = char(fullfile(file_path,file_name));

    end

    source_path = fullfile( ...
        repo_root, ...
        'CryoGridCommunity_source', ...
        'source');

    if ~isfolder(source_path)

        error('CryoGrid source folder not found:\n%s',source_path);

    end

    % Add CryoGrid source code to the MATLAB path.
    addpath(genpath(source_path));

    % Add CryoGridCommunity_run and all run utilities to the MATLAB path.
    addpath(genpath(file_path));

    % Return the paths used by the VP workflow.
    PATHS = VP_return_paths(repo_root);

end