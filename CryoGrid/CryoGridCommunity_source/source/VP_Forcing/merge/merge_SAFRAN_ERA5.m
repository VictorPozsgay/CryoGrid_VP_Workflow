function merge_SAFRAN_ERA5(era5_path, safran_path, output_path)
%MERGE_SAFRAN_ERA5 Merge SAFRAN forcing with ERA5 TOA radiation.
%
% DESCRIPTION
%   Combines the individual SAFRAN forcing files with the corresponding
%   ERA5 top-of-atmosphere (TOA) radiation dataset for each SAFRAN massif.
%
%   Each SAFRAN forcing file located in:
%
%       SAFRAN/per_massif/
%
%   is matched with the corresponding ERA5 TOA forcing contained in:
%
%       ERA5/per_massif/TOA_per_massif.mat
%
%   The merged CryoGrid-compatible forcing structure is saved in:
%
%       CryoGrid_ready/
%
%   Files already present in the output directory are skipped.
%
% INPUTS
%   era5_path
%       Path to the ERA5 directory containing:
%
%           per_massif/TOA_per_massif.mat
%
%   safran_path
%       Path to the SAFRAN directory containing:
%
%           per_massif/
%
%   output_path
%       Output directory for final CryoGrid-ready forcing files.
%
% OUTPUT
%   Creates one MAT file per SAFRAN forcing point containing:
%
%       FORCING
%
%   with:
%       SAFRAN meteorological forcing
%       ERA5 TOA radiation
%
% SEE ALSO
%   MERGE_SAFRAN_ERA5_INDIVIDUAL, BUILD_SAFRAN_PER_MASSIF,
%   INTERPOLATE_ERA5_TO_MASSIFS.


%% ------------------------------------------------------------------------
% Paths and input checks
% -------------------------------------------------------------------------

if ~isfolder(output_path)
    mkdir(output_path)
end

toa_file = fullfile(era5_path,...
                    "per_massif",...
                    "TOA_per_massif.mat");

if ~isfile(toa_file)
    error("Missing ERA5 TOA file: %s", toa_file)
end


%% ------------------------------------------------------------------------
% Load ERA5 TOA data
% -------------------------------------------------------------------------

data = load(toa_file);

S = data.S;


% Create fast massif lookup table
massif2idx = containers.Map( ...
    num2cell([S.massif_num]), ...
    num2cell(1:numel(S)));


%% ------------------------------------------------------------------------
% Loop over SAFRAN forcing files
% -------------------------------------------------------------------------

safran_files = dir(fullfile(safran_path,...
                            "per_massif",...
                            "*.mat"));


Nfiles = numel(safran_files);

for k = 1:Nfiles

    filename = safran_files(k).name;

    fprintf("Processing SAFRAN file %d / %d : %s\n",...
        k,Nfiles,filename)


    output_file = fullfile(output_path,filename);


    if isfile(output_file)
        fprintf("Already exists. Skipping.\n")
        continue
    end


    %% Extract massif number

    token = regexp(filename,...
        'massif_(\d+)_elevation',...
        'tokens',...
        'once');


    if isempty(token)
        warning("Cannot identify massif from %s. Skipping.",filename)
        continue
    end


    massif_num = str2double(token{1});


    %% Match ERA5 massif

    if ~isKey(massif2idx,massif_num)

        warning("No ERA5 TOA data for massif %d. Skipping.",...
            massif_num)

        continue
    end


    ERA5_massif = S(massif2idx(massif_num));


    %% Merge

    safran = load(fullfile(safran_files(k).folder,...
                           filename));


    FORCING = merge_SAFRAN_ERA5_individual( ...
        safran.FORCING,...
        ERA5_massif);


    save(output_file,"FORCING","-v7.3")

end

end