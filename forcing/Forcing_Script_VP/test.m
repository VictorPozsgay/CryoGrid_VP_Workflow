era_path = "..\..\forcing\Forcing_Data\meteo\era5";
safran_path = "..\..\forcing\Forcing_Data\meteo\safran";
out_path = "..\..\forcing\Forcing_Data\meteo\CryoGrid_ready";

%% Step 1: SAFRAN

fprintf('--------------------------\n')
fprintf('--------- STEP 1 ---------\n')
fprintf('--------------------------\n')
fprintf('\n')

% Concatenate all years and split by (massif/elevation/slope/aspect)
read_safran(safran_path)

%% Step 2: ERA5 / TOA

fprintf('\n')
fprintf('--------------------------\n')
fprintf('--------- STEP 2 ---------\n')
fprintf('--------------------------\n')
fprintf('\n')

% Concatenate all years
merge_TOA(era_path)

fprintf('\n')
fprintf('--------------------------\n')
fprintf('--------- STEP 3 ---------\n')
fprintf('--------------------------\n')
fprintf('\n')

% Split by massifs
bilinear_interp_TOA_massifs(era_path,safran_path)

%% Step

fprintf('\n')
fprintf('--------------------------\n')
fprintf('--------- STEP 4 ---------\n')
fprintf('--------------------------\n')
fprintf('\n')

merge_safran_era(era_path,safran_path,out_path)
