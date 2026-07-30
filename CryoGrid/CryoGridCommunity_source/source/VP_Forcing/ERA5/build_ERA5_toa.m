function build_ERA5_toa(era5_path)
%BUILD_ERA5_TOA Concatenate yearly ERA5 TOA radiation files.
%
% DESCRIPTION
%   Reads all ERA5 top-of-atmosphere (TOA) shortwave radiation NetCDF files
%   contained in ERA5/raw/, converts the accumulated total incoming solar
%   radiation to instantaneous fluxes, concatenates them along the time
%   dimension and stores the resulting continuous dataset.
%
%   ERA5 provides total incoming solar radiation (tisr) as accumulated
%   energy over the forecast timestep:
%
%       tisr : J m^-2
%
%   Since the ERA5 files used here have an hourly timestep, the variable is
%   converted to an instantaneous radiation flux:
%
%       S_TOA : W m^-2
%
%       S_TOA = tisr / 3600
%
%   The output dataset is saved as:
%
%       ERA5/merged/ERA5_TOA_all.mat
%
%   containing:
%
%       ERA5.S_TOA
%           [longitude x latitude x time] incoming shortwave radiation
%           at the top of atmosphere (W m^-2)
%
%       ERA5.time
%           datetime vector in UTC
%
%       ERA5.lon
%           longitude coordinates
%
%       ERA5.lat
%           latitude coordinates
%
%
% INPUT
%   era5_path
%       Path to the ERA5 directory containing:
%
%           raw/
%               era5_toa_*.nc
%
%
% OUTPUT
%   Creates:
%
%       ERA5/merged/ERA5_TOA_all.mat
%
%
% NOTES
%   - The conversion from accumulated energy (J m^-2) to flux (W m^-2)
%     assumes an hourly ERA5 timestep.
%
%   - The resulting S_TOA variable is directly compatible with the SAFRAN
%     forcing variables (Sin, Lin, etc.) used by CryoGrid.
%
%
% SEE ALSO
%   PREPARE_FORCING, READ_NC_TIME,
%   INTERPOLATE_ERA5_TO_MASSIFS.


%% Paths

raw_path    = fullfile(era5_path,"raw");
merged_path = fullfile(era5_path,"merged");

if ~isfolder(merged_path)
    mkdir(merged_path)
end

output_file = fullfile(merged_path,"ERA5_TOA_all.mat");


%% Check existing output

if isfile(output_file)

    fprintf('ERA5 TOA merged file already exists:\n')
    fprintf('  %s\n',output_file)
    fprintf('Skipping build_ERA5_toa().\n')

    return

end


%% Find ERA5 files

files = dir(fullfile(raw_path,"era5_toa_*.nc"));

if isempty(files)
    error("No ERA5 TOA NetCDF files found in %s.",raw_path)
end


% Sort chronologically
[~,idx] = sort({files.name});
files = files(idx);


Nfiles = numel(files);

fprintf('Found %d ERA5 TOA files.\n',Nfiles)


%% Read and concatenate

ERA5 = struct();

ERA5.S_TOA = [];
ERA5.time = [];


for k = 1:Nfiles

    fprintf('Reading ERA5 TOA file %d / %d : %s\n',...
        k,Nfiles,files(k).name)


    filepath = fullfile(files(k).folder,files(k).name);


    % Time
    time = read_nc_time(filepath,'valid_time');


    % Radiation
    %
    % ERA5 tisr is accumulated energy (J m^-2)
    % Convert hourly accumulated energy to flux (W m^-2)

    tisr = ncread(filepath,'tisr');

    S_TOA = tisr / 3600;


    ERA5.time = [ERA5.time; time];

    ERA5.S_TOA = cat(3,ERA5.S_TOA,S_TOA);


end


%% Coordinates

ERA5.lon = ncread(filepath,'longitude');
ERA5.lat = ncread(filepath,'latitude');


%% Ensure UTC

ERA5.time.TimeZone = "UTC";


%% Save

save(output_file,'ERA5','-v7.3')


fprintf('ERA5 TOA dataset written:\n')
fprintf('  %s\n',output_file)

end