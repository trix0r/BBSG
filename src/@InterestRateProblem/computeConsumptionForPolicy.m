function C = computeConsumptionForPolicy(self, state, ~, t, policy)

normW = state(:, 1);

% C is also normalized
switch lower(self.modelVariant)
    case 'debug'
        C = normW - sum(policy, 2);
    case {'noannuitywithbond', 'debugonlybond'}
        C = normW - sum(policy, 2);
    case {'termcertainannuitynobond', 'lifeannuitynobond', 'lifeannuitywithbond', 'debugannuity'}
        normL = state(:, 2);
        if t.age >= self.Income.retirementAge
            C = normW + normL - sum(policy, 2);
        else
            C = normW - sum(policy, 2);
        end
end
