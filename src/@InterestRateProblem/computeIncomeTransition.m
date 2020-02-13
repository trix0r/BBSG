function [newLogNormP, newLogNormY] = computeIncomeTransition(self, t, shocks)

logEps = shocks(:, 2); % permanent shock
logTheta = shocks(:, 3); % transitory shock

if t.age >= self.Income.retirementAge
    newLogNormP = zeros(size(logEps));
    newLogNormY = self.Income.Permanent.logG(self.Income.retirementAge) + ...
                  self.Income.logReplacement;
else
    newLogNormP = logEps;
    newLogNormY = self.Income.Permanent.logG(t.age) + logTheta;
end

end
