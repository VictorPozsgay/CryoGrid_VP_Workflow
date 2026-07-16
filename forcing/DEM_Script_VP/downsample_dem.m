function [Zsmall,Rsmall] = downsample_dem(Z,R,factor)

%% Downsampling factor
% 5m -> factor x 5m (e.g. 50m for factor=10)

nrows = floor(size(Z,1)/factor);
ncols = floor(size(Z,2)/factor);

Zsmall = nan(nrows,ncols);

%% Average blocks

for i = 1:nrows
    rows = (i-1)*factor+1 : i*factor;
    for j = 1:ncols
        cols = (j-1)*factor+1 : j*factor;
        block = Z(rows,cols);
        Zsmall(i,j) = mean(block,"all","omitnan");
    end
end

%% New reference

Rsmall = maprefcells( ...
    R.XWorldLimits,...
    R.YWorldLimits,...
    size(Zsmall),...
    "ColumnsStartFrom","north");

Rsmall.ProjectedCRS = R.ProjectedCRS;

end