function GEOLOGY_CLASS = classify_BRGM_geology(GEOLOGY)
%CLASSIFY_BRGM_GEOLOGY Classify BRGM geological units for CryoGrid.
%
% INPUT
%   GEOLOGY
%       BRGM geological inventory.
%
% OUTPUT
%   GEOLOGY_CLASS
%       Copy of GEOLOGY with:
%           CRYOGRID_CLASS
%           TRIGGERS
%           TRIGGER_RULES
%           N_TRIGGERS
%           CONFIDENCE
%           TRIGGER_HITS
%
% CLASSIFICATION
%   Classes:
%       BEDROCK, SCREE, TILL, SEDIMENT, ORGANIC, ICE, UNKNOWN
%
%   Classification priority:
%       1. Exact NOTATION override
%       2. STRONG keyword matches
%       3. WEAK keyword matches
%       4. RULES.CLASS_ORDER resolves ties
%
% MATCHING
%   Keyword matching is case-insensitive, accent-tolerant and substring-
%   based. Keywords may contain several words.
%
%   Nested matches within the same text word are resolved by keeping only
%   the longest matching keyword. Unrelated matches are retained.
%
% EXCLUSIONS
%   RULES.EXCLUDE strings are removed from the search text before any
%   classification rule is evaluated.
%
%   Matching is tolerant to case, accents and the corrupted character �.

%% 1. RULES AND OUTPUT

RULES = BRGM_CryoGrid_rules();
disp(class(RULES.CLASS_ORDER))
disp(size(RULES.CLASS_ORDER))
disp(RULES.CLASS_ORDER)
GEOLOGY_CLASS = GEOLOGY;

n = numel(GEOLOGY.NOTATION);
class_order = RULES.CLASS_ORDER(:);

GEOLOGY_CLASS.CRYOGRID_CLASS = repmat("UNKNOWN",n,1);
GEOLOGY_CLASS.TRIGGERS       = cell(n,1);
GEOLOGY_CLASS.TRIGGER_RULES  = cell(n,1);
GEOLOGY_CLASS.N_TRIGGERS     = zeros(n,1);
GEOLOGY_CLASS.CONFIDENCE     = zeros(n,1);

GEOLOGY_CLASS.TRIGGER_HITS = table( ...
    zeros(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    'VariableNames', ...
    {'ID','CLASS','RULE','STRENGTH','TRIGGERED_TEXT'});

%% 2. BUILD SEARCH TEXT

SEARCH_TEXT = strings(n,1);

for i = 1:n
    SEARCH_TEXT(i) = descr_to_string(GEOLOGY.DESCR{i});
end

%% 3. APPLY GLOBAL EXCLUSIONS

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

%% 4. EXACT NOTATION OVERRIDES

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

                GEOLOGY_CLASS = add_trigger( ...
                    GEOLOGY_CLASS, ...
                    i, ...
                    class_name, ...
                    "NOTATION:" + notation_rule);

            end

        end
    end
end

%% 5. COLLECT ALL KEYWORD MATCHES

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

%% 6. REMOVE NESTED KEYWORD MATCHES

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

%% 7. RECORD SURVIVING KEYWORD TRIGGERS

for h = 1:numel(keyword_hits)

    i = keyword_hits(h).UNIT;

    GEOLOGY_CLASS = add_trigger( ...
        GEOLOGY_CLASS, i, ...
        keyword_hits(h).CLASS, ...
        keyword_hits(h).STRENGTH + ":" + keyword_hits(h).RULE);

    GEOLOGY_CLASS.TRIGGER_HITS(end+1,:) = { ...
        GEOLOGY.ID(i), ...
        keyword_hits(h).CLASS, ...
        keyword_hits(h).RULE, ...
        keyword_hits(h).STRENGTH, ...
        keyword_hits(h).TRIGGERED_TEXT};

end

%% 8. DETERMINE FINAL CLASSIFICATION

for i = 1:n

    % Exact NOTATION overrides everything.
    if strlength(notation_class(i)) > 0
        GEOLOGY_CLASS.CRYOGRID_CLASS(i) = notation_class(i);
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
    strongest = unit_hits(strengths == max(strengths));

    strongest_classes = unique( ...
        [keyword_hits(strongest).CLASS], ...
        'stable');

    % CLASS_ORDER resolves equally strong class conflicts.
    for k = 1:numel(class_order)

        candidate = class_order(k);

        if any(strongest_classes == candidate)
            GEOLOGY_CLASS.CRYOGRID_CLASS(i) = candidate;
            break
        end

    end
end

%% 9. FINALIZE TRIGGER INFORMATION

for i = 1:n

    GEOLOGY_CLASS.N_TRIGGERS(i) = ...
        numel(GEOLOGY_CLASS.TRIGGERS{i});

    if GEOLOGY_CLASS.N_TRIGGERS(i) > 0
        GEOLOGY_CLASS.CONFIDENCE(i) = ...
            1 / GEOLOGY_CLASS.N_TRIGGERS(i);
    end
end

GEOLOGY_CLASS.TRIGGER_HITS = unique( ...
    GEOLOGY_CLASS.TRIGGER_HITS, ...
    'rows', ...
    'stable');

GEOLOGY_CLASS.TRIGGER_HITS = sortrows( ...
    GEOLOGY_CLASS.TRIGGER_HITS, ...
    {'ID','CLASS','RULE'});

%% 10. CLASSIFICATION SUMMARY

fprintf('\n');
fprintf('============================================================\n');
fprintf('BRGM CRYOGRID GEOLOGY CLASSIFICATION\n');
fprintf('============================================================\n');

fprintf('\nTotal units : %d\n',n);
fprintf('\nCRYOGRID_CLASS:\n');

classes = unique( ...
    GEOLOGY_CLASS.CRYOGRID_CLASS, ...
    'stable');

for k = 1:numel(classes)

    class_name = classes(k);

    count = nnz( ...
        GEOLOGY_CLASS.CRYOGRID_CLASS == class_name);

    fprintf( ...
        '  %-10s %5d   %6.2f %%\n', ...
        char(class_name), ...
        count, ...
        100 * count / n);

end

%% 11. UNKNOWN DIAGNOSTICS

unknown = GEOLOGY_CLASS.CRYOGRID_CLASS == "UNKNOWN";
n_unknown = nnz(unknown);

fprintf('\n');
fprintf('============================================================\n');
fprintf('UNKNOWN CRYOGRID CLASS\n');
fprintf('============================================================\n');

fprintf( ...
    'Unknown units : %d (%.1f %%)\n', ...
    n_unknown, ...
    100 * n_unknown / n);

if isfield(GEOLOGY_CLASS,"AREA_m2")

    unknown_area = sum( ...
        GEOLOGY_CLASS.AREA_m2(unknown), ...
        'omitnan') / 1e6;

    fprintf( ...
        'Unknown area  : %.1f km2\n', ...
        unknown_area);
end

%% 12. TRIGGER DIAGNOSTICS

no_trigger       = GEOLOGY_CLASS.N_TRIGGERS == 0;
one_trigger      = GEOLOGY_CLASS.N_TRIGGERS == 1;
multiple_trigger = GEOLOGY_CLASS.N_TRIGGERS > 1;

fprintf('\nTRIGGER DIAGNOSTICS:\n');
fprintf('No trigger     : %d\n',nnz(no_trigger));
fprintf('One trigger    : %d\n',nnz(one_trigger));
fprintf('Multiple       : %d\n',nnz(multiple_trigger));

%% 13. DISPLAY MULTIPLE-TRIGGER UNITS

if any(multiple_trigger)

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('MULTIPLE CLASSIFICATION TRIGGERS\n');
    fprintf('============================================================\n');

    for i = find(multiple_trigger).'

        fprintf('\nID %d\n',GEOLOGY.ID(i));
        fprintf('NOTATION : %s\n', ...
            notation_to_string(GEOLOGY.NOTATION,i));
        fprintf('DESCR    : %s\n', ...
            descr_to_string(GEOLOGY.DESCR{i}));
        fprintf('CLASS    : %s\n', ...
            GEOLOGY_CLASS.CRYOGRID_CLASS(i));
        fprintf('TRIGGERS : %s\n', ...
            strjoin(GEOLOGY_CLASS.TRIGGERS{i},", "));
        fprintf('RULES    : %s\n', ...
            strjoin(GEOLOGY_CLASS.TRIGGER_RULES{i}," | "));

    end
end

%% 14. DISPLAY UNKNOWN UNITS

if any(no_trigger)

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('UNCLASSIFIED UNITS\n');
    fprintf('============================================================\n');

    for i = find(no_trigger).'

        fprintf('\nID %d\n',GEOLOGY.ID(i));
        fprintf('NOTATION : %s\n', ...
            notation_to_string(GEOLOGY.NOTATION,i));
        fprintf('DESCR    : %s\n', ...
            descr_to_string(GEOLOGY.DESCR{i}));

    end
end

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


function GEOLOGY_CLASS = add_trigger(GEOLOGY_CLASS,i,class_name,rule)

if isempty(GEOLOGY_CLASS.TRIGGERS{i})
    GEOLOGY_CLASS.TRIGGERS{i} = string.empty(0,1);
end

if ~any(GEOLOGY_CLASS.TRIGGERS{i} == class_name)
    GEOLOGY_CLASS.TRIGGERS{i}(end+1,1) = class_name;
end

if isempty(GEOLOGY_CLASS.TRIGGER_RULES{i})
    GEOLOGY_CLASS.TRIGGER_RULES{i} = string.empty(0,1);
end

if ~any(GEOLOGY_CLASS.TRIGGER_RULES{i} == rule)
    GEOLOGY_CLASS.TRIGGER_RULES{i}(end+1,1) = rule;
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
%
% The corrupted character � is treated as one unknown character.
% Accented characters also match their unaccented and corrupted forms.

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
