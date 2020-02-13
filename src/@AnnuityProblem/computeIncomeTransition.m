function [newNormP, newNormY] = computeIncomeTransition(self, t, shocks)

eps = shocks(:, 2); % permanent shock
theta = shocks(:, 3); % transitory shock

if t.age >= self.Income.retirementAge
    newNormP = ones(size(eps));
    newNormY = self.Income.Permanent.G(self.Income.retirementAge) *  self.Income.replacement;
else
    newNormP = eps;
    newNormY = self.Income.Permanent.G(t.age) * theta;
end

end
