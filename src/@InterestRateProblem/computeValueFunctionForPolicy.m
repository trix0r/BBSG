function valueFunction = computeValueFunctionForPolicy(self, interpJ, ~, ~, t, ~, shocks)

if self.enableIncome
    [newLogNormP, ~] = self.computeIncomeTransition(t, shocks);
else
    newLogNormP = 0;
end

valueFunction = interpJ .* exp(newLogNormP);
