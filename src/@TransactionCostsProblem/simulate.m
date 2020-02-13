function [state, discreteState, policy, shock] = simulate(self, interpPolicy)

numberOfPaths = 100000;
for s = 1 : self.numberOfStates
    stateName = self.stateNames{s};
    startPaths.(stateName) = 0 * ones(numberOfPaths, 1);
end
startPaths.DiscreteState = ones(numberOfPaths, 1); % index of self.discreteStateNames (1 = alive, 2 = dead)
[state, discreteState, policy, shock] = ...
   self.simulate@LifecycleProblem(interpPolicy, startPaths, numberOfPaths);

times = self.Time.getRange();
state.normW = zeros(numberOfPaths, numel(times) + 1);

if self.enableIncome
    state.normW(:,1) = self.Income.Permanent.G(self.Time.ageStart - 1);
else
    state.normW(:,1) = 1;
end

for t = times
    % determine state vector at time t - 1
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

            p = zeros(noPathInState, self.numberOfStates);
            for q = 1:self.numberOfPolicies
                policyName = self.policyNames{q};
                p(:, q) = policy.(policyName)(idx, t);
            end

            normNormW = self.computeNormalizedWealth( ...
                    s, discreteStateName, t, p, squeeze(shock(idx, t, :)));
            state.normW(idx, t + 1) = normNormW .* state.normW(idx, t);
        end
    end
end
