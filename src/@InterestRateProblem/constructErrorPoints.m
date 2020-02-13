function points = constructErrorPoints(self)

% generate random points from domain
lb = self.Grid.lowerBounds(:)';
ub = self.Grid.upperBounds(:)';

rng(342);
n = 1000;
d = self.numberOfStates;
points = repmat(lb, n, 1) + repmat(ub - lb, n, 1) .* rand(n, d);

end
