function [state, discreteState, policy, shock] = simulate(self, interpPolicy)

numberOfPaths = 10000;

%% start paths of continuous states
for s = 1 : self.numberOfStates
    stateName = self.stateNames{s};
    startPaths.(stateName) = zeros(numberOfPaths, 1);
end
% initial normalized wealth and annuity holdings
% initial wealth is Y; assumes logP = 0, see below
startPaths.normW(:, 1) = self.Income.Permanent.G(self.Time.ageStart - 1);

%% start paths of discrete state
startPaths.DiscreteState = ones(numberOfPaths, 1); % index of self.discreteStateNames (1 = alive)

%% perform simulation
[state, discreteState, policy, shock] = ...
   self.simulate@LifecycleProblem(interpPolicy, startPaths, numberOfPaths);

%% Compute de-normalized states and policies from simulation
times = self.Time.getRange();

% intial log permanent income, log income and de-normalized states
state.P = zeros(numberOfPaths, numel(times) + 1);
state.P(:, 1) = 1;
state.Y = zeros(numberOfPaths, numel(times) + 1);
state.Y(:, 1) = self.Income.Permanent.G(self.Time.ageStart - 1);
state.W = zeros(numberOfPaths, numel(times) + 1);
state.W(:, 1) = state.Y(:, 1);
state.L = zeros(numberOfPaths, numel(times) + 1);
state.L(:, 1) = state.Y(:, 1);

% de-normalized policies
deNormPolicyNames = strrep(self.policyNames, 'norm', '');
for p = 1:numel(deNormPolicyNames)
    deNormPolicyName = deNormPolicyNames{p};
    policy.(deNormPolicyName) = zeros(numberOfPaths, numel(times));
end

for t = times
    % determine state vector
    [newNormP, newNormY] = self.computeIncomeTransition(t, squeeze(shock(:, t, :)));
    state.P(:, t + 1) = state.P(:, t) .* newNormP;
    state.Y(:, t + 1) = state.P(:, t + 1) .* newNormY;
    state.W(:, t + 1) = state.P(:, t + 1) .* state.normW(:, t + 1);
    state.L(:, t + 1) = state.P(:, t + 1) .* state.normL(:, t + 1);
    % determine policy vector
    for p = 1:self.numberOfPolicies
        deNormPolicyName = deNormPolicyNames{p};
        policyName = self.policyNames{p};
        policy.(deNormPolicyName)(:, t) = policy.(policyName)(:, t) .* state.P(:, t);
    end
end
