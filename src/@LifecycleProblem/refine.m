function [previousSolution, noStartPoints, noRefines, noInsertedPoints, noEndPoints, ...
          noPreviousPoints, noAddedPoints, noRemovedPoints, Info] = ...
    refine(self, previousSolution, previousPreviousSolution, discreteState, t)

Info.Time.optimizer   = 0;
Info.Time.COP         = 0;
Info.Calls.J          = 0;
Info.Calls.gradJ      = 0;
Info.Calls.Evaluate.J = 0;
Info.Calls.Evaluate.gradJ = 0;

toleranceFlag.J = true;
for q = 1 : self.numberOfGradientStates
    gradientStateName = self.gradientStateNames{q};
    toleranceFlag.(gradientStateName) = true;
end
i = 0;

noStartPoints    = nan(1, 2+self.numberOfGradientStates);
noRefines        = noStartPoints;
noInsertedPoints = noStartPoints;
noEndPoints      = noStartPoints;
noPreviousPoints = noStartPoints;
noAddedPoints    = noStartPoints;
noRemovedPoints  = noStartPoints;

% used to determine total number of added grid points as well as inserted points
tmpGridPoints.previousSolution = ...
                               previousSolution.gridPoints.(discreteState);
tmpGridPoints.additionalPoints = zeros(0, self.numberOfStates);

% refine value function -- reset grid before refinement
if self.Grid.J.(discreteState).resetGridOnRefine && ...
   self.Grid.J.(discreteState).resetTimes(t.age)

    tmpGridPoints.interpJ = ...
        previousSolution.interpJ.(discreteState).gridPoints;
    previousSolution.interpJ.(discreteState) = self.Grid.J.(discreteState).base.copy();
    previousSolution.interpJ.(discreteState).fit(...
        resortValuesToPoints(previousSolution.interpJ.(discreteState).gridPoints, ...
                                  previousSolution.gridPoints.(discreteState), ...
                                  previousSolution.J.(discreteState)));
    noPreviousPoints(2) = size(tmpGridPoints.interpJ, 1);
end

noPreviousPoints(1) = size(tmpGridPoints.previousSolution, 1);
noStartPoints(2)    = size(previousSolution.interpJ.(discreteState).gridPoints, 1);
noRefines(2)        = 0;
noInsertedPoints(2) = 0;

while true
    if toleranceFlag.J && ...
       i < self.Grid.J.(discreteState).maxRefine && ...
       self.Grid.J.(discreteState).refineTimes(t.age)

        toleranceFlag.J   = false;
        additionalPointsJ = previousSolution.interpJ.(discreteState).refine(...
                                'points', self.Grid.J.(discreteState).refineType, ...
                                size(previousSolution.interpJ.(discreteState).gridPoints, 1), ...
                                self.Grid.J.(discreteState).refineTolerance, ...
                                self.Basis.enableUP, self.Basis.BsplineDegree...
                                );
        if size(additionalPointsJ, 1) > 0
            toleranceFlag.J    = true;
        end
        i = i + 1;
        noInsertedPoints(2) = noInsertedPoints(2) + size(additionalPointsJ, 1);
    else
        additionalPointsJ = [];
    end
    
    % get the optimal function value at all newly added grid points
    if ~isempty(additionalPointsJ)
        [previousSolution, Info] = update( ...
            self, previousSolution, previousPreviousSolution, t, discreteState, ...
            additionalPointsJ, [], Info);
        noRefines(2) = noRefines(2) + 1;
        tmpGridPoints.additionalPoints = union(tmpGridPoints.additionalPoints, ...
                                               additionalPointsJ, 'rows');
    else
        break;
    end  
end

noEndPoints(2) = size(previousSolution.interpJ.(discreteState).gridPoints, 1);

% refine gradients -- reset grid before refinement
for q = 1:self.numberOfGradientStates
    gradientStateName = self.gradientStateNames{q};
    i = 0;

    if self.Grid.gradJ.(discreteState).(gradientStateName).resetGridOnRefine && ...
       self.Grid.gradJ.(discreteState).(gradientStateName).resetTimes(t.age)

       tmpGridPoints.interpGradJ.(gradientStateName) = ...
           previousSolution.interpGradJ.(discreteState).(gradientStateName).gridPoints;     
       previousSolution.interpGradJ.(discreteState).(gradientStateName) = ...
           self.Grid.gradJ.(discreteState).(gradientStateName).base.copy();
       previousSolution.interpGradJ.(discreteState).(gradientStateName).fit(...
           resortValuesToPoints(...
           previousSolution.interpGradJ.(discreteState).(gradientStateName).gridPoints, ...
           previousSolution.gridPoints.(discreteState), ...
           [previousSolution.gradJ.(discreteState).(gradientStateName)]'));
       noPreviousPoints(2+q) = size( ...
           tmpGridPoints.interpGradJ.(gradientStateName), 1);
    end

    noStartPoints(q+2)    = size( ...
        previousSolution.interpGradJ.(discreteState).(gradientStateName).gridPoints, 1);
    noRefines(2+q)        = 0;
    noInsertedPoints(2+q) = 0;

    while true
        if toleranceFlag.(gradientStateName) && ...
           i < self.Grid.gradJ.(discreteState).(gradientStateName).maxRefine && ...
           self.Grid.gradJ.(discreteState).(gradientStateName).refineTimes(t.age)
            toleranceFlag.(gradientStateName) = false;
            additionalPointsGradJ.(gradientStateName) = ...
                previousSolution.interpGradJ.(discreteState).(gradientStateName).refine( ...
                'points', self.Grid.gradJ.(discreteState).(gradientStateName).refineType, ...
                size(previousSolution.interpGradJ.(discreteState).(gradientStateName).gridPoints, 1), ...
                self.Grid.gradJ.(discreteState).(gradientStateName).refineTolerance, ...
                self.Basis.enableUP, self.Basis.BsplineDegree ...
                );
            if size(additionalPointsGradJ.(gradientStateName), 1) > 0
                toleranceFlag.(gradientStateName) = true;
            end
            i = i + 1;
            noInsertedPoints(2+q) = noInsertedPoints(2+q) + ...
                size(additionalPointsGradJ.(gradientStateName), 1);
        else
            additionalPointsGradJ.(gradientStateName) = [];
        end
        
        % get the optimal function value at all newly added grid points
        if ~isempty(additionalPointsGradJ.(gradientStateName))
            [previousSolution, Info] = update( ...
                self, previousSolution, previousPreviousSolution, t, discreteState, ...
                additionalPointsGradJ.(gradientStateName), gradientStateName, Info);
            noRefines(2+q) = noRefines(2+q) + 1;
            tmpGridPoints.additionalPoints = union(tmpGridPoints.additionalPoints, ...
                                      additionalPointsGradJ.(gradientStateName), 'rows');
        else
            break;
        end               
    end

    noEndPoints(2+q) = size( ...
        previousSolution.interpGradJ.(discreteState).(gradientStateName).gridPoints, 1);
end

% compute all added and removed points
if self.Grid.J.(discreteState).resetGridOnRefine && ...
   self.Grid.J.(discreteState).resetTimes(t.age)
    noAddedPoints(2) = ...
        size(setdiff(previousSolution.interpJ.(discreteState).gridPoints, ...
        tmpGridPoints.interpJ, 'rows'), 1);
    noRemovedPoints(2) = ...
        size(setdiff(tmpGridPoints.interpJ, ...
        previousSolution.interpJ.(discreteState).gridPoints, ...
        'rows'), 1);
end
for q = 1:self.numberOfGradientStates
    gradientStateName = self.gradientStateNames{q};
    if self.Grid.gradJ.(discreteState).(gradientStateName).resetGridOnRefine && ...
       self.Grid.gradJ.(discreteState).(gradientStateName).resetTimes(t.age)
        noAddedPoints(2+q) = size(setdiff( ...
            previousSolution.interpGradJ.(discreteState).(gradientStateName).gridPoints, ...
            tmpGridPoints.interpGradJ.(gradientStateName), 'rows'), 1);
        noRemovedPoints(2+q) = size(setdiff( ...
            tmpGridPoints.interpGradJ.(gradientStateName), ...
            previousSolution.interpGradJ.(discreteState).(gradientStateName).gridPoints, ...
            'rows'), 1);
    end
end

% compute number of overall start points
if ~t.getNext().isStop()
    noStartPoints(1) = size( ...
        previousPreviousSolution.gridPoints.(discreteState), 1);
end

% compute number of overall refines
noRefines(1) = max(noRefines(2:end));

% compute number of overall inserted points
noInsertedPoints(1) = size(tmpGridPoints.additionalPoints, 1);

% compute number of overall end points
noEndPoints(1) = size(previousSolution.gridPoints.(discreteState), 1);

% compute number of overall added points
noAddedPoints(1) = ...
    size(setdiff(previousSolution.gridPoints.(discreteState), ...
                 tmpGridPoints.previousSolution, 'rows'), 1);

% compute number of overall removed points
noRemovedPoints(1) = size(setdiff(tmpGridPoints.previousSolution, ...
                                  previousSolution.gridPoints.(discreteState), 'rows'), 1);

end

function [previousSolution, Info] = update( ...
    self, previousSolution, previousPreviousSolution, t, discreteState, ...
    additionalPoints, gradientState, Info)

[previousSolution, InfoOptimize] = self.optimize(previousSolution, previousPreviousSolution, ...
                                   additionalPoints, discreteState, t + 1);
% Update timing
Info.Time.optimizer = Info.Time.optimizer + InfoOptimize.Time.optimizer;
Info.Time.COP = Info.Time.COP + InfoOptimize.Time.COP;
Info.Calls.J = Info.Calls.J + InfoOptimize.Calls.J;
Info.Calls.gradJ = Info.Calls.gradJ + InfoOptimize.Calls.gradJ;
Info.Calls.Evaluate.J = Info.Calls.Evaluate.J + InfoOptimize.Calls.Evaluate.J;
Info.Calls.Evaluate.gradJ = Info.Calls.Evaluate.gradJ + InfoOptimize.Calls.Evaluate.gradJ;

if ~isempty(gradientState)
    % update the gradient interpolant
    previousSolution.interpGradJ.(discreteState).(gradientState).fit(resortValuesToPoints( ...
        previousSolution.interpGradJ.(discreteState).(gradientState).gridPoints, ...
        previousSolution.gridPoints.(discreteState), ...
        [previousSolution.gradJ.(discreteState).(gradientState)]'));
end

end
