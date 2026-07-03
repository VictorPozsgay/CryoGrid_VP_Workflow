function merge_TOA(era_path)
%MERGE_TOA Concatenate ERA5 TOA NetCDF files into a single MAT file.
%
% DESCRIPTION
%   Reads all ERA5 TOA NetCDF files (era5_toa_*.nc), concatenates the
%   shortwave radiation (tisr) along time, converts valid_time into
%   datetime (UTC), and stores the full dataset in:
%
%       ERA5_TOA_all.mat
%
%   The output contains:
%       ERA5.tisr  [lon × lat × time]
%       ERA5.time  [datetime]
%       ERA5.lon   [vector]
%       ERA5.lat   [vector]
%
% INPUT
%   era_path   Path to ERA5 data folder containing "raw/" NetCDF files.
%
% OUTPUT
%   Saves ERA5_TOA_all.mat in era_path/raw/
%
% See also read_nc_time, bilinear_interp_TOA_massifs.

nc_data_folder = fullfile(era_path,"raw\");

if isfile(fullfile(nc_data_folder,'ERA5_TOA_all.mat'))
    fprintf('The merged TOA file ERA5_TOA_all.mat already exists. Skipping.\n');
    return
end

files = dir(fullfile(nc_data_folder,"era5_toa_*.nc"));
[~,idx] = sort({files.name});
files = files(idx);

function time_dt = read_nc_time(fname,varname)

time_raw = ncread(fname,varname);
info = ncinfo(fname,varname);

units = "";
for i = 1:length(info.Attributes)
    if strcmp(info.Attributes(i).Name,'units')
        units = info.Attributes(i).Value;
    end
end

tok = regexp(units,'(\w+)\s+since\s+(.+)','tokens','once');

baseUnit = lower(tok{1});
refDate  = datetime(tok{2},'TimeZone','UTC');

switch baseUnit
    case "seconds"
        time_dt = refDate + seconds(time_raw);
    case "hours"
        time_dt = refDate + hours(time_raw);
    case "days"
        time_dt = refDate + days(time_raw);
    otherwise
        error("Unsupported unit: %s",baseUnit)
end

time_dt.TimeZone = "UTC";

end

ERA5.tisr = [];
ERA5.time = [];

for k = 1:length(files)

    fname = fullfile(files(k).folder, files(k).name);

    time_dt = read_nc_time(fname,'valid_time');

    ERA5.time = [ERA5.time; time_dt];
    ERA5.tisr = cat(3, ERA5.tisr, ncread(fname,'tisr'));

end

ERA5.lat = ncread(fname,'latitude');
ERA5.lon = ncread(fname,'longitude');

save(fullfile(nc_data_folder,'ERA5_TOA_all.mat'),'ERA5','-v7.3')

end
