function [A, b, Aeq, beq, lb, ub, nonlcon] = getConstraints(self, state, ~, t)

normW = state(1);

switch lower(self.modelVariant)
    case 'debug'
        A = 1;
        b = normW - self.minConsumption;
        lb = 0;
        ub = Inf;
    case {'noannuitywithbond', 'debugonlybond'}
        A = ones(1, self.numberOfPolicies);
        b = normW - self.minConsumption;
        lb = zeros(1, self.numberOfPolicies);
        ub = Inf * ones(1, self.numberOfPolicies);
    case {'termcertainannuitynobond', 'lifeannuitynobond', 'lifeannuitywithbond', 'debugannuity'}
        normL = state(2);
        if t.age >= self.Income.retirementAge
            b = normW + normL - self.minConsumption;
        else
            b = normW - self.minConsumption;
        end
        if ismember(t.age, self.eligibleAnnuityPurchaseAges)
            A = ones(1, self.numberOfPolicies);
            ub = Inf * ones(1, self.numberOfPolicies);
        else
            A = [ones(1, self.numberOfPolicies - 1), 0];
            ub = [Inf * ones(1, self.numberOfPolicies - 1), 0];
        end
        lb = zeros(1,  self.numberOfPolicies);
end

Aeq = [];
beq = [];
nonlcon = [];
