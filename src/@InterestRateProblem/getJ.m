function [Info, J, gradientJ] = getJ(self, previousSolution, policy, ...
                                    state, discreteState, t)
                     
calculateGradients = (nargout > 2);
if calculateGradients
    [Info, J, gradientJ] = self.getEpsteinZinUtility(previousSolution, policy, ...
                                                     state, discreteState, t);
else
     [Info, J] = self.getEpsteinZinUtility(previousSolution, policy, state, discreteState, t);
end

end
