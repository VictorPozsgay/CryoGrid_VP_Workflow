function [global_score, seasonal_stats] = score_model_seasonal(obs, pred, dates_excel, dates_cryo, smoothing_window, season_weights)
% score_model_seasonal
%   Computes a global score weighted by season.
%
% INPUTS:
%   - obs, pred                : vectors of observations and predictions
%   - dates_excel, dates_cryo  : datetime vector of observations and predictions
%   - smooth_wondow            : window size for smoothing
%   - season_weights           : structure with fields 'winter', 'spring',
%   etc.
%
% OUTPUTS:
%   - global_score   : weighted global score
%   - season_details : structure with detailed stats per season

    seasons = ["winter", "spring", "summer", "autumn"];
    season_months = containers.Map( ...
        seasons, ...
        {[12,1,2], [3,4,5], [6,7,8], [9,10,11]} ...
    );

    seasonal_stats = struct();
    global_score = 0;
    total_weight = 0;

    for s = seasons
        % Select indices for this season
        months_vec = month(dates_excel);
        idx = ismember(months_vec, season_months(s));

        if nnz(idx) == 0
            warning("⚠️ No data at all for season %s. Skipped.", s);
            continue;
        elseif nnz(idx) < smoothing_window
            warning("⚠️ Season %s has only %d points (< smoothing_window). Still scoring.", s, nnz(idx));
        end

        % Extract seasonal data (copies)
        obs_s = obs(idx);
        pred_s = pred(idx);
        dates_excel_s = dates_excel(idx);
        dates_cryo_s = dates_cryo(idx);

        % Compute statistics
        stats = evaluate_model(obs_s, pred_s, dates_excel_s, dates_cryo_s);
        trends = compare_trends(obs_s, pred_s, smoothing_window);
        [season_score, details] = score_model(stats, trends);

        % Store stats
        season_name = char(s);
        seasonal_stats.(season_name).score = season_score;
        seasonal_stats.(season_name).details = details;
        seasonal_stats.(season_name).stats = stats;

        % Weighted global score
        weight = season_weights.(season_name);
        global_score = global_score + weight * season_score;
        total_weight = total_weight + weight;
    end

    % Weighted average
    if total_weight > 0
        global_score = round(global_score / total_weight);
    else
        warning("⚠️ No season was scored.");
        global_score = NaN;
    end

    % Global averages
    global_stats = struct('R2', [], 'RMSE', [], 'Mean_Diff', []);
    n = 0; total_R2 = 0; total_RMSE = 0; total_DIFF = 0;

    for s = seasons
        if isfield(seasonal_stats, s)
            stats = seasonal_stats.(s).stats;
            total_R2 = total_R2 + stats.R2;
            total_RMSE = total_RMSE + stats.RMSE;
            total_DIFF = total_DIFF + stats.Mean_Diff;
            n = n + 1;
        end
    end

    if n > 0
        SS_res = sum((pred - obs).^2);
        SS_tot = sum((obs - mean(obs)).^2);
        global_stats.R2 = 1 - SS_res/SS_tot;
        global_stats.RMSE = sqrt(mean((pred - obs).^2));
        global_stats.Mean_Diff = average_temperature_over_years(pred, dates_cryo) - average_temperature_over_years(obs, dates_excel);
    else
        global_stats.R2 = NaN;
        global_stats.RMSE = NaN;
        global_stats.Mean_Diff = NaN;
    end

    seasonal_stats.Global = global_stats;
end
