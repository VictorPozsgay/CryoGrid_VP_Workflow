function prepare_forcing(forcing_path)
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
%     2. Read and concatenate yearly ERA5 TOA NetCDF files into a single
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
%   forcing_path
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

addpath(genpath(fileparts(mfilename('fullpath'))));

safran_path     = fullfile(forcing_path,"SAFRAN");
era5_path       = fullfile(forcing_path,"ERA5");
output_path     = fullfile(forcing_path,"CryoGrid_ready");
diagnostic_path = fullfile(forcing_path,"forcing_diagnostics");

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

%% Step 1

print_step(1,"Read SAFRAN forcing")
build_SAFRAN_per_massif(safran_path)

%% Step 2

print_step(2,"Read ERA5 TOA")
build_ERA5_toa(era5_path)

%% Step 3

print_step(3,"Interpolate ERA5 TOA to SAFRAN massifs")
interpolate_ERA5_to_massifs(era5_path,safran_path)

%% Step 4

print_step(4,"Merge SAFRAN and ERA5 forcing")
merge_SAFRAN_ERA5(era5_path,safran_path,output_path)

%% Step 5

print_step(5,"Build CryoGrid forcing collection")
build_combined_forcing(output_path)

%% Step 6

print_step(6,"CryoGrid forcing validation")
build_full_validation(output_path,diagnostic_path)