function valueFunction = computeValueFunctionForPolicy(...
                                    self, interpJ, state, ...
                                    discreteState, t, policy, shocks)

if self.enableIncome
    if t.age >= self.Income.retirementAge
        permShock = ones(size(shocks(:, self.numberOfShocks - 1)));
    else
        permShock = shocks(:, self.numberOfShocks - 1);
    end
else
    permShock = 1;
end

normValueFunction = interpJ .* permShock;

newNormW = self.computeNormalizedWealth(state, discreteState, t, policy, shocks);
valueFunction = newNormW .* normValueFunction;
