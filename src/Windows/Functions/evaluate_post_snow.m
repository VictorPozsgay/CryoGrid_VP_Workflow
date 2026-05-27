function post_snow_score = evaluate_post_snow(obs, pred, dates, snow_sequences, nb_days_post)
%EVALUATE_POST_SNOW
%   Computes a model performance score for the days following snow periods.
%
% INPUTS :
%   - obs            : vector of observed temperatures
%   - pred           : vector of predicted temperatures
%   - dates          : vector of datetime corresponding to obs/pred
%   - snow_sequences : cell array of indices corresponding to snow periods
%   - nb_days_post   : number of days after snow to evaluate (default 5)
%
% OUTPUT :
%   - post_snow_score : mean performance score during post-snow periods

    if nargin < 5
        nb_days_post = 5; % default: look at 5 days after snow
    end

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

        % Last day of the snow sequence
        idx_end = idx_seq(end);

        % Indices for the following days
        idx_post = idx_end + (1:nb_days_post);

        % Make sure we don't exceed array limits
        idx_post = idx_post(idx_post <= length(dates));

        if isempty(idx_post)
            continue;
        end

        % Extract obs/pred for this post-snow period
        obs_post = obs(idx_post);
        pred_post = pred(idx_post);

        % Skip sequences with NaNs
        valid = ~isnan(obs_post) & ~isnan(pred_post);
        if nnz(valid) < 2
            continue;
        end

        obs_post = obs_post(valid);
        pred_post = pred_post(valid);

        % Compute a local score
        stats = evaluate_model(obs_post, pred_post);
        trends = compare_trend(obs_post, pred_post, 7);
        [local_score, ~] = score_model(stats, trends);

        local_scores(end+1) = local_score; %#ok<AGROW>
    end

    % Mean of all local scores
    if isempty(local_scores)
        post_snow_score = 0;
    else
        post_snow_score = mean(local_scores);
    end
end

