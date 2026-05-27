function snow_score = evaluate_during_snow(obs, pred, dates, snow_sequences)

    % Size check
    if length(obs) ~= length(pred) || length(pred) ~= length(dates)
        error('obs, pred, and dates must have the same length');
    end

    local_scores = [];

    for i = 1:length(snow_sequences)
        seq_idx = snow_sequences{i};

        % Keep only sequences of length ≥ 3 days
        if length(seq_idx) < 3
            continue;
        end

        % Extract obs/pred for the snow sequence
        obs_seq = obs(seq_idx);
        pred_seq = pred(seq_idx);

        % Ignore cases with too many NaNs
        valid = ~isnan(obs_seq) & ~isnan(pred_seq);
        if nnz(valid) < 2
            continue;
        end

        obs_seq = obs_seq(valid);
        pred_seq = pred_seq(valid);

        % Compute local score for this sequence
        stats = evaluate_model(obs_seq, pred_seq);
        trends = compare_trends(obs_seq, pred_seq, 7);
        [local_score, ~] = score_model(stats, trends);

        local_scores(end+1) = local_score; %#ok<AGROW>
    end

    % Average of obtained scores
    if isempty(local_scores)
        snow_score = 0;
    else
        snow_score = mean(local_scores);
    end
end
