function providerInit = modify_parameters(providerInit, providerNew)
%MODIFY_PARAMETERS  Automatic parameter modifier for CryoGrid simulations
%PROVIDER class
% 
% This function applies parameter modifications defined in providerNew to an
% existing CryoGrid PROVIDER object (providerInit).
%
% The update strategy is class-aware:
%   - Structural classes are fully replaced using deep copy
%   - Standard classes are updated parameter-by-parameter by comparison with
%     their default definitions
%
% This ensures that only user-defined deviations from default CryoGrid
% parameters are transferred, preserving consistency of base model structure.
%
% INPUTS
% ------
% providerInit  (PROVIDER)
%     Fully initialized CryoGrid PROVIDER object.
%
% providerNew   (PROVIDER)
%     Fully initialized CryoGrid PROVIDER object with parameters to modify.
% 
% 
% OUTPUTS
% -------
% providerInit  (PROVIDER)
%     Updated provider with updated parameters.
% 
% 
% OVERVIEW
% --------
%
% 1. Iterate over all class types defined in providerNew.CLASSES
%
% 2. For each class:
%       - Instantiate default class definition
%       - Retrieve default parameter structure (provide_PARA)
%
% 3. For each object instance in providerNew:
%       CASE A: Structural class (full replacement)
%           - GRID_user_defined
%           - STRAT_classes
%           - STRAT_layers
%           - STRAT_linear
%
%           → Replace entire object using deep copy
%
%       CASE B: Standard class
%           → Identify modified parameters by comparison with defaults
%           → Update only those parameters in providerInit
%
% 4. Apply safe assignment checks:
%       - class exists in providerInit
%       - parameter field exists in target structure
% 
% 
% SEE ALSO
% --------
%
% PROVIDER, provide_PARA
%

cls = fieldnames(providerNew.CLASSES);
for i = 1:size(cls,1)
    c = cls{i}; % class c to modify, might be multiple iterations of the same class
    class_func = str2func(c);
    new_class = class_func();
    new_class = provide_PARA(new_class); % checks format of default class c
    for j = 1:size(providerNew.CLASSES.(c),1)
        if any(string(c) == ["GRID_user_defined", "STRAT_classes", "STRAT_layers", "STRAT_linear"])
            providerInit.CLASSES.(c){j,1} = copy(providerNew.CLASSES.(c){j,1});
        else
            % find all parameters to modify in class c, tile j, that are
            % different from default value
            pars = fieldnames(new_class.PARA);
            modpars = pars(cellfun(@(f) isfield(providerNew.CLASSES.(c){j,1}.PARA,f) && ~isequal(providerNew.CLASSES.(c){j,1}.PARA.(f), new_class.PARA.(f)), pars));
            for k = 1:size(modpars,1) % find all (param,value) to change
                p = modpars{k};
                v = providerNew.CLASSES.(c){j,1}.PARA.(p);
                if (isfield(providerInit.CLASSES, c)) && (size(providerInit.CLASSES.(c),1)>=j) && (isfield(providerInit.CLASSES.(c){j,1}.PARA, p))
                    providerInit.CLASSES.(c){j,1}.PARA.(p) = v;
                end
            end
        end
    end
end
