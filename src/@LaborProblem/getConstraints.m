function [A, b, Aeq, beq, lb, ub, nonlcon] = getConstraints(self, state, ~, ~)

normW = state(1);

A = ones(1, self.numberOfPolicies);
b = normW - self.minConsumption;
lb = zeros(1, self.numberOfPolicies);
ub = Inf * ones(1, self.numberOfPolicies);
Aeq = [];
beq = [];
nonlcon = [];
