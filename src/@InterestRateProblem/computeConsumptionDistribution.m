function C = computeConsumptionDistribution(self, state, policy)

%% Compute non-normalized policies
deNormPolicy = self.getDeNormPolicies(policy);

%% Compute non-normalized consumption
times = self.Time.getRange();
numberOfPaths = size(deNormPolicy, 1);

C = zeros(numberOfPaths, numel(times));
switch lower(self.modelVariant)
    case 'debug'
        C = state.W(:, 1:end-1) - sum(deNormPolicy, 3);
    case {'noannuitywithbond', 'debugonlybond'}
        C = state.W(:, 1:end-1) - sum(deNormPolicy, 3);
    case {'termcertainannuitynobond', 'lifeannuitynobond', 'lifeannuitywithbond'}
        for t = times
            if t.age >= self.Income.retirementAge
                C(:, t) = state.W(:, t) + state.L(:, t) - sum(deNormPolicy(:, t, :), 3);
            else
                C(:, t) = state.W(:, t) - sum(deNormPolicy(:, t, :), 3);
            end
        end
end

end
