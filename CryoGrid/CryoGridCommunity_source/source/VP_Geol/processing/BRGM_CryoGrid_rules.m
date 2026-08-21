function RULES = BRGM_CryoGrid_rules()
%BRGM_CRYOGRID_RULES Scientific rules for BRGM -> CryoGrid geology classification.
%
% =========================================================================
% SCIENTIFIC CLASSIFICATION INPUT
% =========================================================================
%
% This file defines the SCIENTIFIC INPUT to the BRGM geological
% classification used to generate CryoGrid-compatible geology classes.
%
% The classification is based on:
%   1. BRGM geological NOTATION codes
%   2. Keywords identified in BRGM geological descriptions
%   3. Rule strength (STRONG / WEAK)
%   4. CLASS_ORDER for resolving equal-strength conflicts
%
% These rules therefore define the scientific interpretation of the BRGM
% geological database and should be modified deliberately and documented
% when the classification methodology is changed.
%
% =========================================================================
% OUTPUT CLASSES
% =========================================================================
%
%   WATER       Water / water-mask units
%   ORGANIC     Organic-rich deposits, e.g. peat and mire
%   ICE         Glacier and ice-related terrain, including rock glaciers
%   SCREE       Scree, rockfall and slope-failure deposits
%   TILL        Glacial / moraine-derived unconsolidated material
%   SEDIMENT    Other unconsolidated or sedimentary surface material
%   BEDROCK     Consolidated geological bedrock
%   UNKNOWN     Units for which no classification rule is triggered
%
% =========================================================================
% RULE TYPES
% =========================================================================
%
% Each material class may define:
%
%   STRONG
%       Strong diagnostic keywords. These have the highest classification
%       strength.
%
%   WEAK
%       Less diagnostic keywords. These are used only when no stronger
%       classification signal is present.
%
%   NOTATIONS
%       Exact BRGM NOTATION codes providing a direct classification.
%
%   EXCLUDE
%       Global text patterns used to suppress known false-positive
%       keyword matches.
%
% =========================================================================
% CLASSIFICATION LOGIC
% =========================================================================
%
% Classification strength:
%
%       STRONG > WEAK
%
% If several classes have the same strongest signal, CLASS_ORDER determines
% the winning class. The order therefore represents the scientific
% precedence assigned to competing material interpretations.
%
% Current precedence:
%
%       WATER > ORGANIC > ICE > SCREE > TILL > SEDIMENT > BEDROCK
%
% This allows specific surface-material indicators to override generic
% geological lithology. For example, "colluvions à éléments calcaires"
% should be classified as SEDIMENT rather than BEDROCK.
%
% Exact NOTATION rules override keyword-based classification.
%
% =========================================================================
% KEYWORD MATCHING
% =========================================================================
%
% Keywords are intentionally matched as substrings rather than requiring
% complete words. Multi-word keywords are supported.
%
% The classification engine handles accented-character encoding issues
% present in the source BRGM database.
%
% Nested keyword matches are resolved so that a more specific match is
% retained when one keyword is contained within another.
%
% EXCLUDE rules are used only for documented false-positive cases and do
% not remove the corresponding scientific keyword from the rule set.
%
% =========================================================================
% METHODOLOGICAL NOTE
% =========================================================================
%
% The purpose of this classification is to reduce the detailed BRGM
% geological units to a small number of material classes suitable for
% CryoGrid modelling. It is therefore a MATERIAL-ORIENTED classification,
% not a reproduction of the original BRGM geological taxonomy.
%
% The rules below constitute the scientific classification definition.
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
%   WATER
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

RULES.ORGANIC.STRONG = [
    "tourbe"
    "tourbière"
    "marais"
    "mire"
];

RULES.ORGANIC.WEAK = [
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

RULES.ICE.STRONG = [
    "névé"
    "cryokarst"
    "glacier rocheux"
    "glaciers rocheux"
    "glace"
];

RULES.ICE.WEAK = [
];


%% ========================================================================
% SCREE
% =========================================================================

RULES.SCREE.STRONG = [
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

RULES.SCREE.WEAK = [
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

RULES.TILL.STRONG = [
    "moraine"
    "morainique"
    "dépôt glaciaire"
    "dépôts glaciaires"
    "dépôt glaciaux"
    "dépôts glaciaux"
    % "till"          % get rid of it because it ONLY triggers excluded
    % words such as "lentille", "Chatillon", and "Chastillon"
];

RULES.TILL.WEAK = [
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

RULES.SEDIMENT.STRONG = [

    % General sediment / deposits
    "sédiment"
    "cône de déjection"
    "cônes de déjection"

    % Alluvial / fluvial
    "alluvion"
    "fluviatile"
    "fluvial"

    % Colluvial / slope deposits
    "colluvion"
    "colluvial"
    "coulée de boue"
    "coulées de boue"
    "formation de versant"
    "formations de versant"

    % Fine sediment
    "argile"
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

    % Anthropique
    "anthropique"
    "artificiel"
];

RULES.SEDIMENT.WEAK = [
    "argileuse"
    "argileux"
    "argilo"
    "caillouteuse"
    "caillouteux"
    "caillouto"
    "conglomératique"
    "glauconieuse"
    "glauconieux"
    "limoneuse"
    "limoneux"
    "limono"
    "pélitique"
    "sableuse"
    "sableux"
    "sablo"
    "silteuse"
    "silteux"
    "silto"
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

RULES.BEDROCK.STRONG = [

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
    "gneiss"
    "quartzite"
    "micaschiste"
    "migmatite"
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

RULES.BEDROCK.WEAK = [
    "albitique"
    "calcaro"
    "gneissique"
    "granitisé"
    "granitoïde"
    "granitique"
    "gréseuse"
    "gréseux"
    "gréso"
    "gypseuse"
    "gypseux"
    "karstique"
    "marbreuse"
    "marbreux"
    "marneuse"
    "marneux"
    "marno"
    "métamorphique"
    "micacé"
    "migmatiques"
    "migmatisé"
    "migmatitique"
    "quartzeux"
    "quartzo"
    "quartzique"
    "quartziteux"
    "quartzitique"
    "schisteuse"
    "schisteux"
    "schisto"
    "siliceuse"
    "siliceux"
    "silicieuse"
    "silicieux"
    "silico"
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

RULES.WATER.STRONG = [
    "hydro"
];

RULES.WATER.WEAK = [
];


%% ========================================================================
% EXCLUSIONS
% =========================================================================

RULES.EXCLUDE = [
    "Ecenévex"    % névé
    "Genève"      % névé
    "Grésivaudan" % grès
    "inframorainique"
    "non migmatitique"
    "non calcaire"
    "Nappe de la Brèche"
    "Nappe des Gypses"
    % "lentille"    % till
    % "Chastillon"  % till
    % "Chatillon"   % till
];

end