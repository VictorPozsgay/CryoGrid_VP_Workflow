function res = nanmin(vec)
    % Remove NaN values from the vector
    vec = vec(~isnan(vec)); 
    
    % Return the minimum value if the vector is not empty
    if isempty(vec)
        res = NaN; % Return NaN if all values were NaN
    else
        res = min(vec);
    end
end