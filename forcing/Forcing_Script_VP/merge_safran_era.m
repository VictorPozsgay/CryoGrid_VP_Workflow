function merge_safran_era(era_path, safran_path, out_path)
%MERGE_SAFRAN_ERA Merge all SAFRAN forcing files with ERA5 TOA forcing.
%
% DESCRIPTION
%   Processes all SAFRAN forcing files found in the "per_massif"
%   subdirectory of safran_path. Each file is matched to the corresponding
%   ERA5 TOA forcing using its massif number, merged with
%   MERGE_SAFRAN_ERA_INDIVIDUAL, and saved to out_path.
%
%   Massifs without ERA5 TOA data (e.g. massif 30) are skipped.
%
% INPUTS
%   era_path    - Folder containing TOA_per_massif.mat.
%   safran_path - Folder containing the SAFRAN "per_massif" directory.
%   out_path    - Destination folder for merged CryoGrid-ready forcing
%                 files.
%
% EXAMPLE
%   merge_safran_era(era_path, safran_path, out_path)
%
% See also MERGE_SAFRAN_ERA_INDIVIDUAL.

era5 = load(fullfile(era_path,"per_massif\TOA_per_massif.mat"));
S = era5.S;

massif2idx = containers.Map( ...
    num2cell([S.massif_num]), ...
    num2cell(1:numel(S)));

files = dir(fullfile(safran_path,"per_massif\","*.mat"));

for k = 1:numel(files)

    file_name = files(k).name;

    fprintf('Processing %d / %d : %s\n', ...
        k, numel(files), file_name)

    if isfile(fullfile(out_path,file_name))
        fprintf('Skipping existing file.\n');
        continue
    end

    tok = regexp(file_name,...
        'massif_(\d+)_elevation',...
        'tokens','once');

    massif_num = str2double(tok{1});
    fprintf('massif %d\n',massif_num);

    if ~isKey(massif2idx,massif_num)
        fprintf('Skipping massif %d\n',massif_num);
        continue
    end

    safran = load(fullfile(files(k).folder,file_name));
    Smassif = S(massif2idx(massif_num));

    FORCING = merge_safran_era_individual(safran.FORCING,Smassif);
    save(fullfile(out_path,file_name),"FORCING","-v7.3")

end

end
