function merge_BRGM_departments(forcing_path)
%MERGE_BRGM_DEPARTMENTS Merge BRGM GEO050K_HARM geology layers.
%
% MERGE_BRGM_DEPARTMENTS(FORCING_PATH) reads the BRGM GEO050K_HARM
% harmonized geological formation polygons (S_FGEOL) for all configured
% departments, merges them into a single Alpine dataset, and saves the
% processed result.
%
% Input:
%   forcing_path
%       Root path of the BRGM_GEO050K_HARM dataset.
%
% Output:
%   Creates:
%
%       forcing_path/processed/
%           BRGM_GEO050K_HARM_ALPES.mat
%
%   containing:
%
%       BRGM.Shape
%           mappolyshape vector containing all polygons
%
%       BRGM.CODE_LEG
%           Geological formation code
%
%       BRGM.NOTATION
%           Geological notation
%
%       BRGM.DESCR
%           Geological description
%
%       BRGM.DEPARTMENT
%           Source department identifier
%
%       BRGM.CRS
%           Lambert-93 coordinate reference system
%
% Notes:
%   - Only S_FGEOL layers are merged.
%   - Raw data are not modified.
%   - Existing processed output is reused.
%

fprintf("\n================================================\n")
fprintf("BRGM geology merge\n")
fprintf("================================================\n")


%% Paths

root = forcing_path;

raw_path = fullfile(root,"raw");
processed_path = fullfile(root,"processed");


if ~isfolder(processed_path)
    mkdir(processed_path)
end


output_file = fullfile(processed_path,...
    "BRGM_GEO050K_HARM_ALPES.mat");


%% Restart

if isfile(output_file)

    fprintf("Processed file already exists:\n%s\n",output_file)
    fprintf("Skipping merge.\n")

    return

end


%% Departments

departments = departments_list();

fprintf("\nDepartments to merge:\n")
disp(departments)



%% Storage

Ndep = numel(departments);

Shape_cell = cell(Ndep,1);

CODE_cell = cell(Ndep,1);
NOTATION_cell = cell(Ndep,1);
DESCR_cell = cell(Ndep,1);
DEPARTMENT_cell = cell(Ndep,1);

CRS = [];



%% Read departments

fprintf("\nReading geology layers\n")
fprintf("---------------------\n")


for i = 1:Ndep

    dep = departments(i);

    dep_str = sprintf("%03s",dep);

    fprintf("Department %s\n",dep_str)


    shp_file = fullfile(raw_path,...
        dep_str,...
        sprintf("GEO050K_HARM_%s_S_FGEOL_2154.shp",dep_str));


    if ~isfile(shp_file)

        warning("Missing geology file: %s",shp_file)
        continue

    end


    GEO = read_BRGM_geology(shp_file);



    % CRS consistency

    if isempty(CRS)

        CRS = GEO.CRS;

    elseif ~isequal(GEO.CRS,CRS)

        error("CRS mismatch in department %s",dep_str)

    end



    % Geometry

    Shape_cell{i} = GEO.Shape;



    % Attributes

    CODE_cell{i} = string(GEO.CODE_LEG);
    
    NOTATION_cell{i} = string(GEO.NOTATION);

    DESCR_cell{i} = string(GEO.DESCR);

    DEPARTMENT_cell{i} = repmat( ...
        dep_str, ...
        numel(GEO.Shape), ...
        1);

end



%% Concatenate

fprintf("\nConcatenating datasets\n")
fprintf("---------------------\n")


valid = ~cellfun(@isempty,Shape_cell);


Shape_all = vertcat(Shape_cell{valid});

CODE_all = vertcat(CODE_cell{valid});
NOTATION_all = vertcat(NOTATION_cell{valid});
DESCR_all = vertcat(DESCR_cell{valid});
DEPARTMENT_all = vertcat(DEPARTMENT_cell{valid});



%% Build output

BRGM = struct();

BRGM.Shape = Shape_all;

BRGM.CODE_LEG = CODE_all;

BRGM.NOTATION = NOTATION_all;

BRGM.DESCR = DESCR_all;

BRGM.DEPARTMENT = DEPARTMENT_all;

BRGM.CRS = CRS;

BRGM.source = ...
    "BRGM GEO050K_HARM S_FGEOL harmonized geological formations";



%% Save

fprintf("\nSaving merged dataset\n")
fprintf("--------------------\n")


save(output_file,"BRGM","-v7.3")


fprintf("Saved:\n%s\n",output_file)


fprintf("\n================================================\n")
fprintf("Merge completed\n")
fprintf("Polygons: %d\n",numel(BRGM.Shape))
fprintf("================================================\n")


end