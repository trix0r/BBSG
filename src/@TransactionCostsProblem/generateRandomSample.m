function shocks = generateRandomSample(self, numberOfSamples, ~, ~, ~)

n  = numberOfSamples;
dt = self.Time.ageStep;
p  = self.numberOfStocks;

shocks = zeros(n, self.numberOfShocks);

% Return
shocks(:, 1 : p) = exp(bsxfun(@plus, self.Return.m(1 : p) * dt,...
                   randn(n, p) * chol(self.Return.cov(1 : p, 1 : p), ...
                                         'lower') * sqrt(dt)));
if self.enableIncome
    shocks(:, end - 1) = exp(self.Income.Permanent.m * dt ...
                          + self.Income.Permanent.v * sqrt(dt) * randn(n, 1));
    shocks(:, end)     = exp(self.Income.Transitory.m * dt ...
                          + self.Income.Transitory.v * sqrt(dt) * randn(n, 1));
end
end
