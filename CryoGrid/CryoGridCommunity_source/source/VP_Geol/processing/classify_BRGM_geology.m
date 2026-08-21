function GEOLOGY_CLASS = classify_BRGM_geology(GEOLOGY)
%CLASSIFY_BRGM_GEOLOGY Classify BRGM geological units for CryoGrid.
%
% INPUT
%   GEOLOGY
%       BRGM geological inventory.
%
% OUTPUT
%   GEOLOGY_CLASS
%       Copy of GEOLOGY with additional fields:
%
%       CRYOGRID_CLASS
%       TRIGGERS
%       TRIGGER_RULES
%       N_TRIGGERS
%       CONFIDENCE
%
% CLASSIFICATION
%   The BRGM descriptions are reduced directly to a small set of
%   CryoGrid-relevant geological classes:
%
%       BEDROCK
%       SCREE
%       TILL
%       SEDIMENT
%       ORGANIC
%       ICE
%       UNKNOWN
%
%   Classification priority is defined by RULES.CLASS_ORDER.
%
%   First matching class wins for CRYOGRID_CLASS.
%
%   ALL matching classes and ALL matching keywords are retained in:
%
%       TRIGGERS
%       TRIGGER_RULES
%
% MATCHING
%   Keyword matching is deliberately NOT word-aware.
%
%   Keywords may therefore:
%
%       - occur as substrings of larger words
%       - contain several words
%
%   Matching is accent-tolerant.
%
% EXCLUSIONS
%   RULES.EXCLUDE contains global strings which are ignored during
%   classification.
%
%   Exclusions use the same accent-tolerant matching mechanism as
%   keywords.
%
%   Example:
%
%       RULES.EXCLUDE = "Ecenévex"
%
%   removes the occurrence of "Ecenévex" from the search text before
%   classification, preventing the substring "névé" from triggering ICE.
%
% -------------------------------------------------------------------------

%% ========================================================================
% 1. LOAD RULES
% =========================================================================

RULES = BRGM_CryoGrid_rules();


%% ========================================================================
% 2. CREATE WORKING COPY
% =========================================================================

GEOLOGY_CLASS = GEOLOGY;

n = numel(GEOLOGY.NOTATION);


%% ========================================================================
% 3. INITIALIZE OUTPUT
% =========================================================================

GEOLOGY_CLASS.CRYOGRID_CLASS = repmat("UNKNOWN",n,1);

GEOLOGY_CLASS.TRIGGERS = cell(n,1);

GEOLOGY_CLASS.TRIGGER_RULES = cell(n,1);

GEOLOGY_CLASS.N_TRIGGERS = zeros(n,1);

GEOLOGY_CLASS.CONFIDENCE = zeros(n,1);


%% ========================================================================
% 4. BUILD SEARCH TEXT
% =========================================================================
%
% DESCR may contain:
%
%   char
%   string
%   cell arrays
%
% Convert everything to one searchable string per geological unit.
%
% Exclusions are applied here, globally, before any classification rule
% is evaluated.
%
% =========================================================================

SEARCH_TEXT = strings(n,1);

for i = 1:n

    d = GEOLOGY.DESCR{i};

    if isempty(d)

        SEARCH_TEXT(i) = "";

    elseif iscell(d)

        SEARCH_TEXT(i) = strjoin( ...
            string(d(:)), ...
            " | ");

    else

        SEARCH_TEXT(i) = string(d);

    end

end


%% ========================================================================
% 5. APPLY GLOBAL EXCLUSIONS
% =========================================================================
%
% Every string in RULES.EXCLUDE is removed from the searchable text.
%
% The matching is accent-tolerant.
%
% This is intentionally independent of the classification keywords.
%
% =========================================================================

if isfield(RULES,"EXCLUDE") && ~isempty(RULES.EXCLUDE)

    exclusions = string(RULES.EXCLUDE);

    for j = 1:numel(exclusions)

        exclusion = exclusions(j);

        if strlength(exclusion) == 0
            continue
        end

        pattern = make_pattern(exclusion);

        for i = 1:n

            text = char(SEARCH_TEXT(i));

            if isempty(text)
                continue
            end

            SEARCH_TEXT(i) = string(regexprep( ...
                text, ...
                pattern, ...
                ''));

        end

    end

end


%% ========================================================================
% 6. APPLY CLASSIFICATION RULES
% =========================================================================
%
% Classification has two mechanisms:
%
%   1. KEYWORDS
%      Normal accent-tolerant substring matching.
%      CLASS_ORDER determines which class wins.
%
%   2. NOTATIONS
%      Exact BRGM NOTATION matches.
%      These are explicit classification overrides and therefore take
%      priority over all keyword-based classifications.
%
% Every keyword and every notation is nevertheless evaluated so that all
% triggers are retained for diagnostics.
%
% =========================================================================

class_order = string(RULES.CLASS_ORDER);

for k = 1:numel(class_order)

    class_name = class_order(k);

    if ~isfield(RULES,char(class_name))

        error( ...
            'Class "%s" is present in CLASS_ORDER but has no rule definition.', ...
            class_name);

    end

    class_rules = RULES.(char(class_name));


    %% ====================================================================
    % 6A. EXACT NOTATION OVERRIDES
    % =====================================================================
    %
    % NOTATIONS are exact BRGM NOTATION codes.
    %
    % They override any classification obtained from keywords.
    %
    % =====================================================================

    if isfield(class_rules,"NOTATIONS") && ...
            ~isempty(class_rules.NOTATIONS)

        notations = string(class_rules.NOTATIONS);

        for j = 1:numel(notations)

            notation_rule = notations(j);

            if strlength(notation_rule) == 0
                continue
            end


            % -------------------------------------------------------------
            % Get the BRGM notation for every unit
            % -------------------------------------------------------------

            notation_hit = false(n,1);

            for i = 1:n

                if iscell(GEOLOGY.NOTATION)

                    notation = string(GEOLOGY.NOTATION{i});

                else

                    notation = string(GEOLOGY.NOTATION(i));

                end

                notation_hit(i) = ...
                    strcmp(notation,notation_rule);

            end


            if ~any(notation_hit)
                continue
            end


            % -------------------------------------------------------------
            % Record notation trigger
            % -------------------------------------------------------------

            hit_indices = find(notation_hit);

            for ii = 1:numel(hit_indices)

                q = hit_indices(ii);


                % =========================================================
                % Trigger class
                % =========================================================

                if isempty(GEOLOGY_CLASS.TRIGGERS{q})

                    GEOLOGY_CLASS.TRIGGERS{q} = ...
                        string.empty(0,1);

                end

                if ~any( ...
                        GEOLOGY_CLASS.TRIGGERS{q} == class_name)

                    GEOLOGY_CLASS.TRIGGERS{q}(end+1,1) = ...
                        class_name;

                end


                % =========================================================
                % Trigger rule
                % =========================================================
                %
                % Store the notation itself so the diagnostic output makes
                % it clear that this was a NOTATION override rather than a
                % keyword trigger.
                %
                % =========================================================

                if isempty(GEOLOGY_CLASS.TRIGGER_RULES{q})

                    GEOLOGY_CLASS.TRIGGER_RULES{q} = ...
                        string.empty(0,1);

                end

                notation_trigger = ...
                    "NOTATION:" + notation_rule;

                if ~any( ...
                        GEOLOGY_CLASS.TRIGGER_RULES{q} == ...
                        notation_trigger)

                    GEOLOGY_CLASS.TRIGGER_RULES{q}(end+1,1) = ...
                        notation_trigger;

                end


                % =========================================================
                % EXPLICIT OVERRIDE
                % =========================================================
                %
                % A matching NOTATION always wins over keyword-based
                % classification.
                %
                % =========================================================

                GEOLOGY_CLASS.CRYOGRID_CLASS(q) = ...
                    class_name;

            end

        end

    end


    %% ====================================================================
    % 6B. KEYWORD MATCHING
    % =====================================================================
    %
    % KEYWORDS remain subject to CLASS_ORDER.
    %
    % A keyword can assign a class only if no previous keyword-based or
    % notation-based rule has already assigned the unit.
    %
    % =====================================================================

    if ~isfield(class_rules,"KEYWORDS")

        error( ...
            'Class "%s" has no KEYWORDS field.', ...
            class_name);

    end

    keywords = string(class_rules.KEYWORDS);


    % =====================================================================
    % Evaluate every keyword belonging to this class
    % =====================================================================

    for j = 1:numel(keywords)

        keyword = keywords(j);

        if strlength(keyword) == 0
            continue
        end


        % -----------------------------------------------------------------
        % Build accent-tolerant pattern
        % -----------------------------------------------------------------

        pattern = make_pattern(keyword);


        % -----------------------------------------------------------------
        % Find all units containing this keyword
        % -----------------------------------------------------------------

        hit = false(n,1);

        for i = 1:n

            text = char(SEARCH_TEXT(i));

            if isempty(text)
                continue
            end

            hit(i) = ~isempty( ...
                regexpi( ...
                    text, ...
                    pattern, ...
                    'once'));

        end


        if ~any(hit)
            continue
        end


        % -----------------------------------------------------------------
        % Record trigger information
        % -----------------------------------------------------------------

        hit_indices = find(hit);

        for ii = 1:numel(hit_indices)

            q = hit_indices(ii);


            % =============================================================
            % Trigger class
            % =============================================================

            if isempty(GEOLOGY_CLASS.TRIGGERS{q})

                GEOLOGY_CLASS.TRIGGERS{q} = ...
                    string.empty(0,1);

            end

            if ~any( ...
                    GEOLOGY_CLASS.TRIGGERS{q} == class_name)

                GEOLOGY_CLASS.TRIGGERS{q}(end+1,1) = ...
                    class_name;

            end


            % =============================================================
            % Trigger keyword
            % =============================================================

            if isempty(GEOLOGY_CLASS.TRIGGER_RULES{q})

                GEOLOGY_CLASS.TRIGGER_RULES{q} = ...
                    string.empty(0,1);

            end

            if ~any( ...
                    GEOLOGY_CLASS.TRIGGER_RULES{q} == keyword)

                GEOLOGY_CLASS.TRIGGER_RULES{q}(end+1,1) = ...
                    keyword;

            end

        end


        % -----------------------------------------------------------------
        % First keyword match wins
        % -----------------------------------------------------------------
        %
        % A notation override may already have assigned the unit. In that
        % case, this keyword must NOT replace the explicit notation result.
        %
        % -----------------------------------------------------------------

        assign = ...
            hit & ...
            GEOLOGY_CLASS.CRYOGRID_CLASS == "UNKNOWN";

        if any(assign)

            GEOLOGY_CLASS.CRYOGRID_CLASS(assign) = ...
                class_name;

        end

    end

end


%% ========================================================================
% 7. FINALIZE TRIGGER INFORMATION
% =========================================================================

for i = 1:n

    GEOLOGY_CLASS.N_TRIGGERS(i) = ...
        numel(GEOLOGY_CLASS.TRIGGERS{i});


    if GEOLOGY_CLASS.N_TRIGGERS(i) > 0

        % Simple diagnostic confidence:
        %
        %   1 trigger    -> 1.0
        %   2 triggers   -> 0.5
        %   3 triggers   -> 0.333...
        %
        % This is NOT a probabilistic confidence.
        % It only indicates how unambiguous the rule matching was.

        GEOLOGY_CLASS.CONFIDENCE(i) = ...
            1 / GEOLOGY_CLASS.N_TRIGGERS(i);

    else

        GEOLOGY_CLASS.CONFIDENCE(i) = 0;

    end

end


%% ========================================================================
% 8. SUMMARY
% =========================================================================

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

    percent = 100 * count / n;

    fprintf( ...
        '  %-10s %5d   %6.2f %%\n', ...
        class_name, ...
        count, ...
        percent);

end


%% ========================================================================
% 9. UNKNOWN DIAGNOSTICS
% =========================================================================

unknown = ...
    GEOLOGY_CLASS.CRYOGRID_CLASS == "UNKNOWN";

n_unknown = nnz(unknown);


fprintf('\n');
fprintf('============================================================\n');
fprintf('UNKNOWN CRYOGRID CLASS\n');
fprintf('============================================================\n');

fprintf( ...
    'Unknown units : %d (%.1f %%)\n', ...
    n_unknown, ...
    100*n_unknown/n);


if isfield(GEOLOGY_CLASS,"AREA_m2")

    unknown_area = ...
        sum( ...
            GEOLOGY_CLASS.AREA_m2(unknown), ...
            'omitnan') / 1e6;

    fprintf( ...
        'Unknown area  : %.1f km2\n', ...
        unknown_area);

end


%% ========================================================================
% 10. TRIGGER DIAGNOSTICS
% =========================================================================

no_trigger = GEOLOGY_CLASS.N_TRIGGERS == 0;

one_trigger = GEOLOGY_CLASS.N_TRIGGERS == 1;

multiple_trigger = GEOLOGY_CLASS.N_TRIGGERS > 1;


fprintf('\n');
fprintf('TRIGGER DIAGNOSTICS:\n');

fprintf( ...
    'No trigger     : %d\n', ...
    nnz(no_trigger));

fprintf( ...
    'One trigger    : %d\n', ...
    nnz(one_trigger));

fprintf( ...
    'Multiple       : %d\n', ...
    nnz(multiple_trigger));


%% ========================================================================
% 11. DISPLAY MULTIPLE-TRIGGER UNITS
% =========================================================================
%
% This section is intentionally verbose because it is the main tool for
% refining the rule vocabulary.
%
% Every unit with more than one triggered class is displayed together with:
%
%   ID
%   NOTATION
%   DESCRIPTION
%   FINAL CLASS
%   FIRST MATCHING RULE
%   ALL TRIGGERED CLASSES
%   ALL TRIGGERING KEYWORDS
%
% =========================================================================

if any(multiple_trigger)

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('MULTIPLE CLASSIFICATION TRIGGERS\n');
    fprintf('============================================================\n');

    indices = find(multiple_trigger);

    for ii = 1:numel(indices)

        i = indices(ii);


        fprintf('\n');
        fprintf('ID %d\n',GEOLOGY.ID(i));


        % ---------------------------------------------------------------
        % NOTATION
        % ---------------------------------------------------------------

        if iscell(GEOLOGY.NOTATION)

            notation = string(GEOLOGY.NOTATION{i});

        else

            notation = string(GEOLOGY.NOTATION(i));

        end

        fprintf( ...
            'NOTATION : %s\n', ...
            notation);


        % ---------------------------------------------------------------
        % DESCRIPTION
        % ---------------------------------------------------------------

        d = GEOLOGY.DESCR{i};

        if iscell(d)

            fprintf( ...
                'DESCR    : %s\n', ...
                strjoin(string(d(:))," | "));

        else

            fprintf( ...
                'DESCR    : %s\n', ...
                string(d));

        end


        % ---------------------------------------------------------------
        % FINAL CLASS
        % ---------------------------------------------------------------

        fprintf( ...
            'CLASS    : %s\n', ...
            GEOLOGY_CLASS.CRYOGRID_CLASS(i));


        % ---------------------------------------------------------------
        % ALL TRIGGERED CLASSES
        % ---------------------------------------------------------------

        fprintf( ...
            'TRIGGERS : %s\n', ...
            strjoin( ...
                GEOLOGY_CLASS.TRIGGERS{i}, ...
                ", "));


        % ---------------------------------------------------------------
        % ALL TRIGGERING KEYWORDS
        % ---------------------------------------------------------------

        fprintf( ...
            'RULES    : %s\n', ...
            strjoin( ...
                GEOLOGY_CLASS.TRIGGER_RULES{i}, ...
                " | "));

    end

end


%% ========================================================================
% 12. DISPLAY UNKNOWN UNITS
% =========================================================================
%
% These are the units which currently have no rule trigger at all.
%
% They are the most useful candidates for expanding the rule vocabulary.
%
% =========================================================================

if any(no_trigger)

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('UNCLASSIFIED UNITS\n');
    fprintf('============================================================\n');

    indices = find(no_trigger);

    for ii = 1:numel(indices)

        i = indices(ii);


        fprintf('\n');
        fprintf('ID %d\n',GEOLOGY.ID(i));


        % ---------------------------------------------------------------
        % NOTATION
        % ---------------------------------------------------------------

        if iscell(GEOLOGY.NOTATION)

            notation = string(GEOLOGY.NOTATION{i});

        else

            notation = string(GEOLOGY.NOTATION(i));

        end

        fprintf( ...
            'NOTATION : %s\n', ...
            notation);


        % ---------------------------------------------------------------
        % DESCRIPTION
        % ---------------------------------------------------------------

        d = GEOLOGY.DESCR{i};

        if iscell(d)

            fprintf( ...
                'DESCR    : %s\n', ...
                strjoin(string(d(:))," | "));

        else

            fprintf( ...
                'DESCR    : %s\n', ...
                string(d));

        end

    end

end


%% ========================================================================
% LOCAL FUNCTION: ACCENT-TOLERANT REGEXP
% =========================================================================
%
% Converts a keyword into a regular expression which matches both accented
% and unaccented versions of the relevant Latin characters.
%
% Examples:
%
%   "névé"   -> matches "névé", "neve", "NEVE", etc.
%   "calcaire" remains an ordinary substring search.
%
% =========================================================================

    function pattern = make_pattern(keyword)

        keyword = char(string(keyword));

        pattern = '';

        for kk = 1:numel(keyword)

            c = keyword(kk);

            switch c

                case {'é','è','ê','ë','É','È','Ê','Ë'}

                    pattern = [ ...
                        pattern ...
                        '[eéèêëEÉÈÊË�]']; %#ok<AGROW>


                case {'à','â','ä','À','Â','Ä'}

                    pattern = [ ...
                        pattern ...
                        '[aàâäAÀÂÄ�]']; %#ok<AGROW>


                case {'î','ï','Î','Ï'}

                    pattern = [ ...
                        pattern ...
                        '[iîïIÎÏ�]']; %#ok<AGROW>


                case {'ô','ö','Ô','Ö'}

                    pattern = [ ...
                        pattern ...
                        '[oôöOÔÖ�]']; %#ok<AGROW>


                case {'ù','û','ü','Ù','Û','Ü'}

                    pattern = [ ...
                        pattern ...
                        '[uùûüUÙÛÜ�]']; %#ok<AGROW>


                case {'ÿ','Ÿ'}

                    pattern = [ ...
                        pattern ...
                        '[yÿYŸ�]']; %#ok<AGROW>


                case {'ç','Ç'}

                    pattern = [ ...
                        pattern ...
                        '[cçCÇ�]']; %#ok<AGROW>


                case {'œ','Œ'}

                    pattern = [ ...
                        pattern ...
                        '[œŒ�]']; %#ok<AGROW>


                case {'æ','Æ'}

                    pattern = [ ...
                        pattern ...
                        '[æÆ�]']; %#ok<AGROW>


                otherwise

                    pattern = [ ...
                        pattern ...
                        regexptranslate('escape',c)]; %#ok<AGROW>

            end

        end

    end

end