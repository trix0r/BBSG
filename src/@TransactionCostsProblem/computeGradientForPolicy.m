function gradient = computeGradientForPolicy(self, J, gradientJ, state, ...
                                          discreteState, t, policy, shocks)

newState = self.computeStateTransition(state, discreteState, t, policy, shocks);

if self.enableIncome
    if t.age >= self.Income.retirementAge
        permShock = ones(size(shocks(:, self.numberOfShocks - 1)));
    else
        permShock = shocks(:, self.numberOfShocks - 1);
    end
else
    permShock = 1;
end

commonFactor = -sum(gradientJ .* newState, 2);

gradient = zeros(size(gradientJ, 1), self.numberOfPolicies);
for p = 1 : self.numberOfStocks
    derivBuy = permShock .* shocks(:, p) .* (J + gradientJ(:, p) + commonFactor);
    gradient(:, p)                       = derivBuy;
    gradient(:, self.numberOfStocks + p) = -derivBuy;
end
gradient(:, end) = permShock .* self.Return.factor * (J + commonFactor);
