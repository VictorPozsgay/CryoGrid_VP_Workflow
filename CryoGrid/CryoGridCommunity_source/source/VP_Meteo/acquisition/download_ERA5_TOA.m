function download_ERA5_TOA(python_executable)
%DOWNLOAD_ERA5_TOA Download ERA5 top-of-atmosphere radiation.
%
% DESCRIPTION
%   Downloads ERA5 top-of-atmosphere (TOA) incoming solar radiation using
%   the Python CDS API acquisition script.
%
%   The function:
%
%       1. Configures MATLAB to use the specified Python executable.
%       2. Locates the Python acquisition script in the same folder.
%       3. Automatically determines the CryoGrid repository root.
%       4. Passes the repository root to the Python acquisition script.
%       5. Runs the restartable ERA5 yearly download routine.
%
%   Existing ERA5 files are checked by the Python acquisition script and
%   are skipped if they are already present and valid.
%
% INPUT
%   python_executable
%       Path to the Python executable used to run the CDS API acquisition
%       script.
%
%       The Python environment must contain the required dependencies
%       listed below.
%
%       Example:
%
%           download_ERA5_TOA("C:\...\condaVP312\python.exe")
%
% REQUIREMENTS
%   Python environment with:
%
%       cdsapi
%       netCDF4
%
%   Valid CDS API configuration:
%
%       ~/.cdsapirc
%
% OUTPUT
%   Creates ERA5 top-of-atmosphere radiation files in the directory
%   defined by the Python acquisition workflow, for example:
%
%       CryoGridCommunity_forcing/
%           meteo/
%               ERA5/
%                   raw/
%
%   with yearly files of the form:
%
%       era5_toa_YYYY.nc
%
% NOTES
%   MATLAB must be restarted if a different Python environment has already
%   been loaded during the current MATLAB session. This is because MATLAB
%   cannot change the Python environment once it has been loaded.
%
% SEE ALSO
%   PREPARE_FORCING

% Ensure MATLAB uses the correct Python environment
pe = pyenv;

if ~strcmp(pe.Executable,python_executable)

    if pe.Status == "Loaded"
        error(['Python is already loaded with another environment. ' ...
            'Restart MATLAB before changing pyenv.'])
    end

    pyenv("Version",python_executable);
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