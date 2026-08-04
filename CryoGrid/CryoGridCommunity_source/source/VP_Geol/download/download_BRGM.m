function download_BRGM(raw_path)
%DOWNLOAD_BRGM Download BRGM GEO050K_HARM data.
%
% Downloads the official BRGM harmonized geological maps at 1:50,000 scale.
%
% Data are stored as:
%
%   raw_path/
%       <department>/
%
% Existing departments are skipped automatically.
%
%
% INPUT
%
%   raw_path
%       Destination folder for raw BRGM data.
%

if ~exist(raw_path,"dir")
    mkdir(raw_path)
end

departments = departments_list();

for i = 1:numel(departments)
    download_department(raw_path,departments(i));
end

end