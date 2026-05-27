function last_date = get_last_forcing_date(file)
% get_last_forcing_date
%   Returns the last available date in a CryoGrid forcing file.
%
% INPUT :
%   - file : path to a .mat file containing FORCING.data.Tair
%
% OUTPUT :
%   - last_date : datetime of the last measurement

    % --- Fixed parameters ---
    reference_date = datetime(1958, 8, 1);
    measurements_per_day = 8;

    % Load data
    data = load(file);
    if ~isfield(data, 'FORCING') || ~isfield(data.FORCING, 'data') || ~isfield(data.FORCING.data, 'Tair')
        error('❌ The file does not contain the expected FORCING.data.Tair structure.');
    end

    Tair = data.FORCING.data.Tair(:);  % Ensure column vector
    N = length(Tair);

    % Estimate the total number of days
    estimated_days = ceil(N / measurements_per_day);

    % Compute the last date
    last_date = reference_date + days(estimated_days - 2);

    fprintf('ℹ️ Last available date in forcing file: %s\n', datestr(last_date));
end