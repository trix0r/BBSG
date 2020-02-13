function [shocks, probability] = computeShockDistribution(self, state, discreteState, ~)

R = state(:, end); % short rate is always last dimension

vals = values(self.Int, {R});
nodesAndWeights = vals{:};

shocks = nodesAndWeights(:, 1:4);
probability.(discreteState) = nodesAndWeights(:, 5);

end
