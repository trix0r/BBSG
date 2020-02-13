function gradient = computeGradientForPolicy(self, ~, gradientJ, ~, ~, t, ~, shocks)

af = self.computeAnnuityFactor(t.age, 0);

gradient = zeros(size(gradientJ, 1), self.numberOfPolicies);
gradient(:, 1) = gradientJ(:, 1) .* shocks(:, 1);
gradient(:, 2) = gradientJ(:, 1) * self.Return.factor;
gradient(:, 3) = gradientJ(:, 2) / af;
