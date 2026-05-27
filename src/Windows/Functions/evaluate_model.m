 function stats = evaluate_model(obs, pred, dates_excel, dates_cryo)
%EVALUATE_MODEL
%   Computes basic statistical metrics between a model prediction and observations.
%
% INPUTS :
%   - obs  : vector of observations (sensor data)
%   - pred : vector of model predictions
%
% OUTPUT :
%   - stats : structure containing RMSE, MAE, bias, correlation,
%             mean temperatures

    % Basic checks
    if length(obs) ~= length(pred)
        error('Vectors obs and pred must have the same length.');
    end

    obs = obs(:);   % ensure column vectors
    pred = pred(:);

    % 1. RMSE
    rmse = sqrt(mean((pred - obs).^2));

    % 2. MAE
    mae = mean(abs(pred - obs));

    % 3. Bias
    bias = mean(pred - obs);

    % 4. R^2
    SS_res = sum((obs - pred).^2);
    SS_tot = sum((obs - mean(obs)).^2);
    R2 = 1 - (SS_res / SS_tot);
    
    % 5. Mean temperature
    mean_obs  = average_temperature_over_season(obs, dates_excel);
    mean_pred = average_temperature_over_season(pred, dates_cryo);
    mean_difference = mean_pred - mean_obs;

    % Return results in a structure
    stats.RMSE  = rmse;
    stats.MAE   = mae;
    stats.Bias  = bias;
    stats.R2    = R2;
    stats.Mean_Obs  = mean_obs;
    stats.Mean_Pred = mean_pred;
    stats.Mean_Diff = mean_difference;
end
