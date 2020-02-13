function x0 = getOptimizationStartPolicy(self, state, discreteState, t)

x = state;

if ((1 - sum(x, 2)) > 2 * self.minConsumption)
    b = (1 - sum(x, 2)) / 2;
else
    b = 0;
end
x0 = [zeros(1, self.numberOfPolicies - 1), b];

if (self.Optimizer.noOfMultiStartPoints > 1)
    x0 = [x0; createFeasiblePoints(self, state, discreteState, t)];
end

end


function points = createFeasiblePoints(self, state, discreteState, t)

noBuys  = self.numberOfStocks;
noSells = self.numberOfStocks;

n = round(self.Optimizer.noOfMultiStartPoints^(1/self.numberOfPolicies));

if self.allowBorrowing
    lb = [zeros(1, self.numberOfStocks), ...
          -((self.numberOfStocks - 1) + self.minConsumption)];
else
    lb = zeros(1, self.numberOfPolicies);
end
ub = [ones(1, noBuys), ones(1, noSells) .* state, 1];
x = lb' * ones(1, n) + (ub - lb)' * linspace(0, 1, n);
points = makeGrid(x);
C = self.computeConsumptionForPolicy(state, discreteState, t, points);

% generate only feasible points
points(C < 2 * self.minConsumption) = nan;
idx = any(isnan(points), 2);
points = points(~idx,:);

end
