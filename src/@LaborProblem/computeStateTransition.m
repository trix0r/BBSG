function newState = computeStateTransition(self, ~, ~, t, policy, shock)

normS = policy(:, 1);
normB = policy(:, 2);

[newNormP, newNormY] = self.computeIncomeTransition(t, shock);

newState = (normS .* shock(:, 1)  + normB * self.Return.factor) ./ newNormP + newNormY;

end
