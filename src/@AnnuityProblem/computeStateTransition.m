function newState = computeStateTransition(self, state, ~, t, policy, shock)

normS = policy(:, 1);
normB = policy(:, 2);
normA = policy(:, 3);

af = self.computeAnnuityFactor(t.age, 0);

[newNormP, newNormY] = self.computeIncomeTransition(t, shock);

newState(:, 1) = (normS .* shock(:, 1)  + normB * self.Return.factor) ./ newNormP + newNormY;
newState(:, 2) = (state(:, 2) + normA / af) ./ newNormP;

end
