function snow_score = evaluate_during_snow(obs, pred, dates, snow_sequences)
%EVALUATE_DURING_SNOW
%   Computes a performance score of the model specifically during snow periods.
%
% INPUTS :
%   - obs           : vector of observed temperatures
%   - pred          : vector of predicted temperatures
%   - dates         : vector of datetime corresponding to obs/pred
%   - snow_sequences: cell array of indices corresponding to snow periods
%
% OUTPUT :
%   - snow_score    : mean performance score during snow sequences

    % Check sizes
    if length(obs) ~= length(pred) || length(pred) ~= length(dates)
        error('obs, pred, and dates must have the same length.');
    end

    local_scores = [];

    for i = 1:length(snow_sequences)
        idx_seq = snow_sequences{i};

        % Keep only sequences with length ≥ 3 days
        if length(idx_seq) < 3
            continue;
        end

        % Extract obs/pred for the snow sequence
        obs_seq = obs(idx_seq);
        pred_seq = pred(idx_seq);

        % Skip sequences with too many NaNs
        valid = ~isnan(obs_seq) & ~isnan(pred_seq);
        if nnz(valid) < 2
            continue;
        end

        obs_seq = obs_seq(valid);
        pred_seq = pred_seq(valid);

        % Compute local score for this sequence
        stats = evaluate_model(obs_seq, pred_seq);
        trends = compare_trend(obs_seq, pred_seq, 7);
        [local_score, ~] = score_model(stats, trends);

        local_scores(end+1) = local_score; %#ok<AGROW>
    end

    % Mean of all local scores
    if isempty(local_scores)
        snow_score = 0;
    else
        snow_score = mean(local_scores);
    end
end
