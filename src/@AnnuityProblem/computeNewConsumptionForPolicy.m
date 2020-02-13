function newC = computeNewConsumptionForPolicy(self, C, ~, ~, t, ~, shocks)

if t.age >= self.Income.retirementAge
    permShock = ones(size(shocks(:, self.numberOfShocks - 1)));
else
    permShock = shocks(:, self.numberOfShocks - 1);
end

newC = C .* permShock;

end
