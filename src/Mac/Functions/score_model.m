function [score, details] = score_model(stats, trends)
% score_model
%   Computes a global score out of 100 based on errors (70 pts)
%   and curve trend consistency (30 pts)
%
% INPUTS :
%   - stats  : structure containing RMSE, MAE, bias, R, mean difference
%   - trends : structure containing slope_obs, slope_pred, Spearman rho,
%   directional agreement
%
% OUTPUTS :
%   - score   : global score (0-100)
%   - details : structure with detailed scoring components

    %% --- Part 1: Error evaluation (70 points) ---

    % RMSE (10 pts)
    rmse_max = 5;  % maximum tolerated RMSE
    score_rmse = max(0, 10 * (1 - stats.RMSE / rmse_max));

    % MAE (20 pts)
    mae_max = 4;  % maximum tolerated MAE
    score_mae = max(0, 20 * (1 - stats.MAE / mae_max));

    % Bias (20 pts)
    bias_max = 3;  % maximum tolerated absolute bias
    score_bias = max(0, 20 * (1 - abs(stats.Biais) / bias_max));

    % R² (20 pts)
    score_r2 = max(0, 20 * stats.R2);  % R² between 0 and 1

    % Mean temperature (10 pts)
    mean_diff_max = 3;  % max tolerated difference in °C
    score_mean = max(0, 10 * (1 - abs(stats.Mean_Diff) / mean_diff_max));

    %% --- Part 2: Trend consistency evaluation (30 points) ---

    % Slope difference (10 pts)
    slope_diff = abs(trends.Slope_Obs - trends.Slope_Pred);
    score_slope = max(0, 10 * (1 - slope_diff / 0.05));  % 0 beyond 0.05

    % Spearman's rho (10 pts)
    score_rho = max(0, 10 * (trends.Rho_Spearman)^2);

    % Directional agreement (10 pts)
    score_agreement = max(0, 10 * (trends.Trend_Agreement_Percent - 60) / 40);

    %% --- Total score ---
    score = round(score_rmse + score_mae + score_bias + score_r2 + ...
                  score_slope + score_rho + score_agreement + score_mean);

    % Normalize to 100
    score = round(score * 100 / 110);

    %% --- Details structure ---
    details = struct();
    details.Global_Score      = score;
    details.Score_RMSE        = score_rmse;
    details.Score_MAE         = score_mae;
    details.Score_Bias        = score_bias;
    details.Score_R2          = score_r2;
    details.Score_Mean        = score_mean;
    details.Score_Slope       = score_slope;
    details.Score_Rho         = score_rho;
    details.Score_Agreement   = score_agreement;

    % Include raw stats
    details.RMSE              = stats.RMSE;
    details.MAE               = stats.MAE;
    details.Bias              = stats.Biais;
    details.R2                = stats.R2;
    details.Mean_Diff         = stats.Mean_Diff;

    % Include trend info
    details.Slope_Obs         = trends.Slope_Obs;
    details.Slope_Pred        = trends.Slope_Pred;
    details.Rho_Spearman      = trends.Rho_Spearman;
    details.Directional_Agreement = trends.Trend_Agreement_Percent;
end
