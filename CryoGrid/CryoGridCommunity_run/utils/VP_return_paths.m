function PATHS = VP_return_paths(repo_root)
%VP_RETURN_PATHS Return paths used by the CryoGrid VP workflow.
%
%   PATHS = VP_RETURN_PATHS(REPO_ROOT) constructs and returns the main
%   paths used by the CryoGrid VP workflow from the supplied CryoGrid
%   repository root.
%
%   The returned structure groups paths according to their role:
%
%       PATHS.CG_ROOT_PATH
%           Root directory of the CryoGrid repository.
%
%       PATHS.FORCING
%           Paths to CryoGridCommunity_forcing and its main subfolders:
%           meteo, geology and DEM.
%
%       PATHS.SOURCE
%           Paths to CryoGridCommunity_source and the VP source modules:
%           VP_Meteo, VP_Geol and VP_DEM.
%
%       PATHS.RESULTS
%           Path to CryoGridCommunity_results.
%
%       PATHS.RUN
%           Path to CryoGridCommunity_run.
%
%       PATHS.meteo_path
%           VP meteorological source path.
%
%       PATHS.dem_path
%           VP DEM source path.
%
%       PATHS.geology_path
%           VP geology source path.
%
%       PATHS.safran_shp
%           Path to the SAFRAN massif shapefile.
%
%   Input:
%       repo_root - Absolute path to the root of the CryoGrid repository.
%
%   Output:
%       PATHS - Structure containing the paths used by the CryoGrid
%               VP workflow.
%
%   Example:
%       repo_root = 'D:\Projects\CryoGrid';
%       PATHS = VP_return_paths(repo_root);
%
%       PATHS.FORCING.dem
%       PATHS.RESULTS.root
%       PATHS.safran_shp
%
%   See also INITIALIZE_CRYOGRID_VP.
%
%   ---------------------------------------------------------------------
%   CryoGrid VP workflow
%   ---------------------------------------------------------------------

    PATHS.CG_ROOT_PATH = repo_root;

    % CryoGrid forcing data.
    PATHS.FORCING.root    = char(fullfile( ...
        PATHS.CG_ROOT_PATH,"CryoGridCommunity_forcing"));

    PATHS.FORCING.meteo   = char(fullfile( ...
        PATHS.FORCING.root,"meteo"));

    PATHS.FORCING.geology = char(fullfile( ...
        PATHS.FORCING.root,"geology"));

    PATHS.FORCING.dem     = char(fullfile( ...
        PATHS.FORCING.root,"DEM"));

    % CryoGrid source code and VP modules.
    PATHS.SOURCE.root = char(fullfile( ...
        PATHS.CG_ROOT_PATH,"CryoGridCommunity_source"));

    PATHS.SOURCE.meteo = char(fullfile( ...
        PATHS.SOURCE.root,"source","VP_Meteo"));

    PATHS.SOURCE.geology = char(fullfile( ...
        PATHS.SOURCE.root,"source","VP_Geol"));

    PATHS.SOURCE.dem = char(fullfile( ...
        PATHS.SOURCE.root,"source","VP_DEM"));

    % CryoGrid results and run directories.
    PATHS.RESULTS.root = char(fullfile( ...
        PATHS.CG_ROOT_PATH,"CryoGridCommunity_results"));

    PATHS.RUN.root = char(fullfile( ...
        PATHS.CG_ROOT_PATH,"CryoGridCommunity_run"));

    % Convenience paths.
    PATHS.meteo_path   = PATHS.SOURCE.meteo;
    PATHS.dem_path     = PATHS.SOURCE.dem;
    PATHS.geology_path = PATHS.SOURCE.geology;

    % SAFRAN massif shapefile.
    PATHS.safran_shp = char(fullfile( ...
        PATHS.meteo_path, ...
        "SAFRAN","shapefile","massifs_alpes_2154.shp"));

end