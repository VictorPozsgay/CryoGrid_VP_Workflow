function plot_BRGM_preview(geology_path)
%PLOT_BRGM_PREVIEW Plot BRGM geology by department.
%
% Displays one department at a time because mappolyshape/geoplot creates
% its own geographic axes.

fprintf("\nLoading BRGM geology\n")
fprintf("--------------------\n")


file = fullfile(geology_path,...
    "processed",...
    "BRGM_GEO050K_HARM_ALPES.mat");


load(file,"BRGM")


fprintf("Polygons: %d\n",numel(BRGM.Shape))


departments = unique(BRGM.DEPARTMENT);


for i = 1:numel(departments)

    idx = BRGM.DEPARTMENT == departments(i);

    fprintf("Plotting department %s (%d polygons)\n",...
        departments(i),sum(idx))


    figure

    geoplot(BRGM.Shape(idx))

    title("BRGM department " + departments(i))

end

end