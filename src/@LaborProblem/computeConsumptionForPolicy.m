function C = computeConsumptionForPolicy(~, state, ~, ~, policy)

% C is also normalized
C = state(:, 1) - sum(policy, 2);
