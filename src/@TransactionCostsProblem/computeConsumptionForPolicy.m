function C = computeConsumptionForPolicy(self, state, ~, ~, policy)

x = state;

% the first (n-1)/2 policies are buys
DeltaNormNormSBuy  = policy(:, 1 : self.numberOfStocks);
DeltaNormNormSSell = policy(:, ...
                        self.numberOfStocks + 1 : 2 * self.numberOfStocks);
normNormB  = policy(:, self.numberOfPolicies);

% C is also normalized
C = (1 - sum(x, 2)) - normNormB - ...
    (1 + self.linearTransactionCosts) * sum(DeltaNormNormSBuy, 2) - ...
    (self.linearTransactionCosts - 1) * sum(DeltaNormNormSSell, 2);
