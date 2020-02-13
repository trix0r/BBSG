function error = getEulerErrors(self, state, discreteState, t, solution, interpPolicy)

policy = zeros(1, self.numberOfPolicies);
for s = 1:self.numberOfPolicies
    policyName = self.policyNames{s};
        policy(s)  = interpPolicy(t).(discreteState).(policyName).evaluate(state);
end
C = self.computeConsumptionForPolicy(state, discreteState, t, policy);

% if constraint is binding, only checks for inequality constraints so far
binding = checkBindingConstraints(self, state, discreteState, t, policy);
if all(binding); error = NaN(1, self.numberOfPolicies); return; end

% get index of discrete state
g = self.riskAversion;
p = self.elasticityOfIntertemporalSubstitution;
df = self.discountFactor^(self.Time.ageStep);
ds = strcmp(self.discreteStateNames, discreteState);

%% calculation of the expectation
[shocks, probability] = self.computeShockDistribution(state, discreteState, t);

gradientExpectation = zeros(1, self.numberOfPolicies);
valueFunctionExpectation = zeros(1, self.numberOfPolicies);
for q = 1:self.numberOfDiscreteStates
    discreteStateName = self.discreteStateNames{q};
    newState = self.computeStateTransition(state, discreteStateName, t, policy, shocks);
    transitionProbability = self.transitionMatrix(t, ds, q);
    [J, gradJ] = solution(t + 1).interpOptJ.(discreteStateName).evaluate(newState);
    valueFct = self.computeValueFunctionForPolicy(J, state, discreteStateName, t, policy, shocks);
    gradValueFct = self.computeGradientForPolicy(J, gradJ, state, discreteStateName, t, policy, ...
                                                shocks);
    %% calculation of expectation
    e = transitionProbability * probability.(discreteStateName)' * valueFct.^g;
    ge = transitionProbability * probability.(discreteStateName)' * ...
        (valueFct.^(g - 1) .* gradValueFct);

    valueFunctionExpectation = valueFunctionExpectation + e;
    gradientExpectation = gradientExpectation + ge;
end

error = (df * C^(1 - p) * valueFunctionExpectation.^(p / g - 1) .* gradientExpectation .* ...
         -1 ./ self.computeGradientForConsumption(state, discreteState, t, policy) ...
         ).^(1 / (p - 1)) - 1;
error(binding) = NaN;

end

function binding = checkBindingConstraints(self, state, discreteState, t, policy)

tc = self.Optimizer.tolCon;
[A, b, ~, ~, lb, ub, ~] = self.getConstraints(state, discreteState, t);
binding = abs(A * policy' - b) < tc | abs(policy - lb) < tc | abs(policy - ub) < tc;

end
