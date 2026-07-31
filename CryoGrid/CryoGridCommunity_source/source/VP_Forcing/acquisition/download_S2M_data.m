function download_S2M_data(forcing_path)
%DOWNLOAD_S2M_DATA Download raw SAFRAN S2M forcing and massif shapefiles from AERIS.
%
% DESCRIPTION
%   Runs the complete acquisition workflow required to obtain the raw
%   SAFRAN S2M meteorological reanalysis and the associated massif
%   shapefiles from the AERIS/SEDOO data centre, ready to be consumed by
%   the rest of the forcing preprocessing workflow (see PREPARE_FORCING).
%
%   The workflow performs the following steps:
%
%     1. Submit the S2M order (Alps, flat geometry, meteo product,
%        dataset version 2024.1, full 1958-2023 period) to the AERIS
%        REST API. The download link is emailed by AERIS and is not
%        returned directly by the API, so this step pauses and asks the
%        user to paste the file name found in the confirmation email.
%
%     2. Download and extract the SAFRAN archive, keep only the
%        FORCING_*.nc files, and discard the now-empty alp_flat/ folder
%        created by the extraction.
%
%     3. Download the massif shapefiles (direct download, no order or
%        email required), keep only the Alps massif files, and discard
%        the station shapefiles and intermediate archives.
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
%       The SAFRAN directory is created automatically if it does not
%       already exist.
%
% OUTPUT
%   Creates:
%
%       SAFRAN_test/raw/
%           FORCING_*.nc files, one per year, covering 1958-2023.
%
%       SAFRAN_test/shapefile/
%           Alps massif shapefile (massifs_alpes_2154.shp and
%           associated .cpg/.dbf/.prj/.qpj/.shx files).
%
% SEE ALSO
%   PREPARE_FORCING, BUILD_SAFRAN_PER_MASSIF.

addpath(genpath(fileparts(mfilename('fullpath'))));

orderApiUrl     = "https://api.sedoo.fr/aeris-s2m-rest/data/download/865730e8-edeb-4c6b-ae58-80f95166509b";
downloadBaseUrl = "https://api.sedoo.fr/aeris-s2m-rest/data/download/";
shapefileUrl    = "https://api.sedoo.fr/aeris-s2m-rest/data/download/files/shapefiles";
emailAddress    = "victor.pozsgay@univ-smb.fr";

safran_path = fullfile(forcing_path,"SAFRAN_test");
raw_path    = fullfile(safran_path,"raw");
shape_path  = fullfile(safran_path,"shapefile");

folders_to_create = {
    safran_path
    raw_path
    shape_path
    };
for i = 1:numel(folders_to_create)
    if ~isfolder(folders_to_create{i})
        mkdir(folders_to_create{i})
    end
end

%% Step 1
print_step(1,"Submit S2M order")
% years = arrayfun(@(y) string(y), 1958:2023);
years = arrayfun(@(y) string(y), 1958:1959);
payload = struct();
payload.areas = struct();
payload.areas.alp_flat = struct();
payload.areas.alp_flat.meteo = struct();
payload.areas.alp_flat.meteo.files = years;
payload.datasetVersion = "2024.1";
payload.email = emailAddress;

opts = weboptions('MediaType', 'application/json', 'Timeout', 60, 'ContentType', 'text');
response = webwrite(orderApiUrl, payload, opts);
fprintf("Order submitted: %s\n", response);
fprintf("Check %s for the confirmation email (usually within minutes, link expires after 4 days).\n", emailAddress);

fileNamePattern = '^[a-f0-9-]+\.zip$';
while true
    raw = strtrim(input("\nPaste just the 'File name' from the email (e.g. 5ecf33e8-...-c34c.zip): ", 's'));
    parts = strsplit(raw, "/");
    candidate = parts{end};
    if ~isempty(regexp(candidate, fileNamePattern, 'once'))
        fileName = candidate;
        break
    end
    disp("That doesn't look like a valid file name, please try again.");
end

%% Step 2
print_step(2,"Download and extract SAFRAN forcing")
url = downloadBaseUrl + fileName;
zipPath = fullfile(raw_path, fileName);
fprintf("Downloading from %s ...\n", url);
websave(zipPath, url);
fprintf("Downloaded: %s\n", zipPath);

fprintf("Extracting...\n");
unzip(zipPath, raw_path);
delete(zipPath);

ncFiles = dir(fullfile(raw_path, "alp_flat", "meteo", "FORCING_*.nc"));
for k = 1:numel(ncFiles)
    src = fullfile(ncFiles(k).folder, ncFiles(k).name);
    dst = fullfile(raw_path, ncFiles(k).name);
    movefile(src, dst);
end
fprintf("Moved %d FORCING file(s) to %s\n", numel(ncFiles), raw_path);

rmdir(fullfile(raw_path, "alp_flat"), 's');
fprintf("Removed alp_flat/ (moved files only).\n");

%% Step 3
print_step(3,"Download massif shapefiles")
shapefileZipPath = fullfile(shape_path, "s2m_shapefiles.zip");
fprintf("Downloading shapefiles from %s ...\n", shapefileUrl);
websave(shapefileZipPath, shapefileUrl);
fprintf("Downloaded: %s\n", shapefileZipPath);

fprintf("Extracting shapefiles...\n");
unzip(shapefileZipPath, shape_path);
delete(shapefileZipPath);

stationsZipPath = fullfile(shape_path, "stations_shapefiles.zip");
if exist(stationsZipPath, 'file')
    delete(stationsZipPath);
end

massifsZipPath = fullfile(shape_path, "massifs_shapefiles.zip");
massifsTempDir = fullfile(shape_path, "massifs_tmp");
unzip(massifsZipPath, massifsTempDir);
delete(massifsZipPath);

allFiles = dir(fullfile(massifsTempDir, "**", "*.*"));
allFiles = allFiles(~[allFiles.isdir]);
for k = 1:numel(allFiles)
    if contains(lower(allFiles(k).name), "alpes")
        movefile(fullfile(allFiles(k).folder, allFiles(k).name), fullfile(shape_path, allFiles(k).name));
    end
end
rmdir(massifsTempDir, 's');
fprintf("Shapefiles extracted to: %s\n", shape_path);

end