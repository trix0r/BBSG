function policy = computeTerminalPolicy(self, state, ~)

% all the wealth is consumed, so no nothing invested
for p = 1 : self.numberOfPolicies
    policyName          = self.policyNames{p};
    policy.(policyName) = zeros(size(state, 1), 1);
end

% create struct array from structure of arrays
policy = struct2struct(policy);
