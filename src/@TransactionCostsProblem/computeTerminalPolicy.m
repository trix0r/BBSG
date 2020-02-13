function policy = computeTerminalPolicy(self, state, ~)

x = state;

% for all buys
for p = 1 : self.numberOfStocks
    policyName          = self.policyNames{p};
    policy.(policyName) = zeros(size(state, 1), 1);
end

% for all sells
for p = self.numberOfStocks + 1 : 2 * self.numberOfStocks
    policyName          = self.policyNames{p};
    policy.(policyName) = x(:, p - self.numberOfStocks);
end

policy.normNormB = zeros(size(state, 1), 1);

% create struct array from structure of arrays
policy = struct2struct(policy);
