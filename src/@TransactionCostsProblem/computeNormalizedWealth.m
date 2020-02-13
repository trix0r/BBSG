function [newNormW, newNormNormS] = computeNormalizedWealth(self, state, ~, t, policy, shock)

x = state;

% the first (n-1)/2 policies are buys
DeltaNormNormSBuy  = policy(:, 1 : self.numberOfStocks);
DeltaNormNormSSell = policy(:, (self.numberOfStocks) + 1 ...
                        : self.numberOfPolicies - 1);
normNormB = policy(:, self.numberOfPolicies);

% the pen-ultimate shock is the permanent income shock
% the last shock is the transitory income shock
if self.enableIncome
    if t.age >= self.Income.retirementAge
        permShock = ones(size(shock(:, self.numberOfShocks - 1)));
        Y = self.Income.Permanent.G(self.Income.retirementAge) * ...
            self.Income.replacement;
    else
        permShock = shock(:, self.numberOfShocks - 1);
        Y = self.Income.Permanent.G(t.age) * shock(:, self.numberOfShocks);
    end
    newNormNormS = bsxfun(@rdivide, ...
                          x + DeltaNormNormSBuy - DeltaNormNormSSell, ...
                          permShock) .* shock(:, 1 : self.numberOfShocks - 2);
else
    permShock = 1;
    Y = 0;
    newNormNormS = bsxfun(@times, ...
                          x + DeltaNormNormSBuy - DeltaNormNormSSell, ...
                          shock);
end

newNormW = sum(newNormNormS, 2) + (normNormB * self.Return.factor ./ permShock) + Y;
