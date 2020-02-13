function [shocks, probability] = computeShockDistribution(self, ~, ...
    discreteState, ~)

shocks      = self.Int.nodes;
if strcmpi(discreteState, 'Alive')
    probability.(discreteState) = self.Int.weights;
else
    probability.(discreteState) = zeros(size(self.Int.weights));
end
