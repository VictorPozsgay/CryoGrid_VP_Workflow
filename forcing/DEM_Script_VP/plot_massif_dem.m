function plot_massif_dem(dem_folder)
%PLOT_MASSIF_DEM Plot and save all cropped massif DEMs.
%
% DESCRIPTION
%   Creates one PNG figure per massif showing:
%       - DEM elevation
%       - massif boundary
%       - colorbar
%
%   A final figure containing all massif outlines is also generated,
%   together with a DEM plot of the original DEM data.
%
% INPUTS
%   dem_folder
%       Folder with the following structure
%       dem_folder/
%           Alps/                     containing origianl DEM tif file.
%           massifs/                  containing DEM_massif_*.tif files.
%           shapefile_massifs_SAFRAN/ containing SAFRAN shapefile.
%           plots/                    folder where figures are saved.
%
%
% OUTPUT
%   output_folder/
%       DEM_all.png
%       DEM_massif_<id>.png
%       DEM_all_massifs.png
%
% V. Pozsgay, 2026

full_dem_file = fullfile(dem_folder,"Alps\MNT10m_Alps_from_LidarHD20CM_ign_v2.tif");
dem_massifs_folder = fullfile(dem_folder,"massifs");
output_folder = fullfile(dem_folder,"plots");
shapefile_file = fullfile(dem_folder,"shapefile_massifs_SAFRAN\massifs_alpes_2154.shp");

if ~exist(output_folder,'dir')
    mkdir(output_folder)
end

S = shaperead(shapefile_file);

%% =====================================================================
% Original DEM
% ======================================================================

[Z,~] = readgeoraster(full_dem_file);

fig = figure('Visible','off');

imagesc(Z(1:10:end,1:10:end));
axis image tight;
colormap(turbo);
cb = colorbar;
cb.Label.String = 'Elevation (m)';
title('DEM');

exportgraphics(fig, ...
    fullfile(output_folder,'DEM_all.png'), ...
    'Resolution',300);

close(fig);

%% =====================================================================
% Individual massif plots
% ======================================================================

files = dir(fullfile(dem_massifs_folder,'DEM_massif_*.tif'));

for k = 1:numel(files)

    fprintf('Plotting massif %d / %d\n',k,numel(files))

    dem_file = fullfile(files(k).folder,files(k).name);

    tok = regexp(files(k).name,...
        'DEM_massif_(\d+)\.tif',...
        'tokens','once');

    massif_num = str2double(tok{1});

    idx = find([S.massif_num] == massif_num,1);

    if isempty(idx)
        continue
    end

    [Z,R] = readgeoraster(dem_file);

    % Downsample for plotting only
    step = max(1,ceil(max(size(Z))/1500));

    Zp = double(Z(1:step:end,1:step:end));

    [X,Y] = worldGrid(R);

    X = X(1:step:end,1:step:end);
    Y = Y(1:step:end,1:step:end);

    fig = figure('Visible','off');

    surf(X,Y,Zp,...
        'EdgeColor','none');

    view(2)
    axis equal tight

    colormap(turbo)
    cb = colorbar;
    cb.Label.String = 'Elevation (m)';

    hold on

    plot3(S(idx).X,...
          S(idx).Y,...
          max(Zp(:),[],'omitnan')*ones(size(S(idx).X)),...
          'k','LineWidth',1.5)

    hold off

    xlabel('Lambert-93 X (m)')
    ylabel('Lambert-93 Y (m)')

    title(sprintf('SAFRAN Massif %d - %s',...
        massif_num,...
        string(S(idx).nom)))

    exportgraphics(fig,...
        fullfile(output_folder,...
        sprintf('DEM_massif_%02d.png',massif_num)),...
        'Resolution',200)

    close(fig)

end

%% =====================================================================
% All massifs together
% ======================================================================

fig = figure;

hold on

for i = 1:numel(S)

    plot(S(i).X,...
         S(i).Y,...
         'LineWidth',1)

    xc = mean(S(i).X,'omitnan');
    yc = mean(S(i).Y,'omitnan');

    text(xc,yc,...
        num2str(S(i).massif_num),...
        'HorizontalAlignment','center')
end

axis equal
grid on

xlabel('Lambert-93 X (m)')
ylabel('Lambert-93 Y (m)')

title('SAFRAN Massifs')

exportgraphics(fig,...
    fullfile(output_folder,'DEM_all_massifs.png'),...
    'Resolution',300)

close(fig)

fprintf('\nDone.\n')

end
