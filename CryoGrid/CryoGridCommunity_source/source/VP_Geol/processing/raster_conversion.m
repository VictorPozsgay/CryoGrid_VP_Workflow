function raster_conversion(brgm_path)
%RASTER_CONVERSION Convert BRGM geology rasters to CryoGrid class codes.
%
% SCIENTIFIC INPUT
%   BRGM GEO050K_HARM rasters containing original BRGM ID_original values.
%
%   The scientific classification is NOT performed here. This function
%   consumes the previously generated classification index:
%
%       processed/BRGM_CryoGrid_classification_index.mat
%
% CONVERSION
%   Each valid raster pixel is converted:
%
%       BRGM ID_original  ->  CryoGrid integer code
%
%   The classification index therefore acts as the fixed interface
%   between the scientific geological classification and the raster
%   products.
%
% OUTPUT
%   For every:
%
%       processed/raster/GEOLOGY_massif_XX.tif
%
%   a corresponding raster is written to:
%
%       processed/raster_CryoGrid/GEOLOGY_massif_XX.tif
%
%   with integer CryoGrid class codes.
%
%   Code convention:
%
%       0       UNKNOWN
%       1       BEDROCK
%       2       SEDIMENT
%       3       TILL
%       4       SCREE
%       5       ICE
%       6       ORGANIC
%       7       WATER
%       -9999   NoData
%
% IMPORTANT
%   This function does not rerun the scientific classification and does
%   not modify the original BRGM rasters.
%
% INPUT
%   brgm_path
%       Root path of the BRGM GEO050K_HARM processing directory.
%
% =========================================================================

%% Paths

processed_path = fullfile(brgm_path,"processed");
input_path     = fullfile(processed_path,"raster");
output_path    = fullfile(processed_path,"raster_CryoGrid");

classification_index_path = fullfile( ...
    processed_path, ...
    "BRGM_CryoGrid_classification_index.mat");

%% Check inputs

if ~isfolder(input_path)
    error("BRGM raster directory not found: %s",input_path);
end

if ~isfile(classification_index_path)
    error( ...
        "CryoGrid classification index not found: %s", ...
        classification_index_path);
end

%% Check whether raster conversion is already complete

input_files = dir(fullfile(input_path,"GEOLOGY_massif_*.tif"));
conversion_complete = false;

if isfolder(output_path)
    output_files = dir(fullfile(output_path,"GEOLOGY_massif_*.tif"));
    input_names = string({input_files.name});
    output_names = string({output_files.name});
    conversion_complete = ...
        numel(input_files) == numel(output_files) && ...
        all(ismember(input_names,output_names));
end

if conversion_complete
    fprintf("\n")
    fprintf("BRGM -> CryoGrid raster conversion already complete.\n")
    fprintf("Output folder:\n  %s\n",output_path)
    fprintf("Skipping raster conversion.\n")
    return
end

%% Load classification index

INDEX_DATA = load(classification_index_path);

if ~isfield(INDEX_DATA,"CLASSIFICATION_INDEX")
    error( ...
        "Classification index file does not contain " + ...
        "'CLASSIFICATION_INDEX': %s", ...
        classification_index_path);
end

CLASSIFICATION_INDEX = INDEX_DATA.CLASSIFICATION_INDEX;

required_fields = [
    "ID_original"
    "NOTATION"
    "CRYOGRID_CLASS"
    "CRYOGRID_CODE"
];

for k = 1:numel(required_fields)

    field_name = required_fields(k);

    if ~isfield(CLASSIFICATION_INDEX,char(field_name))
        error( ...
            "CLASSIFICATION_INDEX is missing required field '%s'.", ...
            field_name);
    end

end

%% Validate classification index

brgm_ids = double(CLASSIFICATION_INDEX.ID_original);
cryo_codes = double(CLASSIFICATION_INDEX.CRYOGRID_CODE);

if numel(brgm_ids) ~= numel(cryo_codes)
    error("ID_original and CRYOGRID_CODE have different lengths.");
end

if any(~isfinite(brgm_ids))
    error("CLASSIFICATION_INDEX contains invalid ID_original values.");
end

if any(~isfinite(cryo_codes))
    error("CLASSIFICATION_INDEX contains invalid CRYOGRID_CODE values.");
end

if numel(unique(brgm_ids)) ~= numel(brgm_ids)
    error("CLASSIFICATION_INDEX contains duplicate ID_original values.");
end

%% Create output directory

if ~isfolder(output_path)
    mkdir(output_path);
end

%% Find BRGM rasters

files = dir(fullfile(input_path,"GEOLOGY_massif_*.tif"));

if isempty(files)
    error( ...
        "No GEOLOGY_massif_XX.tif files found in: %s", ...
        input_path);
end

files = sort_nat({files.name});

%% Start

fprintf("\n");
fprintf("============================================================\n");
fprintf("BRGM -> CRYOGRID GEOLOGY RASTER CONVERSION\n");
fprintf("============================================================\n");

fprintf("\nClassification index:\n");
fprintf("  %s\n",classification_index_path);

fprintf("\nInput raster directory:\n");
fprintf("  %s\n",input_path);

fprintf("\nOutput raster directory:\n");
fprintf("  %s\n",output_path);

fprintf("\nRasters to convert : %d\n",numel(files));
fprintf("Classification units: %d\n",numel(brgm_ids));

%% Process each massif

for f = 1:numel(files)

    input_file = fullfile(input_path,files{f});
    output_file = fullfile(output_path,files{f});

    fprintf("\n------------------------------------------------------------\n");
    fprintf("Massif %d / %d\n",f,numel(files));
    fprintf("Input : %s\n",files{f});

    %% Read raster

    [GEOLOGY,R] = readgeoraster(input_file);

    info = georasterinfo(input_file);

    if ndims(GEOLOGY) ~= 2
        error( ...
            "Raster is not single-band: %s", ...
            input_file);
    end

    %% Identify valid BRGM IDs

    GEOLOGY_double = double(GEOLOGY);
    nodata_mask = GEOLOGY_double == -9999;
    valid_mask = ~nodata_mask;
    raster_ids = unique(GEOLOGY_double(valid_mask));

    fprintf("Raster size       : %d x %d\n", ...
        size(GEOLOGY,1),size(GEOLOGY,2));

    fprintf("Valid raster IDs  : %d\n",numel(raster_ids));

    %% Verify all raster IDs exist in classification index

    [is_member,~] = ismember(raster_ids,brgm_ids);

    if any(~is_member)
        missing_ids = raster_ids(~is_member);
        fprintf("\nERROR: raster IDs missing from classification index:\n");
        fprintf("  ");
        fprintf("%g ",missing_ids);
        fprintf("\n");

        error( ...
            "Raster contains %d BRGM IDs absent from classification index.", ...
            numel(missing_ids));

    end

    %% Convert BRGM IDs -> CryoGrid codes

    CRYOGRID = zeros(size(GEOLOGY_double),"int16");
    valid_values = GEOLOGY_double(valid_mask);
    [~,pixel_index] = ismember(valid_values,brgm_ids);
    converted_values = cryo_codes(pixel_index);
    CRYOGRID(valid_mask) = int16(converted_values);

    % Preserve NoData.
    CRYOGRID(nodata_mask) = int16(-9999);

    %% Diagnostics

    cryo_ids = unique(double(CRYOGRID(valid_mask)));
    fprintf("CryoGrid classes : %d\n",numel(cryo_ids));

    %% Write GeoTIFF
    
    if isfile(output_file)
        delete(output_file);
    end
    
    % All CryoGrid BRGM geology rasters are expected to use
    % RGF93 / Lambert-93 (EPSG:2154).
    EXPECTED_EPSG = 2154;
    
    crs = info.CoordinateReferenceSystem;
    
    if ~isa(crs,"projcrs")
        error("Unexpected CRS type for %s: %s",input_file,class(crs));
    end
    
    if crs.Name ~= "RGF93 v1 / Lambert-93"
        error( ...
            "Unexpected CRS for %s: %s. Expected RGF93 v1 / Lambert-93.", ...
            input_file, ...
            crs.Name);
    end
    
    geotiffwrite( ...
        output_file, ...
        CRYOGRID, ...
        R, ...
        "CoordRefSysCode",EXPECTED_EPSG);
    
    fprintf("CRS               : RGF93 v1 / Lambert-93 (EPSG:%d)\n", ...
        EXPECTED_EPSG);
    
    fprintf("Output             : %s\n",output_file);

end

%% Complete

fprintf("\n");
fprintf("============================================================\n");
fprintf("RASTER CONVERSION COMPLETED\n");
fprintf("============================================================\n");

fprintf("\nConverted %d massif rasters.\n",numel(files));
fprintf("Output directory:\n  %s\n",output_path);

end


%% ========================================================================
% LOCAL FUNCTIONS
% ========================================================================

function sorted_names = sort_nat(names)
%SORT_NAT Sort filenames naturally by their numeric massif number.

names = string(names);
numbers = nan(size(names));

for i = 1:numel(names)
    token = regexp(names(i),'GEOLOGY_massif_(\d+)','tokens','once');
    if ~isempty(token)
        numbers(i) = str2double(token{1});
    end
end

[~,order] = sort(numbers);
sorted_names = cellstr(names(order));

end