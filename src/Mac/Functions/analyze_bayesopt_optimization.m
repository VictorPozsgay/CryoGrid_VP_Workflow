function [best_params, best_score] = analyze_bayesopt_optimization(results)
% analyze_bayesopt_results - Analyze and visualize Bayesian optimization results
%
% Inputs:
%   results - output from bayesopt function (contains XTrace, ObjectiveTrace, etc.)
%
% Outputs:
%   best_params - table (1 row) with the best set of parameters found
%   best_score  - best score (performance) obtained
%
% This function plots:
% 1) Convergence of the score (performance)
% 2) Individual influence of each parameter on the score
% 3) 3D surface/interpolation of the score according to the first two parameters
%
% Note: The function assumes bayesopt minimizes the objective.
% If a higher score is better, the objective is inverted.

    % Get tested parameters (table)
    T = results.XTrace;

    % Get objective (minimized by bayesopt)
    objective = results.ObjectiveTrace;

    % Invert score if needed (higher is better)
    scores = -objective;

    % Find the index of the best score (max because inverted)
    [best_score, idx_best] = max(scores);

    % Extract the best set of parameters (1-row table)
    best_params = T(idx_best, :);

    % Display best parameters and score
    fprintf('Best score: %.4f\n', best_score);
    fprintf('Best parameter set:\n');
    disp(best_params);

    % Parameter names (columns of T)
    param_names = T.Properties.VariableNames;

    % --------- 1. Convergence plot ---------
    figure;
    plot(scores, '-o', 'LineWidth', 1.5);
    xlabel('Iteration');
    ylabel('Score');
    title('Performance convergence');
    grid on;

    % --------- 2. Individual influence ---------
    
    n_params = length(param_names);
    figure;
    
    for i = 1:n_params
        % Histogram of the parameter
        subplot(n_params,2,2*i-1);
        histogram(T.(param_names{i}), 20, 'FaceColor', [0.2 0.6 0.8]);
        xlabel(param_names{i}, 'Interpreter', 'none');
        ylabel('Frequency');
        title(['Distribution of ', param_names{i}]);
        grid on;
    
        % Scatter parameter vs score
        subplot(n_params,2,2*i);
        scatter(T.(param_names{i}), scores, 50, 'filled');
        xlabel(param_names{i}, 'Interpreter', 'none');
        ylabel('Score');
        title(['Influence of ', param_names{i}]);
        grid on;
    end

    % --------- 3. 3D surface/interpolation for first two parameters ---------
    if n_params < 3

        x = T.(param_names{1});
        y = T.(param_names{2});
        z = scores;

        % Regular grid
        [Xq, Yq] = meshgrid(linspace(min(x), max(x), 50), linspace(min(y), max(y), 50));
        Zq = griddata(x, y, z, Xq, Yq, 'cubic');

        figure;
        surf(Xq, Yq, Zq);
        xlabel(param_names{1}, 'Interpreter', 'none');
        ylabel(param_names{2}, 'Interpreter', 'none');
        zlabel('Score');
        title(['Performance surface vs ', param_names{1}, ' and ', param_names{2}]);
        shading interp;
        colormap(flipud(jet)); % ou flipud(parula), flipud(hot), etc.
        c = colorbar;
        ylabel(c, 'Score');
        grid on;

    else

        % Variables
        x = T.(param_names{1});
        y = T.(param_names{2});
        z = T.(param_names{3});
        scores = results.ObjectiveTrace;  % Recover scores directly
        
        % Regular Grid (denser grid)
        nGrid = 50;
        [Xq, Yq, Zq] = meshgrid(linspace(min(x), max(x), nGrid), ...
                                linspace(min(y), max(y), nGrid), ...
                                linspace(min(z), max(z), nGrid));
        
        % 3D Interpolation
        F = scatteredInterpolant(x, y, z, scores, 'linear', 'none');
        Vq = F(Xq, Yq, Zq);
        
        % Low threshold for testing
        iso_val = prctile(scores, 20);  
        
        figure;
        p = patch(isosurface(Xq, Yq, Zq, Vq, iso_val));
        isonormals(Xq, Yq, Zq, Vq, p);  
        p.FaceColor = 'red';
        p.EdgeColor = 'none';
        
        camlight; lighting gouraud;
        xlabel(param_names{1}, 'Interpreter', 'none');
        ylabel(param_names{2}, 'Interpreter', 'none');
        zlabel(param_names{3}, 'Interpreter', 'none');
        title(sprintf('Isosurface forcée (>= %.2f)', iso_val));
        grid on; axis tight; view(3);
        
        % Real points
        hold on;
        scatter3(x, y, z, 50, scores, 'filled', 'MarkerEdgeColor', 'k');
        colormap(flipud(jet)); % ou flipud(parula), flipud(hot), etc.
        c = colorbar;
        ylabel(c, 'Score');

    end

end
