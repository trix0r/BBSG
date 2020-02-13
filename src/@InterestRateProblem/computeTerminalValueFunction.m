function [interpJ, interpGradJ] = computeTerminalValueFunction(self, state, ~)

% certainty equivalent, all the wealth is consumed
interpJ = sum(state(:, 1 : end - 1), 2);
for q = 1 : self.numberOfGradientStates
    gradientStateName = self.gradientStateNames{q};
    interpGradJ.(gradientStateName) = ones(size(state, 1), 1);
end

% create struct array from structure of arrays
if self.numberOfGradientStates > 0
    interpGradJ = struct2struct(interpGradJ);
end
