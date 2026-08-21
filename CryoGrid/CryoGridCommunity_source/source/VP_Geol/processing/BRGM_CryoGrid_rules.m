function RULES = BRGM_CryoGrid_rules()
%BRGM_CRYOGRID_RULES Rules for reducing BRGM geological units to CryoGrid classes.
%
% FINAL CRYOGRID CLASSES
%
%   BEDROCK
%   SCREE
%   TILL
%   SEDIMENT
%   ORGANIC
%   ICE
%   UNKNOWN
%   WATER       % water-mask class
%
% The rules are intentionally material-oriented rather than attempting to
% reproduce the previous BROAD_CLASS / MATERIAL_CLASS distinction.
%
% Each class may contain:
%
%   KEYWORDS
%       Substrings which trigger the class when found in the geological
%       description.
%
%   NOTATIONS
%       Exact BRGM geological NOTATION codes which trigger the class.
%       This is useful when the description alone does not provide a
%       sufficiently specific material indicator.
%
%   EXCLUDE
%       Strings which suppress a specific keyword match.
%
% Keyword matching is deliberately NOT word-aware:
%
%   - keywords may be substrings of larger words when scientifically useful
%   - multi-word keywords are supported
%   - accented characters are matched using accent-tolerant patterns by the
%     classification engine
%
% For example:
%
%   KEYWORD = "coulées de boue"
%
% matches descriptions containing encoding-corrupted variants such as
% "Coul�es de boues", provided the difference is limited to the tolerated
% accented-character substitutions.
%
% NOTATIONS are handled separately from keyword matching. They should be
% used only where the BRGM NOTATION itself provides a sufficiently reliable
% classification signal.
%
% Example:
%
%   RULES.BEDROCK.NOTATIONS = [
%       "Rc"
%       "Rt"
%   ];
%
% Then units with NOTATION "Rc" or "Rt" are classified as BEDROCK even if
% their description contains no BEDROCK keyword.
%
% EXCLUSIONS
%
% EXCLUDE entries are used to suppress specific false-positive keyword
% matches without removing the keyword itself from the rule set.
%
% Example:
%
%   KEYWORD = "névé"
%   EXCLUDE = "Ecenévex"
%
% Then "névé" can match normally, while the occurrence inside "Ecenévex"
% is ignored.
%
% CLASSIFICATION PRIORITY
%
% The order in CLASS_ORDER defines the priority of competing classes.
% The classification engine uses FIRST MATCH WINS for the final
% CRYOGRID_CLASS.
%
% The classification engine should nevertheless retain ALL triggered
% classes and triggering keywords/notational rules for diagnostics.
%
% Current philosophy:
%
%   WATER
%   ORGANIC
%   ICE
%   SCREE
%   TILL
%   SEDIMENT
%   BEDROCK
%
% More specific surface-material and mask indicators therefore override
% generic geological-rock terms.
%
% =========================================================================

RULES = struct();


%% ========================================================================
% CLASSIFICATION PRIORITY
% =========================================================================
%
% IMPORTANT:
%   First matching class wins.
%
% The order should therefore be changed deliberately.
%
% Current philosophy:
%
%   ORGANIC
%   ICE
%   SCREE
%   TILL
%   SEDIMENT
%   BEDROCK
%
% More specific / diagnostic surface-material indicators are therefore
% allowed to override generic geological-rock terms.
%
% =========================================================================

RULES.CLASS_ORDER = [
    "WATER"
    "ORGANIC"
    "ICE"
    "SCREE"
    "TILL"
    "SEDIMENT"
    "BEDROCK"
];


%% ========================================================================
% ORGANIC
% =========================================================================

RULES.ORGANIC.KEYWORDS = [
    "tourbe"
    "tourbière"
    "marais"
    "mire"
];


%% ========================================================================
% ICE
% =========================================================================
%
% Includes actual ice/glacier-related terrain and rock glaciers.
%
% IMPORTANT:
%   "glacier" is intentionally included, but false substring matches can
%   occur in unrelated words. Add such cases to the corresponding EXCLUDE
%   list as they are discovered.
%
% =========================================================================

RULES.ICE.KEYWORDS = [
    "névé"
    "cryokarst"
    "glacier rocheux"
    "glaciers rocheux"
    "glace"
];


%% ========================================================================
% SCREE
% =========================================================================

RULES.SCREE.KEYWORDS = [
    "éboulis"
    "éboulement"
    "écroulement"
    "talus"
    "gélivation"
    "avalanche"
    "brèche de pente"
    "cône d'éboulis"
    "glissement"
    "glissé"
];


%% ========================================================================
% TILL
% =========================================================================
%
% Till here means glacial / moraine-derived unconsolidated material.
%
% This does NOT mean that every occurrence of "glaciaire" should be TILL:
% ICE has higher priority and explicit glacial-ice terms therefore win.
%
% =========================================================================

RULES.TILL.KEYWORDS = [
    "moraine"
    "morainique"
    "dépôt glaciaire"
    "dépôts glaciaires"
    "dépôt glaciaux"
    "dépôts glaciaux"
    "till"
];


%% ========================================================================
% SEDIMENT
% =========================================================================
%
% General unconsolidated / sedimentary surface material.
%
% This intentionally contains a broad vocabulary. The purpose is to
% distinguish sedimentary surface material from BEDROCK, not to reproduce
% every geological sediment type separately.
%
% =========================================================================

RULES.SEDIMENT.KEYWORDS = [

    % General sediment / deposits
    "sédiment"
    "dépôt"
    "cône de déjection"
    "cônes de déjection"

    % Alluvial / fluvial
    "alluvion"
    "fluviatile"
    "fluvial"
    "torrent"

    % Colluvial / slope deposits
    "colluvion"
    "colluvial"
    "coulée de boue"
    "coulées de boue"
    "formation de versant"
    "formations de versant"

    % Fine sediment
    "argile"
    "argilo"
    "limon"
    "sable"
    "loess"
    "lehm"
    "pélite"

    % Coarse sediment
    "cailloutis"
    "cailloux"
    "galet"
    "gravier"
    "bloc"

    % Conglomeratic / breccia material
    "conglomérat"
    "poudingue"
    "brèche"

    % Glaciofluvial
    "fluvio-glaciaire"
    "fluvio glaciaire"
    "fluvioglaciaire"

    % Aeolian
    "dune"

    % Lacustrine
    "lacustre"

    % Terrace
    "terrasse"
    "terasse"  % there is one with a spelling mistake

    % Travertine
    "travertin"
];


%% ========================================================================
% BEDROCK
% =========================================================================
%
% Explicit lithological / bedrock vocabulary.
%
% This is deliberately the lowest-priority class because many BRGM
% descriptions contain both a bedrock lithology and a surface deposit.
%
% Example:
%
%   "colluvions à éléments calcaires"
%
% contains "calcaire", but should be allowed to become SEDIMENT rather than
% BEDROCK because SEDIMENT has higher priority.
%
% =========================================================================

RULES.BEDROCK.KEYWORDS = [

    % Carbonate rocks
    "calcaire"
    "calc."
    "dolomie"
    "dolomitique"
    "dolomitisé"
    "marne"
    "calcschiste"
    "marbre"
    "cipolin"
    "calcite"
    "carbonaté"

    % Sulphates
    "cargneule"
    "gypse"

    % Metamorphic rocks
    "schiste"
    "schisto"
    "gneiss"
    "quartzite"
    "micaschiste"
    "migmat"
    "amphibolite"
    "anatexite"
    "agmatite"
    "mylonite"
    "phyllonite"
    "prasinite"
    "ovardite"
    "éclogite"
    "albitite"

    % Igneous / volcanic rocks
    "granit"
    "granite"
    "rhyolite"
    "rhyolitique"
    "basalte"
    "andésite"
    "gabbro"
    "spilite"
    "kératophyre"
    "dolérite"
    "diabase"
    "pegmatite"
    "aplite"

    % Sedimentary / siliceous bedrock
    "quartz"
    "arkose"
    "arkosique"
    "grès"
    "flysch"
    "molasse"
    "terres noires"
    "terre noire"
    "radiolarite"
    "radiolaritique"
    "silex"
    "lumachelle"

    % Other rocks
    "ophiolite"
    "ophiolitique"
    "serpentinite"
    "tuf"
    "métamorphique"
    "cristallin"

    % Mineralised rocks
    "sidérite"
    "sidérose"
    "ankérite"
    "ankéritique"

    % Explicit basic rocks
    "roches basiques"
    "roche basique"

    %others
    "karst"
    "olistolithe"
    "olistolithique"
    "urgonien"
    "argilite"
];

RULES.BEDROCK.NOTATIONS = [
    "Rc"
    "Rt"
    "c5L"
    "c6L"
    "g1a_(e)"
    "g1a_PS(B)"
    "h3-5a"
    "j2a-bJ"
    "j4-5J"
    "j5cJ(2)"
    "l-j4"
    "l1-3E"
    "l2_(3)"
    "l3-n2"
    "m1"
    "n1-2(2)"
    "n3-4R"
    "p2-IV"
    "t-ch"
    "t6-7_(1)"
];


%% ========================================================================
% WATER
% =========================================================================

RULES.WATER.KEYWORDS = [
    "hydro"
];


%% ========================================================================
% EXCLUSIONS
% =========================================================================

RULES.EXCLUDE = [
    "Ecenévex"   % névé
    "lentilles"  % till
];

end