function [holdings, fractions] = computeAssetAllocation(self, state, policy)

%% Compute non-normalized policies
[deNormPolicy, deNormPolicyNames] = self.getDeNormPolicies(policy);

%% Compute holdings and fractions
times = self.Time.getRange();
numberOfPaths = size(deNormPolicy, 1);

holdings = zeros(numberOfPaths, numel(times), numel(deNormPolicyNames));
if isfield(state, 'L')
    annuityPrices = zeros(numberOfPaths, numel(times));
    for t = times
        if t.age >= self.Income.retirementAge
            % buy immediate annuity
            annuityPrices(:, t) = self.computeAnnuityFactor(t.age, state.R(:, t), 0);
        else
            annuityPrices(:, t) = self.computeAnnuityFactor(t.age, state.R(:, t), ...
                                                            self.Income.retirementAge - ...
                                                            t.age - self.Time.ageStep);
        end
    end
    holdings(:, :, 1:end - 1) = deNormPolicy(:, :, 1:end - 1);
    holdings(:, :, end) = state.L(:, [times.index] + 1) .* annuityPrices;
else
    holdings = deNormPolicy;
end
fractions = holdings ./ sum(holdings, 3);

end
