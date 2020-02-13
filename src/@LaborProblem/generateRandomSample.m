function shocks = generateRandomSample(self, numberOfSamples, ~, ~, ~)

n  = numberOfSamples;
dt = self.Time.ageStep;

shocks = zeros(n, self.numberOfShocks);

shocks(:, 1) = exp(self.Return.m * dt + sqrt(self.Return.cov) * sqrt(dt) * randn(n, 1));
shocks(:, 2) = exp(self.Income.Permanent.m * dt + self.Income.Permanent.v * sqrt(dt) * randn(n, 1));
shocks(:, 3) = exp(self.Income.Transitory.m * dt + ...
                   self.Income.Transitory.v * sqrt(dt) * randn(n, 1));
end
