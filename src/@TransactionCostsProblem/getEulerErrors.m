function error = getEulerErrors(self, state, discreteState, t, solution, interpPolicy)

err = self.getEulerErrors@LifecycleProblem(state, discreteState, t, solution, interpPolicy);

error = NaN(1, numel(self.EulerError(1).names));
idx = ismember(self.EulerError(t).points, state, 'rows');
error(:, 1) = err(:, end);
% if we have a weight for this point
if sum(idx, 1) > 0; error(:, 2) = error(:, 1) .* self.EulerError(t).weights(idx); end
% if we evaluate simulated states the probability to hit any self.EulerError(t).points is 0

end
