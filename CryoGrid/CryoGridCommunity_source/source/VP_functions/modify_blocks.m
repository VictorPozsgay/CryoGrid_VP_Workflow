function [TOut, idxBlock] = modify_blocks(TIn, TOut, idxOut, sup, cls, idx, ops)
%MODIFY_BLOCKS Copy a block from TIn to TOut and modify one or more parameters.
%
%   TOut = MODIFY_BLOCKS(TIn, TOut, idxOut, sup, cls, idx, ops)
%
%   Searches TIn for the unique block identified by the triplet
%   (sup, cls, idx). The corresponding block is copied into TOut.
%
%   The source block is located by finding the row of TIn satisfying:
%
%       TIn.sup == sup
%       TIn.cls == cls
%       TIn.idx == idx
%
%   The index of the matching block is denoted idxBlock.
%
%   Destination block selection:
%       - If idxOut is a positive integer, the copied block is written
%         to TOut.blocks{idxOut}.
%       - If idxOut is 0 or false, the copied block is written to
%         TOut.blocks{idxBlock}, i.e. the same position as in TIn.
%
%   After the block has been copied, a sequence of parameter
%   modifications is applied to the copied block in TOut.
%
%   ops is a structure array whose elements contain:
%
%       ops(k).param   Parameter name to modify.
%       ops(k).value   New value to assign to the parameter.
%
%   For each operation k:
%
%       1. The parameter line corresponding to ops(k).param is located
%          within the copied block using IDENTIFYING_LINE_TO_CHANGE.
%
%       2. The parameter value is replaced by ops(k).value using
%          REPLACE_VAL_HLIST.
%
%   The source block in TIn is never modified.
%
%   Inputs
%   ------
%   TIn     Source table containing the original blocks.
%   TOut    Destination table to be modified.
%   idxOut  Destination block index. If 0 or false, use idxBlock.
%   sup     Superclass identifier of the source block.
%   cls     Class identifier of the source block.
%   idx     Numerical class index of the source block.
%   ops     Structure array of parameter modifications.
%
%   Output
%   ------
%   TOut      Modified output table.
%   idxBlock  Index of the source block found in TIn corresponding to
%             the triplet (sup, cls, idx).
%
%   Example
%   -------
%       ops(1).param = "tile_class";
%       ops(1).value = repmat({"TILE_1D"},1,2*numLoops-1);
%
%       ops(2).param = "start_time";
%       ops(2).value = {1958, 9, 1};
%
%       [TOut, idxBlock] = modify_blocks( ...
%           TInit, TOut, 0, ...
%           "RUN_INFO", "RUN_1D_POINT_SPINUP", 1, ...
%           ops);
%

mask = (TIn.sup == sup) & (TIn.cls == cls) & (TIn.idx == idx);
idxBlock = find(mask);

if ~idxOut
    idxOut = idxBlock;
end

TOut.blocks{idxOut} = TIn.blocks{idxBlock};

for k = 1:numel(ops)
    param = ops(k).param;
    value = ops(k).value;

    rowIdx = identifying_line_to_change(TIn.blocks{idxBlock}, ...
        cls, idx, param);

    TOut.blocks{idxOut} = replace_val_hlist( ...
        TOut.blocks{idxOut}, rowIdx, param, value);

end

end
