function [currentSolution, Info] = ...
    optimize(self, currentSolution, previousSolution, state, discreteState, t)

% update hashmap if refinement has added new short rate grid points
self.updateQuadratureMaps(unique(state(:, end)));

[currentSolution, Info] = self.optimize@LifecycleProblem(currentSolution, previousSolution, ...
                                                         state, discreteState, t);
end
