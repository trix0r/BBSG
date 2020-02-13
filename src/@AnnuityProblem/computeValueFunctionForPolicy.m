function valueFunction = computeValueFunctionForPolicy(self, interpJ, ~, ~, t, ~, shocks)

if t.age >= self.Income.retirementAge
    permShock = ones(size(shocks(:, self.numberOfShocks - 1)));
else
    permShock = shocks(:, self.numberOfShocks - 1);
end

valueFunction = interpJ .* permShock;
