function [A, b, Aeq, beq, lb, ub, nonlcon] = getConstraints(self, state, ~, ~)

normW = state(1);
normL = state(2);

A = ones(1, self.numberOfPolicies);
b = normW + normL - self.minConsumption;
lb = zeros(1, self.numberOfPolicies);
ub = Inf * ones(1, self.numberOfPolicies);
Aeq = [];
beq = [];
nonlcon = [];
