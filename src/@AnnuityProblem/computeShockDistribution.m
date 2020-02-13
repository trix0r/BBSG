function [shocks, probability] = computeShockDistribution(self, ~, discreteState, ~)

shocks = self.Int.nodes;
probability.(discreteState) = self.Int.weights;
