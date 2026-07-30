function time_dt = read_nc_time(filename,varname)
%READ_NC_TIME Convert NetCDF time variable to MATLAB datetime.
%
% DESCRIPTION
%   Reads a NetCDF time variable and converts it into a MATLAB datetime
%   vector using the "units" attribute.
%
%   Supported units:
%
%       seconds since YYYY-MM-DD HH:MM:SS
%       hours   since YYYY-MM-DD HH:MM:SS
%       days    since YYYY-MM-DD HH:MM:SS
%
%   The returned datetime is always expressed in UTC.
%
%
% INPUTS
%   filename
%       NetCDF file path.
%
%   varname
%       Name of the time variable.
%
%
% OUTPUT
%   time_dt
%       MATLAB datetime vector in UTC.
%
%
% SEE ALSO
%   BUILD_ERA5_TOA.


%% Read raw time

time_raw = ncread(filename,varname);

info = ncinfo(filename,varname);


%% Find units attribute

units = "";

for i = 1:numel(info.Attributes)

    if strcmp(info.Attributes(i).Name,'units')

        units = string(info.Attributes(i).Value);

        break

    end

end


if units == ""

    error("No time units attribute found for variable %s.",varname)

end


%% Parse units

tokens = regexp(units,...
    '(\w+)\s+since\s+(.+)',...
    'tokens',...
    'once');


if isempty(tokens)

    error("Cannot interpret time units: %s",units)

end


base_unit = lower(tokens{1});
reference_time = datetime(tokens{2},...
    'TimeZone','UTC');


%% Convert

switch base_unit

    case "seconds"

        time_dt = reference_time + seconds(time_raw);

    case "hours"

        time_dt = reference_time + hours(time_raw);

    case "days"

        time_dt = reference_time + days(time_raw);

    otherwise

        error("Unsupported NetCDF time unit: %s",base_unit)

end


time_dt.TimeZone = "UTC";


end