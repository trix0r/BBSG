function [points, weights] = constructErrorPoints(self)

% generate random points from [0,1]^d
lb = self.Grid.lowerBounds(:)';
ub = self.Grid.upperBounds(:)';

rng(342);
n = factorial(self.numberOfStates) * 1000;
d = self.numberOfStates;
points = repmat(lb, n, 1) + repmat(ub - lb, n, 1) .* rand(n, d);

% determine which error points constitute an eligible state
eligibleState = self.cropToEligibleState(points);

% select only the values that have not been cropped
eligible = ismembertol(points, eligibleState, 'byRows', true);
points = points(eligible,:);

% compute error weights that allow for correcting the impact of the cropping at the boundary,
% weights are the (normalized w/ respect to the origin) distance from points to boundary 
% sum(points, 2) == 1
weights = (1 - sum(points, 2));

end
