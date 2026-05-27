function results = compare_trends(obs, pred, smooth_window)
% compare_trends
%   Compare trends between observed and predicted data:
%   - Smoothing (moving average)
%   - Linear regression (overall slope)
%   - Spearman correlation (rank-based)
%   - Local directional agreement (%)
%
% INPUTS :
%   - obs  : observations (vector)
%   - pred : predictions (vector)
%   - smooth_window : size of moving average (e.g., 7)
%
% OUTPUT :
%   - results : structure with 3 trend indicators

    % Check input lengths
    if length(obs) ~= length(pred)
        error('Vectors obs and pred must have the same length.');
    end

    obs  = obs(:);
    pred = pred(:);

    % Smoothing (moving average)
    obs_smooth  = movmean(obs, smooth_window);
    pred_smooth = movmean(pred, smooth_window);

    % 1. 📈 Linear regression (slope)
    x = (1:length(obs_smooth))';
    p_obs  = polyfit(x, obs_smooth, 1);
    p_pred = polyfit(x, pred_smooth, 1);
    slope_obs  = p_obs(1);
    slope_pred = p_pred(1);

    % 2. 📊 Spearman correlation (without toolbox)
    ranks_obs  = rankdata(obs_smooth);
    ranks_pred = rankdata(pred_smooth);
    
    % Pearson correlation on ranks
    rho_spearman = pearson_corr(ranks_obs, ranks_pred);

    % 3. 🔁 Local directional agreement (compare variations)
    trend_obs  = sign(diff(obs_smooth));
    trend_pred = sign(diff(pred_smooth));
    agreement = mean(trend_obs == trend_pred) * 100;

    % Results
    results.Slope_Obs = slope_obs;
    results.Slope_Pred = slope_pred;
    results.Rho_Spearman = rho_spearman;
    results.Trend_Agreement_Percent = agreement;
end

%% Auxiliary function: compute ranks (without toolbox)
function ranks = rankdata(x)
    [~, sorted_idx] = sort(x);
    ranks = zeros(size(x));
    ranks(sorted_idx) = 1:length(x);
end

%% Auxiliary function: manual Pearson correlation
function r = pearson_corr(a, b)
    a = a(:); b = b(:);
    a_mean = mean(a);
    b_mean = mean(b);
    r = sum((a - a_mean) .* (b - b_mean)) / sqrt(sum((a - a_mean).^2) * sum((b - b_mean).^2));
end
