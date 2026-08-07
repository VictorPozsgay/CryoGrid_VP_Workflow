function [DEM,mask_out,Rout] = merge_dem_chunks( ...
        DEM,mask_out,Rout,...
        Z,no_valid,R)

%% First chunk

if isempty(DEM)

    DEM = Z;
    mask_out = no_valid;
    Rout = R;

    return

end



resolution = Rout.CellExtentInWorldX;


if abs(R.CellExtentInWorldX-resolution)>1e-6
    error("Chunk resolutions do not match")
end



%% Common extent

xmin=min(Rout.XWorldLimits(1),R.XWorldLimits(1));
xmax=max(Rout.XWorldLimits(2),R.XWorldLimits(2));

ymin=min(Rout.YWorldLimits(1),R.YWorldLimits(1));
ymax=max(Rout.YWorldLimits(2),R.YWorldLimits(2));



nx=round((xmax-xmin)/resolution);
ny=round((ymax-ymin)/resolution);



Rnew = maprefcells( ...
    [xmin xmax],...
    [ymin ymax],...
    [ny nx],...
    "RowsStartFrom","west",...
    "ColumnsStartFrom","north");



DEMnew = -9999*ones(ny,nx,'single');
masknew = true(ny,nx);



%% Insert old

[DEMnew,masknew]=insert_chunk(...
    DEMnew,...
    masknew,...
    DEM,...
    mask_out,...
    Rnew,...
    Rout);



%% Insert new

[DEMnew,masknew]=insert_chunk(...
    DEMnew,...
    masknew,...
    Z,...
    no_valid,...
    Rnew,...
    R);



DEM=DEMnew;
mask_out=masknew;
Rout=Rnew;


end



function [DEMout,maskout]=insert_chunk(...
    DEMout,maskout,Z,no_valid,Rout,R)


resolution=Rout.CellExtentInWorldX;


col0=round(...
    (R.XWorldLimits(1)-Rout.XWorldLimits(1))/resolution)+1;


row0=round(...
    (Rout.YWorldLimits(2)-R.YWorldLimits(2))/resolution)+1;


rows=row0:(row0+size(Z,1)-1);
cols=col0:(col0+size(Z,2)-1);



% DEM values

DEMout(rows,cols)=Z;


% Quality mask union

maskout(rows,cols)= ...
    maskout(rows,cols) | no_valid;


end