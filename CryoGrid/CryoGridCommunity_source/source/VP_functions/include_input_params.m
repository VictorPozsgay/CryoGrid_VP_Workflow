function [TNew, TInit, TNext, TRestart] = include_input_params(TNew, TInit, TNext, TRestart)

for i = 1:size(TNew,1)
    rowA = TNew(i,1:3);
    [tfInit, idxInit] = ismember(rowA, TInit(:,1:3), 'rows');
    [tfNext, idxNext] = ismember(rowA, TNext(:,1:3), 'rows');
    [tfRestart, idxRestart] = ismember(rowA, TRestart(:,1:3), 'rows');
    if strcmp(rowA.cls, "STRAT_linear")
        if tfInit
            TInit.blocks{idxInit} = TNew.blocks{i};
        elseif tfNext
            TNext.blocks{idxNext} = TNew.blocks{i};
        elseif tfRestart
            TRestart.blocks{idxRestart} = TNew.blocks{i};
        end
    else
        for j = 1:size(TNew.blocks{i},1)
            row = TNew.blocks{i}(j,:);
            strt = string(row(1));
            if ~strcmp(strt,"")
                if tfInit
                    matchIdx = find(strcmp(string(TInit.blocks{idxInit}(:,1)), strt));
                    for m=1:numel(matchIdx)
                        TInit.blocks{idxInit}(matchIdx(m),1:numel(row)) = row;
                    end
                elseif tfNext
                    matchIdx = find(strcmp(string(TNext.blocks{idxNext}(:,1)), strt));
                    for m=1:numel(matchIdx)
                        TNext.blocks{idxNext}(matchIdx(m),1:numel(row)) = row;
                    end
                elseif tfRestart
                    matchIdx = find(strcmp(string(TRestart.blocks{idxRestart}(:,1)), strt));
                    for m=1:numel(matchIdx)
                        TRestart.blocks{idxRestart}(matchIdx(m),1:numel(row)) = row;
                    end
                end
            end
        end
    end
end

end
