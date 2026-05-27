function [global_score, season_details] = score_model_seasonal(obs, pred, dates_excel, dates_cryo, smooth_window, season_weights)
%SEASONAL_MODEL_SCORE
%   Computes a global score weighted by seasons.
%
% INPUTS:
%   - obs, pred      : vectors of observations and predictions
%   - dates          : datetime vector (same length as obs/pred)
%   - smooth_window  : window size for smoothing
%   - season_weights : structure with fields 'winter', 'spring', etc.
%
% OUTPUTS:
%   - global_score   : weighted global score
%   - season_details : structure with detailed stats per season

    seasons = ['winter', 'spring', 'summer', 'autumn'];
    months_per_season = containers.Map( ...
        seasons, ...
        {[12,1,2], [3,4,5], [6,7,8], [9,10,11]} ...
    );

    season_details = struct();
    global_score = 0;
    total_weight = 0;

    for s = seasons
        % Select indices for this season
        m = month(dates_excel);
        idx = ismember(m, months_per_season(s));

        if nnz(idx) == 0
            warning('⚠️ Not enough data for season %s. Ignored.', s);
            continue;
        elseif nnz(idx) < smooth_window
            warning('⚠️ Season %s has only %d points (< smoothing window). Still scoring.', s, nnz(idx));
        end

        % Extract data
        obs_s = obs(idx);
        pred_s = pred(idx);
        dates_excel_s = dates_excel(idx);
        dates_cryo_s = dates_cryo(idx);

        % Compute stats
        stats = evaluate_model(obs_s, pred_s, dates_excel_s, dates_cryo_s);
        trends = compare_trends(obs_s, pred_s, smooth_window);
        [season_score, details] = score_model(stats, trends);

        % Store detailed info
        season_name = char(s);
        season_details.(season_name).score = season_score;
        season_details.(season_name).details = details;
        season_details.(season_name).stats = stats;

        % Weighting
        weight = season_weights.(season_name);
        global_score = global_score + weight * season_score;
        total_weight = total_weight + weight;
    end

    % Weighted average
    if total_weight > 0
        global_score = round(global_score / total_weight);
    else
        warning('⚠️ No season was scored.');
        global_score = NaN;
    end

    % Compute simple global averages of key stats across seasons
    stats_global = struct('R2', [], 'RMSE', [], 'Mean_Diff', []);
    count = 0;
    total_R2 = 0; total_RMSE = 0; total_DIFF = 0;

    for s = seasons
        if isfield(season_details, s)
            stats = season_details.(s).stats;
            total_R2   = total_R2 + stats.R2;
            total_RMSE = total_RMSE + stats.RMSE;
            total_DIFF = total_DIFF + stats.Mean_Diff;
            count = count + 1;
        end
    end

    if count > 0
        SS_res = sum((obs - pred).^2);
        SS_tot = sum((obs - mean(obs)).^2);
        stats_global.R2          = 1 - (SS_res / SS_tot);
        stats_global.RMSE        = sqrt(mean((pred - obs).^2));
        stats_global.Mean_Diff   = average_temperature_over_years(pred, dates_cryo) - average_temperature_over_years(obs, dates_excel);
    else
        stats_global.R2        = NaN;
        stats_global.RMSE      = NaN;
        stats_global.Mean_Diff = NaN;
    end

    season_details.Global = stats_global;
end
