function [state, discreteState, policy, shock] = simulate(self, interpPolicy, startPaths, numberOfPaths)

% randon number stream
rs = RandStream.create('mt19937ar', 'seed', 123456);
RandStream.setGlobalStream(rs);

n  = numberOfPaths;
times = self.Time.getRange();

%% set intial values for policies and states
for q = 1:self.numberOfStates
    stateName = self.stateNames{q};
    state.(stateName) = [startPaths.(stateName) zeros(n, numel(times))];
end

% this should be encoded in terms of doubles (instead of strings), where the value corresponds
% with the index of the discrete state name self.discreteStateNames
discreteState = [startPaths.DiscreteState zeros(n, numel(times))];

for q = 1:self.numberOfPolicies
    policyName = self.policyNames{q};
    policy.(policyName) = zeros(n, numel(times));
end
% initialization of state vector in simulation
sNew  = zeros(n, self.numberOfStates);
shock = zeros(n, numel(times), self.numberOfShocks);

%% simulate over all times
timer = tic;
for t = times

    fprintf('Simulating age %i.\n', t.age);
    
    % determine state vector at time t
    for k = 1:self.numberOfDiscreteStates
        discreteStateName = self.discreteStateNames{k};
        % for all paths in this discrete state
        idx = discreteState(:, t) == k;
        noPathInState = sum(idx);
        if noPathInState ~= 0 % if at least one state is in this path
            s = zeros(noPathInState, self.numberOfStates);
            p = zeros(noPathInState, self.numberOfStates);
            for q = 1:self.numberOfStates
                stateName = self.stateNames{q};
                s(:, q) = state.(stateName)(idx, t);
            end
            
            % generate distriubtion of random shocks
            shock(idx, t, :) = self.generateRandomSample(noPathInState, s, discreteStateName, t);
            
            % optimal policies from optimization for t - 1 (interpolation for state vector)
            for q = 1:self.numberOfPolicies
                policyName = self.policyNames{q};
                policy.(policyName)(idx, t) = ...
                    interpPolicy(t).(discreteStateName).(policyName).evaluate(s);
                p(:, q) = policy.(policyName)(idx, t);
            end
            
            % evolution of state variables
            sNew(idx, :) = self.computeStateTransition( ...
                s, discreteStateName, t, p, squeeze(shock(idx, t, :)));
        end
    end    
   
    % compute state transtions
    if self.numberOfDiscreteStates > 1
        discreteState(:, t + 1) = mswitch(discreteState(:, t), ...
                                      squeeze(self.transitionMatrix(t, :, :)));
    else
        discreteState(:, t + 1) = discreteState(:, t);
    end
    
    for q = 1:self.numberOfStates
        stateName = self.stateNames{q};
        state.(stateName)(:, t + 1) = sNew(:, q);
    end
end

time = toc(timer);
fprintf('Calculation time was %0.2f seconds.\n', time);


