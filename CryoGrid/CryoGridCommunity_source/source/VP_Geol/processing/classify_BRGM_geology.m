function classify_BRGM_geology(brgm_path)
%CLASSIFY_BRGM_GEOLOGY Classify BRGM geological units for CryoGrid.
%
% SCIENTIFIC INPUT
%   BRGM GEO050K_HARM geological units represented in the CryoGrid
%   raster domain. The input inventory is:
%
%       fullfile(brgm_path,"processed", ...
%           "BRGM_GEO050K_HARM_raster_inventory.mat")
%
%   GEOLOGY_RASTER.ID_original identifies the original BRGM unit and
%   GEOLOGY_RASTER.NOTATION provides the BRGM geological notation used
%   by the classification rules.
%
% CLASSIFICATION
%   Final CryoGrid classes:
%
%       UNKNOWN
%       BEDROCK
%       SEDIMENT
%       TILL
%       SCREE
%       ICE
%       ORGANIC
%       WATER
%
%   Exact NOTATION rules have priority over keyword rules.
%   For keyword rules:
%
%       STRONG > WEAK
%
%   Ties are resolved using RULES.CLASS_ORDER.
%
% OUTPUT PRODUCTS
%   Written to:
%
%       fullfile(brgm_path,"processed")
%
%   1. BRGM_CryoGrid_classification_log.txt
%      Complete classification statistics and unit-by-unit diagnostics.
%
%   2. BRGM_CryoGrid_classification_index.mat
%      Explicit mapping between the original BRGM unit, its notation,
%      and the resulting CryoGrid class and numerical code.
%
%   The saved index contains:
%
%       ID_original
%       NOTATION
%       CRYOGRID_CLASS
%       CRYOGRID_CODE
%       METADATA
%
%   Numerical coding:
%
%       0     = UNKNOWN
%       1     = BEDROCK
%       2     = SEDIMENT
%       3     = TILL
%       4     = SCREE
%       5     = ICE
%       6     = ORGANIC
%       7     = WATER
%       -9999 = NoData
%
% REPRODUCIBILITY
%   The classification is determined by the BRGM raster-domain inventory,
%   BRGM_CryoGrid_rules(), and this classification algorithm. The original
%   BRGM inventory is never modified.
% 
% If both output products already exist, classification is skipped.
%
% =========================================================================

%% 1. INPUTS AND OUTPUT PATHS

file_path = fullfile( ...
    brgm_path, ...
    "processed", ...
    "BRGM_GEO050K_HARM_raster_inventory.mat");

processed_path = fullfile(brgm_path,"processed");

classification_log_path = fullfile( ...
    processed_path, ...
    "BRGM_CryoGrid_classification_log.txt");

classification_index_path = fullfile( ...
    processed_path, ...
    "BRGM_CryoGrid_classification_index.mat");

%% Check whether classification is already complete

if isfile(classification_log_path) && ...
        isfile(classification_index_path)

    fprintf("\n")
    fprintf("BRGM CryoGrid classification already complete.\n")
    fprintf("Classification log:\n  %s\n", ...
        classification_log_path)
    fprintf("Classification index:\n  %s\n", ...
        classification_index_path)
    fprintf("Skipping classification.\n")
    return

end

%% 2. LOAD SCIENTIFIC INPUT AND RULES

S = load(file_path);
GEOLOGY = S.GEOLOGY_RASTER;

RULES = BRGM_CryoGrid_rules();

n = numel(GEOLOGY.NOTATION);
class_order = RULES.CLASS_ORDER(:);


%% 3. INTERNAL CLASSIFICATION STRUCTURE

CLASSIFICATION.CRYOGRID_CLASS = repmat("UNKNOWN",n,1);
CLASSIFICATION.TRIGGERS       = cell(n,1);
CLASSIFICATION.TRIGGER_RULES  = cell(n,1);
CLASSIFICATION.N_TRIGGERS     = zeros(n,1);

CLASSIFICATION.TRIGGER_HITS = table( ...
    zeros(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    'VariableNames', ...
    {'ID','CLASS','RULE','STRENGTH','TRIGGERED_TEXT'});


%% 4. BUILD SEARCH TEXT

SEARCH_TEXT = strings(n,1);

for i = 1:n
    SEARCH_TEXT(i) = descr_to_string(GEOLOGY.DESCR{i});
end


%% 5. APPLY GLOBAL EXCLUSIONS

if isfield(RULES,"EXCLUDE") && ~isempty(RULES.EXCLUDE)

    for exclusion = string(RULES.EXCLUDE)

        if strlength(exclusion) == 0
            continue
        end

        pattern = make_pattern(exclusion);

        for i = 1:n

            if strlength(SEARCH_TEXT(i)) == 0
                continue
            end

            SEARCH_TEXT(i) = string(regexprep( ...
                char(SEARCH_TEXT(i)), ...
                pattern, ...
                '', ...
                'ignorecase'));

        end
    end
end


%% 6. EXACT NOTATION OVERRIDES

notation_class = repmat("",n,1);

for k = 1:numel(class_order)

    class_name = class_order(k);

    if ~isfield(RULES,char(class_name))
        error( ...
            'Class "%s" is present in CLASS_ORDER but has no rule definition.', ...
            char(class_name));
    end

    class_rules = RULES.(char(class_name));

    if ~isfield(class_rules,"NOTATIONS") || ...
            isempty(class_rules.NOTATIONS)
        continue
    end

    for notation_rule = string(class_rules.NOTATIONS(:))'

        if strlength(notation_rule) == 0
            continue
        end

        for i = 1:n

            if strcmp( ...
                    notation_to_string(GEOLOGY.NOTATION,i), ...
                    notation_rule)

                notation_class(i) = class_name;

                CLASSIFICATION = add_trigger( ...
                    CLASSIFICATION, ...
                    i, ...
                    class_name, ...
                    "NOTATION:" + notation_rule);

            end
        end
    end
end


%% 7. COLLECT ALL KEYWORD MATCHES

strength_names  = ["WEAK","STRONG"];
strength_values = [1 2];

keyword_hits = struct( ...
    'UNIT',{}, ...
    'CLASS',{}, ...
    'RULE',{}, ...
    'STRENGTH',{}, ...
    'STRENGTH_VALUE',{}, ...
    'TRIGGERED_TEXT',{});

for k = 1:numel(class_order)

    class_name = class_order(k);
    class_rules = RULES.(char(class_name));

    for s = 1:numel(strength_names)

        strength_name  = strength_names(s);
        strength_value = strength_values(s);

        if ~isfield(class_rules,char(strength_name))
            error( ...
                'Class "%s" must contain a %s field.', ...
                char(class_name), ...
                char(strength_name));
        end

        keywords = string(class_rules.(char(strength_name)));

        for j = 1:numel(keywords)

            keyword = keywords(j);

            if strlength(keyword) == 0
                continue
            end

            pattern = make_pattern(keyword);

            for i = 1:n

                text = char(SEARCH_TEXT(i));

                if isempty(text)
                    continue
                end

                matches = regexpi( ...
                    text, ...
                    ['\S*' pattern '\S*'], ...
                    'match');

                for m = 1:numel(matches)

                    keyword_hits(end+1) = struct( ... %#ok<AGROW>
                        'UNIT',i, ...
                        'CLASS',class_name, ...
                        'RULE',keyword, ...
                        'STRENGTH',strength_name, ...
                        'STRENGTH_VALUE',strength_value, ...
                        'TRIGGERED_TEXT',string(matches{m}));

                end
            end
        end
    end
end


%% 8. REMOVE NESTED KEYWORD MATCHES

keep_hit = true(1,numel(keyword_hits));

for h = 1:numel(keyword_hits)

    if ~keep_hit(h)
        continue
    end

    unit_h = keyword_hits(h).UNIT;

    text_h = normalize_for_comparison( ...
        keyword_hits(h).TRIGGERED_TEXT);

    rule_h = normalize_for_comparison( ...
        keyword_hits(h).RULE);

    for g = 1:numel(keyword_hits)

        if h == g || ~keep_hit(g)
            continue
        end

        if keyword_hits(g).UNIT ~= unit_h
            continue
        end

        text_g = normalize_for_comparison( ...
            keyword_hits(g).TRIGGERED_TEXT);

        if ~strcmp(text_h,text_g)
            continue
        end

        rule_g = normalize_for_comparison( ...
            keyword_hits(g).RULE);

        % Keep the longer keyword when one contains the other.
        if length(rule_h) < length(rule_g) && ...
                contains(rule_g,rule_h)

            keep_hit(h) = false;
            break
        end
    end
end

keyword_hits = keyword_hits(keep_hit);


%% 9. RECORD SURVIVING KEYWORD TRIGGERS

for h = 1:numel(keyword_hits)

    i = keyword_hits(h).UNIT;

    CLASSIFICATION = add_trigger( ...
        CLASSIFICATION, ...
        i, ...
        keyword_hits(h).CLASS, ...
        keyword_hits(h).STRENGTH + ":" + keyword_hits(h).RULE);

    CLASSIFICATION.TRIGGER_HITS(end+1,:) = { ...
        GEOLOGY.ID_original(i), ...
        keyword_hits(h).CLASS, ...
        keyword_hits(h).RULE, ...
        keyword_hits(h).STRENGTH, ...
        keyword_hits(h).TRIGGERED_TEXT};

end


%% 10. DETERMINE FINAL CLASSIFICATION

for i = 1:n

    % Exact NOTATION overrides everything.
    if strlength(notation_class(i)) > 0
        CLASSIFICATION.CRYOGRID_CLASS(i) = notation_class(i);
        continue
    end

    if isempty(keyword_hits)
        continue
    end

    unit_hits = find([keyword_hits.UNIT] == i);

    if isempty(unit_hits)
        continue
    end

    strengths = [keyword_hits(unit_hits).STRENGTH_VALUE];

    strongest = unit_hits( ...
        strengths == max(strengths));

    strongest_classes = unique( ...
        [keyword_hits(strongest).CLASS], ...
        'stable');

    % CLASS_ORDER resolves equally strong class conflicts.
    for k = 1:numel(class_order)

        candidate = class_order(k);

        if any(strongest_classes == candidate)
            CLASSIFICATION.CRYOGRID_CLASS(i) = candidate;
            break
        end

    end
end


%% 11. FINALIZE TRIGGER INFORMATION

for i = 1:n

    CLASSIFICATION.N_TRIGGERS(i) = ...
        numel(CLASSIFICATION.TRIGGERS{i});

end

CLASSIFICATION.TRIGGER_HITS = unique( ...
    CLASSIFICATION.TRIGGER_HITS, ...
    'rows', ...
    'stable');

CLASSIFICATION.TRIGGER_HITS = sortrows( ...
    CLASSIFICATION.TRIGGER_HITS, ...
    {'ID','CLASS','RULE'});


%% 12. CLASSIFICATION CODES

% Numerical codes used by the subsequent CryoGrid geology raster.

CRYOGRID_CODES = struct( ...
    "UNKNOWN",  0, ...
    "BEDROCK",  1, ...
    "SEDIMENT", 2, ...
    "TILL",     3, ...
    "SCREE",    4, ...
    "ICE",      5, ...
    "ORGANIC",  6, ...
    "WATER",    7);

cryogrid_code = zeros(n,1);

for i = 1:n

    class_name = char(CLASSIFICATION.CRYOGRID_CLASS(i));

    if isfield(CRYOGRID_CODES,class_name)
        cryogrid_code(i) = CRYOGRID_CODES.(class_name);
    else
        error( ...
            'Unknown CryoGrid class "%s" for BRGM ID %d.', ...
            class_name, ...
            GEOLOGY.ID_original(i));
    end

end


%% 13. WRITE CLASSIFICATION LOG

fid = fopen(classification_log_path,"w");

if fid == -1
    error( ...
        'Could not open classification log for writing: %s', ...
        classification_log_path);
end

cleanup_log = onCleanup(@() fclose(fid));

fprintf(fid,'============================================================\n');
fprintf(fid,'BRGM GEO050K_HARM -> CRYOGRID GEOLOGY CLASSIFICATION\n');
fprintf(fid,'============================================================\n');
fprintf(fid,'\n');

fprintf(fid,'Scientific input:\n');
fprintf(fid,'  %s\n',file_path);

fprintf(fid,'Classification rules:\n');
fprintf(fid,'  %s\n',which("BRGM_CryoGrid_rules"));

fprintf(fid,'\n');
fprintf(fid,'Total units : %d\n',n);


%% 13.1 CLASSIFICATION SUMMARY

fprintf(fid,'\n');
fprintf(fid,'============================================================\n');
fprintf(fid,'CRYOGRID CLASSIFICATION SUMMARY\n');
fprintf(fid,'============================================================\n');

classes = unique( ...
    CLASSIFICATION.CRYOGRID_CLASS, ...
    'stable');

for k = 1:numel(classes)

    class_name = classes(k);

    count = nnz( ...
        CLASSIFICATION.CRYOGRID_CLASS == class_name);

    fprintf( ...
        fid, ...
        '  %-10s %5d   %6.2f %%\n', ...
        char(class_name), ...
        count, ...
        100 * count / n);

end


%% 13.2 UNKNOWN DIAGNOSTICS

unknown = CLASSIFICATION.CRYOGRID_CLASS == "UNKNOWN";
n_unknown = nnz(unknown);

fprintf(fid,'\n');
fprintf(fid,'============================================================\n');
fprintf(fid,'UNKNOWN CRYOGRID CLASS\n');
fprintf(fid,'============================================================\n');

fprintf( ...
    fid, ...
    'Unknown units : %d (%.1f %%)\n', ...
    n_unknown, ...
    100 * n_unknown / n);

if isfield(GEOLOGY,"AREA_m2")

    unknown_area = sum( ...
        GEOLOGY.AREA_m2(unknown), ...
        'omitnan') / 1e6;

    fprintf( ...
        fid, ...
        'Unknown area  : %.1f km2\n', ...
        unknown_area);

end


%% 13.3 TRIGGER DIAGNOSTICS

no_trigger       = CLASSIFICATION.N_TRIGGERS == 0;
one_trigger      = CLASSIFICATION.N_TRIGGERS == 1;
multiple_trigger = CLASSIFICATION.N_TRIGGERS > 1;

fprintf(fid,'\n');
fprintf(fid,'============================================================\n');
fprintf(fid,'TRIGGER DIAGNOSTICS\n');
fprintf(fid,'============================================================\n');

fprintf(fid,'No trigger     : %d\n',nnz(no_trigger));
fprintf(fid,'One trigger    : %d\n',nnz(one_trigger));
fprintf(fid,'Multiple       : %d\n',nnz(multiple_trigger));


%% 13.4 COMPLETE UNIT-BY-UNIT CLASSIFICATION

fprintf(fid,'\n');
fprintf(fid,'============================================================\n');
fprintf(fid,'COMPLETE UNIT-BY-UNIT CLASSIFICATION\n');
fprintf(fid,'============================================================\n');

for i = 1:n

    fprintf(fid,'\n');
    fprintf(fid,'------------------------------------------------------------\n');

    fprintf(fid,'ID_original  : %d\n', ...
        GEOLOGY.ID_original(i));

    fprintf(fid,'NOTATION     : %s\n', ...
        notation_to_string(GEOLOGY.NOTATION,i));

    fprintf(fid,'DESCR        : %s\n', ...
        descr_to_string(GEOLOGY.DESCR{i}));

    fprintf(fid,'CLASS        : %s\n', ...
        CLASSIFICATION.CRYOGRID_CLASS(i));

    fprintf(fid,'CODE         : %d\n', ...
        cryogrid_code(i));

    fprintf(fid,'N_TRIGGERS   : %d\n', ...
        CLASSIFICATION.N_TRIGGERS(i));

    if isempty(CLASSIFICATION.TRIGGERS{i})

        fprintf(fid,'TRIGGERS     : none\n');

    else

        fprintf(fid,'TRIGGERS     : %s\n', ...
            strjoin(CLASSIFICATION.TRIGGERS{i},", "));

    end

    if isempty(CLASSIFICATION.TRIGGER_RULES{i})

        fprintf(fid,'RULES        : none\n');

    else

        fprintf(fid,'RULES        : %s\n', ...
            strjoin(CLASSIFICATION.TRIGGER_RULES{i}," | "));

    end

end


%% 13.5 MULTIPLE-TRIGGER SUMMARY

fprintf(fid,'\n');
fprintf(fid,'============================================================\n');
fprintf(fid,'MULTIPLE CLASSIFICATION TRIGGERS\n');
fprintf(fid,'============================================================\n');

if ~any(multiple_trigger)

    fprintf(fid,'None.\n');

else

    for i = find(multiple_trigger).'

        fprintf(fid, ...
            'ID %d | NOTATION %s | CLASS %s | TRIGGERS %s\n', ...
            GEOLOGY.ID_original(i), ...
            notation_to_string(GEOLOGY.NOTATION,i), ...
            CLASSIFICATION.CRYOGRID_CLASS(i), ...
            strjoin(CLASSIFICATION.TRIGGERS{i},", "));

    end

end


%% 13.6 UNCLASSIFIED SUMMARY

fprintf(fid,'\n');
fprintf(fid,'============================================================\n');
fprintf(fid,'UNCLASSIFIED UNITS\n');
fprintf(fid,'============================================================\n');

if ~any(no_trigger)

    fprintf(fid,'None.\n');

else

    for i = find(no_trigger).'

        fprintf(fid, ...
            'ID %d | NOTATION %s | DESCR %s\n', ...
            GEOLOGY.ID_original(i), ...
            notation_to_string(GEOLOGY.NOTATION,i), ...
            descr_to_string(GEOLOGY.DESCR{i}));

    end

end


%% 13.7 CLOSE LOG

clear cleanup_log


%% 14. CREATE SCIENTIFIC CLASSIFICATION INDEX

notation_values = strings(n,1);

for i = 1:n
    notation_values(i) = ...
        notation_to_string(GEOLOGY.NOTATION,i);
end

CLASSIFICATION_INDEX.ID_original = GEOLOGY.ID_original;
CLASSIFICATION_INDEX.NOTATION = notation_values;
CLASSIFICATION_INDEX.CRYOGRID_CLASS = ...
    CLASSIFICATION.CRYOGRID_CLASS;
CLASSIFICATION_INDEX.CRYOGRID_CODE = cryogrid_code;

CLASSIFICATION_INDEX.METADATA = [ ...
    "CryoGrid geology classification codes: " + ...
    "0 = UNKNOWN; " + ...
    "1 = BEDROCK; " + ...
    "2 = SEDIMENT; " + ...
    "3 = TILL; " + ...
    "4 = SCREE; " + ...
    "5 = ICE; " + ...
    "6 = ORGANIC; " + ...
    "7 = WATER; " + ...
    "-9999 = NoData"];


%% 15. SAVE CLASSIFICATION INDEX

save( ...
    classification_index_path, ...
    'CLASSIFICATION_INDEX');

fprintf('\n');
fprintf('Classification log saved to:\n  %s\n', ...
    classification_log_path);

fprintf('\n');
fprintf('Classification index saved to:\n  %s\n', ...
    classification_index_path);

end


%% ========================================================================
% LOCAL FUNCTIONS
% ========================================================================

function text = descr_to_string(d)

if isempty(d)
    text = "";
elseif iscell(d)
    text = strjoin(string(d(:))," | ");
else
    text = string(d);
end

end


function notation = notation_to_string(notations,i)

if iscell(notations)
    notation = string(notations{i});
else
    notation = string(notations(i));
end

end


function CLASSIFICATION = add_trigger( ...
    CLASSIFICATION,i,class_name,rule)

if isempty(CLASSIFICATION.TRIGGERS{i})
    CLASSIFICATION.TRIGGERS{i} = string.empty(0,1);
end

if ~any(CLASSIFICATION.TRIGGERS{i} == class_name)
    CLASSIFICATION.TRIGGERS{i}(end+1,1) = class_name;
end

if isempty(CLASSIFICATION.TRIGGER_RULES{i})
    CLASSIFICATION.TRIGGER_RULES{i} = string.empty(0,1);
end

if ~any(CLASSIFICATION.TRIGGER_RULES{i} == rule)
    CLASSIFICATION.TRIGGER_RULES{i}(end+1,1) = rule;
end

end


function s = normalize_for_comparison(s)

s = lower(string(s));

s = replace(s,["à","á","â","ã","ä","å"],"a");
s = replace(s,["è","é","ê","ë"],"e");
s = replace(s,["ì","í","î","ï"],"i");
s = replace(s,["ò","ó","ô","õ","ö"],"o");
s = replace(s,["ù","ú","û","ü"],"u");
s = replace(s,"ç","c");

s = char(s);

end


function pattern = make_pattern(keyword)
%MAKE_PATTERN Build accent/corruption-tolerant regexp pattern.

keyword = char(string(keyword));
pattern = '';

for k = 1:numel(keyword)

    switch keyword(k)

        case '�'
            token = '.';

        case {'é','è','ê','ë','É','È','Ê','Ë'}
            token = '[eéèêë�]';

        case {'à','â','ä','À','Â','Ä'}
            token = '[aàâä�]';

        case {'î','ï','Î','Ï'}
            token = '[iîï�]';

        case {'ô','ö','Ô','Ö'}
            token = '[oôö�]';

        case {'ù','û','ü','Ù','Û','Ü'}
            token = '[uùûü�]';

        case {'ÿ','Ÿ'}
            token = '[yÿ�]';

        case {'ç','Ç'}
            token = '[cç�]';

        case {'œ','Œ'}
            token = '[œ�]';

        case {'æ','Æ'}
            token = '[æ�]';

        otherwise
            token = regexptranslate('escape',keyword(k));

    end

    pattern = [pattern token]; %#ok<AGROW>

end

end