function lossAversion = computeLossAversion(self, ~, ~, ~, ~, shocks)

lossAversion = zeros(size(shocks, 1), self.numberOfStocks);
