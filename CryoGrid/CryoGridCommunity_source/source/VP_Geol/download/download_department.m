function download_department(raw_path,department)
%DOWNLOAD_DEPARTMENT Download one BRGM department.
%
% Downloads and extracts:
%
%   GEO050K_HARM_<department>.zip
%
% from BRGM Infoterre.
%
% The output is:
%
%   raw_path/<department>/
%
% The function is restartable:
%
% - If the main geological shapefile exists, download is skipped.
% - Otherwise the archive is downloaded and extracted.
%
%
% INPUT
%
%   raw_path
%       Root raw geological directory.
%
%   department
%       French department code.
%

% BRGM uses 3-digit department codes
brgm_code = sprintf("%03d",str2double(department));

folder = fullfile(raw_path,brgm_code);

if ~exist(folder,"dir")
    mkdir(folder)
end

%% Checker

shp_file = fullfile(folder,...
    sprintf("GEO050K_HARM_%s_S_FGEOL_2154.shp",brgm_code));

if exist(shp_file,"file")
    fprintf( ...
        "Department %s (%s) already available. Skipping.\n",...
        department,brgm_code)
    return
end

%% Download

zip_name = sprintf("GEO050K_HARM_%s.zip",brgm_code);
zip_file = fullfile(folder,zip_name);
url = "http://infoterre.brgm.fr/telechargements/BDCharm50/" + zip_name;

fprintf("Downloading department %s (%s)\n",department,brgm_code)
websave(zip_file,url);

%% Extract

fprintf("Extracting department %s (%s)\n",department,brgm_code)
unzip(zip_file,folder);
delete(zip_file);
fprintf("Department %s (%s) completed\n",department,brgm_code)

end