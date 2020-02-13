function [interpJ, interpGradJ] = computeTerminalValueFunction(self, state, ~)

interpJ = sum(state, 2);
for q = 1 : self.numberOfGradientStates
    gradientStateName = self.gradientStateNames{q};
    interpGradJ.(gradientStateName) = ones(self.numberOfStates, 1);
end

% create struct array from structure of arrays
if self.numberOfGradientStates > 0
    interpGradJ = struct2struct(interpGradJ);
end
