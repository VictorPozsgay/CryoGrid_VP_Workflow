function download_ERA5_TOA()
%DOWNLOAD_ERA5_TOA Download ERA5 top-of-atmosphere radiation.
%
% DESCRIPTION
%   Wrapper around the Python CDS API acquisition script used to download
%   ERA5 top-of-atmosphere incoming solar radiation.
%
%   The function:
%
%       1. Loads the Python environment defined in VP_config.m.
%       2. Locates the Python acquisition script located in the same folder.
%       3. Passes the CryoGrid project root directory to Python.
%       4. Runs the restartable ERA5 yearly download routine.
%
%   Existing ERA5 files are checked by the Python script and skipped if
%   already present and valid.
%
% REQUIREMENTS
%   - Python environment with:
%         cdsapi
%         netCDF4
%
%   - Valid CDS API configuration:
%         ~/.cdsapirc
%
% CONFIGURATION
%   Python executable is defined in:
%
%       VP_config.m
%
% OUTPUT
%   Creates:
%
%       CryoGridCommunity_forcing/
%           meteo/
%               ERA5_test/
%                   raw/
%
%   containing yearly files:
%
%       era5_toa_YYYY.nc
%
% SEE ALSO
%   PREPARE_FORCING, VP_CONFIG

CFG = VP_config();

% Ensure MATLAB uses the correct Python environment
pe = pyenv;

if ~strcmp(pe.Executable,CFG.python_exe)

    if pe.Status == "Loaded"
        error(['Python is already loaded with another environment. ' ...
            'Restart MATLAB before changing pyenv.'])
    end

    pyenv("Version",CFG.python_exe);
end


% Folder containing this MATLAB function and Python script
acquisition_folder = fileparts(mfilename('fullpath'));

% CryoGrid root
cryogrid_root = fileparts(fileparts(fileparts(fileparts(acquisition_folder))));

% Python acquisition script
script = fullfile(acquisition_folder,"download_ERA5_TOA_data.py");

% Run Python acquisition
pyrunfile(script,project_root=cryogrid_root);

end