function [Info, J, gradientJ] = getJ(self, previousSolution, policy, ...
                                    state, discreteState, t)

x = state;
                                
calculateGradients = (nargout > 2);
if calculateGradients
    if (1 - sum(x)) < self.minConsumption && ...
       ~self.allowBorrowing % if unattainable state
        J = NaN;
        gradientJ = NaN;
        Info = [];
    else
        [Info, J, gradientJ] = ...
            self.getEpsteinZinUtility(previousSolution, policy, ...
            state, discreteState, t);
    end
else
    if (1 - sum(x)) < self.minConsumption && ...
       ~self.allowBorrowing % if unattainable state
        Info = [];
        J = NaN;
    else
        [Info, J] = self.getEpsteinZinUtility(previousSolution, policy, ...
            state, discreteState, t);
    end
end

end
