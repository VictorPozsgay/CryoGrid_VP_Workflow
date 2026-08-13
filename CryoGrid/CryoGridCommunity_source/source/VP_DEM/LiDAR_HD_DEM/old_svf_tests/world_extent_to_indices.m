function [r1,r2,c1,c2] = world_extent_to_indices( ...
    R,xmin,xmax,ymin,ymax)
%WORLD_EXTENT_TO_INDICES Convert projected extent to raster indices.

[c1_tmp,r1_tmp] = worldToIntrinsic(R,xmin,ymax);
[c2_tmp,r2_tmp] = worldToIntrinsic(R,xmax,ymin);

c1 = floor(min(c1_tmp,c2_tmp));
c2 = ceil(max(c1_tmp,c2_tmp));

r1 = floor(min(r1_tmp,r2_tmp));
r2 = ceil(max(r1_tmp,r2_tmp));

end
