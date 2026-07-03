safran_path = "..\..\forcing\Forcing_Data\meteo\safran";
% lat = 45.832680732450456;
% lon = 6.864715384539419;

% lat = 44.92055267330358;
% lon = 6.263247068209718;

T = safran_massif_to_coord(safran_path);

for i = 1:size(T,1)
    [massif_id, massif_name] = get_safran_massif(safran_path, T(i).lat, T(i).lon);
    disp(["i" i])
    disp(["massif_id" massif_id])
    disp(["massif_name" massif_name])
end
