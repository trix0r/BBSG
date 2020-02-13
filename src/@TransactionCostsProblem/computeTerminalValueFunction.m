function [interpJ, interpGradJ] = ...
    computeTerminalValueFunction(self, state, discreteState)

x = state;

if strcmp(discreteState, 'Alive')
    interpJ = (1 - self.linearTransactionCosts * sum(x, 2));
    for q = 1 : self.numberOfGradientStates
        gradientStateName = self.gradientStateNames{q};
        interpGradJ.(gradientStateName) = ones(size(x, 1), 1) * ...
                                          -self.linearTransactionCosts;
    end
else % dead
    interpJ = zeros(size(x, 1), 1);
end

% create struct array from structure of arrays
if self.numberOfGradientStates > 0
    interpGradJ = struct2struct(interpGradJ);
end
