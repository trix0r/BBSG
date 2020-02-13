function gradient = computeGradientForConsumption(self, ~, ~, ~, ~)

gradient = zeros(1, self.numberOfPolicies);
for p = 1 : self.numberOfStocks
    gradient(:, p)                       = -1 * (1 + self.linearTransactionCosts);
    gradient(:, self.numberOfStocks + p) = -1 * (self.linearTransactionCosts - 1);
end
gradient(end) = -1;

end
