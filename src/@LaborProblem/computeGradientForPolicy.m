function gradient = computeGradientForPolicy(self, ~, gradientJ, ~, ~, ~, ~, shocks)

gradient = zeros(size(gradientJ, 1), self.numberOfPolicies);
gradient(:, 1) = gradientJ(:, 1) .* shocks(:, 1);
gradient(:, 2) = gradientJ(:, 1) * self.Return.factor;
