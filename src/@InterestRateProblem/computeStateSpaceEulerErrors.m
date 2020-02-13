function errors = computeStateSpaceEulerErrors(self, solution, interpPolicy, times)

% Update hashmap for Euler error pts. This is not done in constructErrorPoints as the resulting
% hashmap is unecessarily large in the optimization and all other parts. Also, the added hashmap
% entries fot the error are most likely not any refined points
% ASSUMPTION: All error pts are the same at all times (this is so, see constructErrorPoints)
self.updateQuadratureMaps(self.EulerError(end).points(:, end));

if ~exist('times', 'var')
    errors = self.computeStateSpaceEulerErrors@LifecycleProblem(solution, interpPolicy);
else
    errors = self.computeStateSpaceEulerErrors@LifecycleProblem(solution, interpPolicy, times);
end

end
