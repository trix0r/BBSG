function lambda = computeTerminalLambda(self, state, ~)

k = size(state, 1);
lambda = repmat(conStruct({'isActive', 'multiplier'}), k, 1);

for j = 1:k
    lambda(j).isActive   = zeros(self.numberOfPolicies, 1);
    lambda(j).multiplier = zeros(self.numberOfPolicies, 1);
end
