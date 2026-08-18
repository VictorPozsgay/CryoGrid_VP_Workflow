function prepare_forcing(meteo_path,varargin)
%PREPARE_FORCING Build CryoGrid-ready forcing datasets from SAFRAN and ERA5.
%
% DESCRIPTION
%   Runs the complete preprocessing workflow required to generate
%   CryoGrid-ready forcing datasets from raw SAFRAN meteorological forcing
%   and ERA5 top-of-atmosphere (TOA) radiation.
%
%   The workflow performs the following steps:
%
%     1. Read and concatenate yearly SAFRAN NetCDF files, producing one
%        forcing file for each massif/elevation/slope/aspect combination.
%
%     2. Optionally download ERA5 top-of-atmosphere radiation and then read
%        and concatenate yearly ERA5 TOA NetCDF files into a single
%        continuous dataset.
%
%     3. Interpolate ERA5 TOA radiation to the centroid of each SAFRAN
%        massif.
%
%     4. Merge the SAFRAN and ERA5 datasets into individual CryoGrid-ready
%        forcing files.
%
%     5. Build a single MAT file containing all forcing structures for
%        convenient loading by CryoGrid workflows.
%
% INPUT
%   meteo_path
%       Path to the forcing dataset root directory:
%
%           meteo/
%               SAFRAN/
%               ERA5/
%               CryoGrid_ready/
%
%       The SAFRAN and ERA5 directories must contain the required raw input
%       datasets. Intermediate folders (such as per_massif/) and the final
%       CryoGrid_ready/ directory are created automatically when needed.
%
% OPTIONS
%   'DownloadS2M'
%       Logical flag indicating whether the S2M/SAFRAN meteorological
%       forcing data should be acquired automatically.
%
%       If false, the workflow assumes that the required S2M/SAFRAN
%       forcing files and associated shapefiles already exist in the
%       forcing directory.
%
%       If true, the S2M/SAFRAN acquisition workflow is performed.
%       The email address required for the acquisition is specified
%       through the 'Email' option.
%
%       default = false
%
%       Example:
%           prepare_forcing(meteo_path,'DownloadS2M',true)
%
%
%   'Email'
%       Email address used for the S2M/SAFRAN data acquisition when
%       'DownloadS2M' is true.
%
%       If 'DownloadS2M' is false, this option is ignored.
%
%       default = 'none'
%
%       Example:
%           prepare_forcing(meteo_path, ...
%               'DownloadS2M',true, ...
%               'Email','<name>@<extension>')
%
%
%   'DownloadERA5'
%       Logical flag indicating whether ERA5 top-of-atmosphere (TOA)
%       radiation data should be downloaded automatically using the
%       CDS API.
%
%       If false, the workflow assumes that the required ERA5 NetCDF
%       files already exist in the forcing directory.
%
%       If true, the ERA5 acquisition script is called through MATLAB
%       using the Python executable specified by 'PythonExecutable'.
%
%       default = false
%
%       Example:
%           prepare_forcing(meteo_path,'DownloadERA5',true)
%
%
%   'PythonExecutable'
%       Path to the Python executable used to run the ERA5 CDS API
%       acquisition script.
%
%       This option is only required when 'DownloadERA5' is true.
%       If 'DownloadERA5' is false, this option is ignored.
%
%       default = ''
%
%       Example:
%           prepare_forcing(meteo_path, ...
%               'DownloadERA5',true, ...
%               'PythonExecutable',"C:\...\python.exe")
% 
% OUTPUT
%   Creates:
%
%       SAFRAN/per_massif/
%           Individual SAFRAN forcing files.
%
%       ERA5/per_massif/
%           ERA5 TOA radiation interpolated to SAFRAN massifs.
%
%       CryoGrid_ready/
%           Final CryoGrid-ready forcing files together with a combined
%           forcing collection.
%
% SEE ALSO
%   READ_SAFRAN, MERGE_TOA, BILINEAR_INTERP_TOA_MASSIFS,
%   MERGE_SAFRAN_ERA, ALL_FORCING_TOGETHER.

% Options
p = inputParser;

addParameter(p,"DownloadS2M",false,@(x)islogical(x) && isscalar(x));
addParameter(p,"Email",'none',@(x)ischar(x) || isstring(x));

addParameter(p,"DownloadERA5",false,@(x)islogical(x) && isscalar(x));
addParameter(p,"PythonExecutable",'',@(x)ischar(x) || isstring(x));

parse(p,varargin{:});

download_s2m       = p.Results.DownloadS2M;
email_address      = p.Results.Email;

download_era5      = p.Results.DownloadERA5;
python_executable  = p.Results.PythonExecutable;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RESTART FROM HERE WITH THE PYTHON FROM MATLAB SCRIPT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath(fileparts(mfilename('fullpath'))));

safran_path     = fullfile(meteo_path,"SAFRAN");
era5_path       = fullfile(meteo_path,"ERA5");
output_path     = fullfile(meteo_path,"CryoGrid_ready");
diagnostic_path = fullfile(meteo_path,"forcing_diagnostics");

folders_to_create = {
    fullfile(safran_path,"per_massif")
    fullfile(era5_path,"per_massif")
    output_path
    diagnostic_path
    };

for i = 1:numel(folders_to_create)
    if ~isfolder(folders_to_create{i})
        mkdir(folders_to_create{i})
    end
end

%% Step 0

print_step(0,"Download SAFRAN (S2M) forcing")
if download_s2m
    if strcmp(email_address,'none') || strlength(string(email_address)) == 0
        error([ ...
            'DownloadS2M is enabled, but no email address was provided. ' ...
            'Specify the ''Email'' option.']);
    end
    download_S2M_data(meteo_path,email_address)
else
    disp('Skipping S2M download. Assuming the data already exists.')
end

%% Step 0.5

print_step(0.5,"Download ERA5 TOA radiation")
if download_era5
    if isempty(python_executable)
        error([ ...
            'DownloadERA5 is enabled, but no Python executable was provided. ' ...
            'Specify the ''PythonExecutable'' option.']);
    end
    download_ERA5_TOA(python_executable)
else
    disp('Skipping ERA5 download. Assuming the data already exists.')
end

% %% Step 1
% 
% print_step(1,"Read SAFRAN forcing")
% build_SAFRAN_per_massif(safran_path)
% 
% %% Step 2
% 
% print_step(2,"Read ERA5 TOA")
% build_ERA5_toa(era5_path)
% 
% %% Step 3
% 
% print_step(3,"Interpolate ERA5 TOA to SAFRAN massifs")
% interpolate_ERA5_to_massifs(era5_path,safran_path)
% 
% %% Step 4
% 
% print_step(4,"Merge SAFRAN and ERA5 forcing")
% merge_SAFRAN_ERA5(era5_path,safran_path,output_path)
% 
% %% Step 5
% 
% print_step(5,"Build CryoGrid forcing collection")
% build_combined_forcing(output_path)
% 
% %% Step 6
% 
% print_step(6,"CryoGrid forcing validation")
% build_full_validation(output_path,diagnostic_path)