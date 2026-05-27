function [BestXTable, MinObserved, Iteration] = minObservedPoint(this)
% Returns the feasible point BestXTable with the minimum
% observed Objective value. Feasibility is judged by the
% current constraint and error models.
%

%   Copyright 2016-2024 The MathWorks, Inc.

FeasMask = double(this.FeasibilityTrace);
FeasMask(FeasMask==0) = NaN;
InBoundsMask = double(~isPointOutOfBounds(this, this.XTrace));
InBoundsMask(InBoundsMask==0) = NaN;
[MinObserved, Iteration] = min($1, [], 'omitnan');
else
    BestXTable = [];
    MinObserved = NaN;
    Iteration = NaN;
end
end
