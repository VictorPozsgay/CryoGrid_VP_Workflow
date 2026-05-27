function post_snow_score = evaluate_post_snow(obs, pred, dates, snow_sequences, nb_post_days)

    if nargin < 5
        nb_post_days = 5; % default: look 5 days after
    end

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

        % Last day of the snow sequence
        last_idx = seq_idx(end);

        % Indices of following days
        post_idx = last_idx + (1:nb_post_days);

        % Ensure we do not exceed array bounds
        post_idx = post_idx(post_idx <= length(dates));

        if isempty(post_idx)
            continue;
        end

        % Extract obs/pred for this post-snow period
        obs_post = obs(post_idx);
        pred_post = pred(post_idx);

        % Ignore cases with NaN
        valid = ~isnan(obs_post) & ~isnan(pred_post);
        if nnz(valid) < 2
            continue;
        end

        obs_post = obs_post(valid);
        pred_post = pred_post(valid);

        % Compute local score
        stats = evaluate_model(obs_post, pred_post);
        trends = compare_trends(obs_post, pred_post, 7);
        [local_score, ~] = score_model(stats, trends);

        local_scores(end+1) = local_score; %#ok<AGROW>
    end

    % Average of obtained scores
    if isempty(local_scores)
        post_snow_score = 0;
    else
        post_snow_score = mean(local_scores);
    end
end
