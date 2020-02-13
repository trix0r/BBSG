function error = getEnvelopeEulerErrors(self, state, discreteState, t, solution, interpPolicy)

%% Assumptions
% There are only two policies, normS and normB, and shocks(:, 1) are the stock returns
policy = zeros(1, self.numberOfPolicies);
for s = 1:self.numberOfPolicies
    policyName = self.policyNames{s};
    policy(s)  = interpPolicy(t).(discreteState).(policyName).evaluate(state);
end
C = self.computeConsumptionForPolicy(state, discreteState, t, policy);

% if constraint is binding, only checks for inequality constraints so far
% check only for first two policies, i.e., stocks and bonds
binding = checkBindingConstraints(self, state, discreteState, t, policy);
binding = binding(1:2);
if all(binding); error = NaN(1, 2); return; end

% get index of discrete state
g = self.riskAversion;
p = self.elasticityOfIntertemporalSubstitution;
df = self.discountFactor^(self.Time.ageStep);
ds = strcmp(self.discreteStateNames, discreteState);

%% calculation of the expectation
[shocks, probability] = self.computeShockDistribution(state, discreteState, t);

consumptionExpectation = zeros(1, 2);
valueFunctionExpectation = zeros(1, 2);
for q = 1:self.numberOfDiscreteStates
    discreteStateName = self.discreteStateNames{q};
    newState = self.computeStateTransition(state, discreteStateName, t, policy, shocks);
    transitionProbability = self.transitionMatrix(t, ds, q);
    J = solution(t + 1).interpOptJ.(discreteStateName).evaluate(newState);
    newPolicy = zeros(size(newState, 1), self.numberOfPolicies);
    for s = 1:self.numberOfPolicies
        policyName = self.policyNames{s};
        newPolicy(:, s) = interpPolicy(t + 1).(discreteState).(policyName).evaluate(newState);
    end
    newC = self.computeConsumptionForPolicy(newState, discreteStateName, t + 1, newPolicy);
    newC = self.computeNewConsumptionForPolicy(newC, state, discreteStateName, t, policy, shocks);
    valueFct = self.computeValueFunctionForPolicy(J, state, discreteStateName, t, policy, shocks);

    %% calculation of expectation
    e = transitionProbability * probability.(discreteStateName)' * valueFct.^g;
    ce(1) = transitionProbability * probability.(discreteStateName)' * ...
            (valueFct.^(g - p) .* newC.^(p - 1) .* shocks(:, 1));
    ce(2) = transitionProbability * probability.(discreteStateName)' * ...
            (valueFct.^(g - p) .* newC.^(p - 1) * self.Return.factor);

    valueFunctionExpectation = valueFunctionExpectation + e;
    consumptionExpectation = consumptionExpectation + ce;
end

error = (df * C^(1 - p) * valueFunctionExpectation.^(p / g - 1) .* ...
        consumptionExpectation).^(1 / (p - 1)) - 1;
error(binding) = NaN;

end

function binding = checkBindingConstraints(self, state, discreteState, t, policy)

tc = self.Optimizer.tolCon;
[A, b, ~, ~, lb, ub, ~] = self.getConstraints(state, discreteState, t);
binding = abs(A * policy' - b) < tc | abs(policy - lb) < tc | abs(policy - ub) < tc;

end