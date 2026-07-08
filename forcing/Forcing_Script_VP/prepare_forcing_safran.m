function prepare_forcing_safran(era_path, safran_path, out_path)
%PREPARE_FORCING_SAFRAN Build CryoGrid-ready forcing from SAFRAN and ERA5 data.
%
%
% DESCRIPTION
%   Runs the complete forcing preprocessing workflow:
%     1. Reads and concatenates yearly SAFRAN NetCDF files, producing one
%        forcing file per massif/elevation/slope/aspect combination.
%     2. Merges yearly ERA5 TOA NetCDF files and interpolates the TOA
%        radiation onto SAFRAN massif centroids.
%     3. Merges the SAFRAN and ERA5 datasets into CryoGrid-ready forcing
%        files and creates a single structure containing all forcings.
%
% INPUTS
%   era_path
%       Path to the ERA5 forcing directory. It must contain the
%       subdirectories:
%           raw/          ERA5 TOA NetCDF files (era5_toa_*.nc)
%           per_massif/   (created automatically if needed)
%
%   safran_path
%       Path to the SAFRAN forcing directory. It must contain:
%           raw/          Yearly SAFRAN NetCDF files
%           shapefile/    SAFRAN massif shapefile used to compute massif
%                         centroids.
%       The subdirectory per_massif/ is created/populated automatically.
%
%   out_path
%       Output directory where the final CryoGrid-ready forcing MAT files
%       and the combined forcing structure are written.
%
% SEE ALSO
%   READ_SAFRAN, READ_ERA, MERGE_SAFRAN_ERA, ALL_FORCING_TOGETHER.

%% Step 1: SAFRAN

fprintf('--------------------------\n')
fprintf('--------- STEP 1 ---------\n')
fprintf('--------- SAFRAN ---------\n')
fprintf('--------------------------\n')
fprintf('\n')

disp('Concatenate all years and split by (massif/elevation/slope/aspect)')
read_safran(safran_path)

%% Step 2: ERA5 / TOA

fprintf('\n')
fprintf('--------------------------\n')
fprintf('--------- STEP 2a --------\n')
fprintf('------- ERA5 / TOA -------\n')
fprintf('--------------------------\n')
fprintf('\n')

disp('Concatenate all years')
merge_TOA(era_path)

fprintf('\n')
fprintf('--------------------------\n')
fprintf('--------- STEP 2b --------\n')
fprintf('------- ERA5 / TOA -------\n')
fprintf('--------------------------\n')
fprintf('\n')

disp('Split by massifs')
bilinear_interp_TOA_massifs(era_path,safran_path)

%% Step 3: Merge SAFRAN + ERA5 data

fprintf('\n')
fprintf('--------------------------\n')
fprintf('--------- STEP 3a --------\n')
fprintf('--- Merge SAFRAN + ERA5 --\n')
fprintf('--------------------------\n')
fprintf('\n')

disp('build the final forcing data')
merge_safran_era(era_path,safran_path,out_path)

fprintf('\n')
fprintf('--------------------------\n')
fprintf('--------- STEP 3b --------\n')
fprintf('--- Merge SAFRAN + ERA5 --\n')
fprintf('--------------------------\n')
fprintf('\n')


disp('single structure final forcing data')
all_forcing_together(out_path)
