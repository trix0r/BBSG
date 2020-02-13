function x0 = getOptimizationStartPolicy(self, state, discreteState, t)

normW = state(1);

switch lower(self.modelVariant)
    case 'debug'
        x0 = normW * ones(1, (self.numberOfPolicies)) ./ (self.numberOfPolicies + 1);
    case {'noannuitywithbond', 'debugonlybond'}
        x0 = normW * ones(1, (self.numberOfPolicies)) ./ (self.numberOfPolicies + 1);
    case {'termcertainannuitynobond', 'lifeannuitynobond', 'lifeannuitywithbond', 'debugannuity'}
        normL = state(2);
        if t > self.Income.retirementAge - self.Time.ageStart - self.Time.ageStep
            x0 = [(normW + normL) * ones(1, (self.numberOfPolicies - 1)) ./ ...
                  self.numberOfPolicies, ...
                  0];
        else
            x0 = normW * ones(1, (self.numberOfPolicies)) ./ (self.numberOfPolicies + 1);
        end
end

if (self.Optimizer.noOfMultiStartPoints(state, discreteState, t) > 1)
    x0 = [x0; createFeasiblePoints(self, state, discreteState, t)];
end

end

function points = createFeasiblePoints(self, state, discreteState, t)

n = round(self.Optimizer.noOfMultiStartPoints(state, discreteState, t)^(1/(self.numberOfPolicies)));

lb = zeros(1, self.numberOfPolicies);
if t > self.Income.retirementAge - self.Time.ageStart - self.Time.ageStep
    ub = ones(1, self.numberOfPolicies) * sum(state(1 : end - 1));
else
    ub = ones(1, self.numberOfPolicies) * state(1);
end
x = lb' * ones(1, n) + (ub - lb)' * linspace(0, 1, n);
points = makeGrid(x);

% generate only feasible points
C = self.computeConsumptionForPolicy(state, discreteState, t, points);
[A, b, ~, ~,  lb, ub, ~] = self.getConstraints(state, discreteState, t);
idx = C >= self.minConsumption & ...
      points * A'  <= b & ...
      all(bsxfun(@ge, points, lb), 2) & ...
      all(bsxfun(@le, points, ub), 2);
points = points(idx, :);

end
