function errors = computeSimulationEulerErrors(self, solution, interpPolicy, state, ...
                                               discreteState, times)

if nargin < 6
    times = self.Time.getRange();
    times = times(1:end-1);
end

emptyError = conStruct({'All', 'L1', 'L2', 'Max'});
errors = repmat(emptyError, numel(self.Time.getRange()) - 1, 1);

if isfield(self.EulerError, 'names')
    noOfErrs = numel(self.EulerError(1).names);
else
    noOfErrs = self.numberOfPolicies;
end

numberOfPaths = size(discreteState, 1);
parfor r = 1:numel(times)
    t = times(r);
    err = nan(numberOfPaths, noOfErrs); %#ok<*PFBNS>
    % determine state vector at time t
    for k = 1:self.numberOfDiscreteStates
        discreteStateName = self.discreteStateNames{k};
        % for all paths in this discrete state
        idx = discreteState(:, t) == k;
        noPathInState = sum(idx);
        if noPathInState ~= 0 % if at least one path is in this state
            s = zeros(noPathInState, self.numberOfStates);
            for q = 1:self.numberOfStates
                stateName = self.stateNames{q};
                s(:, q) = state.(stateName)(idx, t);
            end
            for i = 1:size(idx, 1)
                err(i, :) = self.getEulerErrors(s(i, :), discreteStateName, t, solution, ...
                                                interpPolicy);
            end
        end
    end
    errors(r).All = err;
    % l1 error
    errors(r).L1 = nanmean(abs(err));
    % l2 error
    errors(r).L2 = sqrt(nanmean(err.^2));
    % max error
    errors(r).Max = nanmax(abs(err));
end

end
