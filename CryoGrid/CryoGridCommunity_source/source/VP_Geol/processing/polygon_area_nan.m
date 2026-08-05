function A = polygon_area_nan(X,Y)
%POLYGON_AREA_NAN Compute polygon area from NaN-separated rings.
%
% First ring is outer boundary.
% Following rings are holes and are subtracted.

sep = isnan(X) | isnan(Y);
edges = [0; find(sep(:)); numel(X)+1];
A = 0;
ring = 0;

for i = 1:numel(edges)-1
    ind = edges(i)+1 : edges(i+1)-1;
    if numel(ind)<3
        continue
    end
    xx = X(ind);
    yy = Y(ind);
    ring_area = polyarea(xx,yy);
    ring = ring + 1;
    if ring == 1
        A = A + ring_area;
    else
        A = A - ring_area;
    end

end

end