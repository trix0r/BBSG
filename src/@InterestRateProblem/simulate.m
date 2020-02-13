function [state, discreteState, policy, shock] = simulate(self, interpPolicy)

hasAnnuity = any(strcmp(self.stateNames, 'normL'));

numberOfPaths = 10000;

%% start paths of continuous states
for s = 1 : self.numberOfStates
    stateName = self.stateNames{s};
    startPaths.(stateName) = zeros(numberOfPaths, 1);
end
% initial normalized wealth and annuity holdings
% initial wealth is exp(logY); assumes logP = 0, see below
startPaths.normW(:, 1) = exp(self.Income.Permanent.logG(self.Time.ageStart - 1));
if hasAnnuity; startPaths.normL(:, 1) = zeros(numberOfPaths, 1); end % for clarity only
% initial short rate equals long term mean
startPaths.R = self.Interest.theta * ones(numberOfPaths, 1);

%% start paths of discrete state
startPaths.DiscreteState = ones(numberOfPaths, 1); % index of self.discreteStateNames (1 = alive)

%% perform simulation
[state, discreteState, policy, shock] = ...
   self.simulate@LifecycleProblem(interpPolicy, startPaths, numberOfPaths);

%% Compute de-normalized states and policies from simulation
times = self.Time.getRange();

% intial log permanent income, log income and de-normalized states
state.logP = zeros(numberOfPaths, numel(times) + 1);
state.logP(:, 1) = 0;
state.logY = zeros(numberOfPaths, numel(times) + 1);
state.logY(:, 1) = self.Income.Permanent.logG(self.Time.ageStart - 1);
state.W = zeros(numberOfPaths, numel(times) + 1);
state.W(:, 1) = exp(state.logY(:, 1));
if hasAnnuity; state.L = zeros(numberOfPaths, numel(times) + 1); state.L(:, 1) = 0; end

% de-normalized policies
deNormPolicyNames = strrep(self.policyNames, 'norm', '');
for p = 1:numel(deNormPolicyNames)
    deNormPolicyName = deNormPolicyNames{p};
    policy.(deNormPolicyName) = zeros(numberOfPaths, numel(times));
end

for t = times
    % determine state vector
    [newLogNormP, newLogNormY] = self.computeIncomeTransition(t, squeeze(shock(:, t, :)));
    state.logP(:, t + 1) = state.logP(:, t) + newLogNormP;
    state.logY(:, t + 1) = state.logP(:, t + 1) + newLogNormY;
    state.W(:, t + 1) = exp(state.logP(:, t + 1)) .* state.normW(:, t + 1);
    if hasAnnuity; state.L(:, t + 1) = exp(state.logP(:, t + 1)) .* state.normL(:, t + 1); end
    % determine policy vector
    for p = 1:self.numberOfPolicies
        deNormPolicyName = deNormPolicyNames{p};
        policyName = self.policyNames{p};
        policy.(deNormPolicyName)(:, t) = policy.(policyName)(:, t) .* exp(state.logP(:, t));
    end
end
