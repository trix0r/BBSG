function [A, b, Aeq, beq, lb, ub, nonlcon] = ...
    getConstraints(self, state, discreteState, ~)

x = state;

noBuys  = self.numberOfStocks;
noSells = self.numberOfStocks;

if strcmp('Dead', discreteState)
    b   = 0;
    lb  = zeros(self.numberOfPolicies, 1);
    ub  = zeros(self.numberOfPolicies, 1);
else
    b   = max((1 - sum(x)) - self.minConsumption, 0);
    if self.allowBorrowing
        lb = [zeros(1, self.numberOfPolicies - 1), ...
              -((self.numberOfStocks - 1) + self.minConsumption)];
    else
        lb = [zeros(1, self.numberOfPolicies - 1), eps^2];
    end
    ub  = [ones(1, noBuys) * Inf, ones(1, noSells) .* x , Inf];
end

tau     = self.linearTransactionCosts;
A       = [ones(1, noBuys) * (1 + tau), ones(1, noSells) * (tau - 1), 1];
Aeq     = [];
beq     = [];
nonlcon = [];
