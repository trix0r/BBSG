function [currentSolution, Info] = ...
    optimize(self, currentSolution, previousSolution, state, discreteState, t)

% setdiff makes state automatically unique (and sorted)
state = setdiff(state, currentSolution.gridPoints.(discreteState), 'rows');
k = size(state, 1);

if t.isStop()
    tmpPolicy = self.computeTerminalPolicy(state, discreteState);
    if self.numberOfGradientStates > 0
        [tmpJ, tmpGradJ] = self.computeTerminalValueFunction(state, discreteState);
    else
        tmpJ             = self.computeTerminalValueFunction(state, discreteState);
    end
    tmpLambda = self.computeTerminalLambda(state, discreteState);
    tmpStatus = nan(size(state, 1), 1);
else
    tmpJ      = zeros(k, 1);
    tmpPolicy = repmat(conStruct(self.policyNames), k, 1);
    tmpLambda = repmat(conStruct({'isActive', 'multiplier'}), k, 1);

    if self.Optimizer.printTimes
        fprintf('%7s %3s %3s %3s %4s %7s %4s %7s\n', ...
                'COP', 'J%', 'gJ%', 'ot%', '#J', 'JAvg', '#gJ', 'gJAvg');
    end

    Infos = cell(k, 1);
    parfor i = 1 : k
        time_cop = tic();
        [tmpJ(i), tmpPolicy(i), tmpLambda(i), Infos{i}] = computeOptimalPolicy( ...
            self, previousSolution, state(i, :), discreteState, t);
        Infos{i}.Time.COP = toc(time_cop);
    end
    tmpStatus = cellfun(@(x) x.status, Infos);
end

currentSolution.gridPoints.(discreteState) = ...
    [currentSolution.gridPoints.(discreteState); state];
currentSolution.J.(discreteState)          = ...
    [currentSolution.J.(discreteState);          tmpJ];
currentSolution.policy.(discreteState)     = ...
    [currentSolution.policy.(discreteState);     tmpPolicy];
currentSolution.lambda.(discreteState)     = ...
    [currentSolution.lambda.(discreteState);     tmpLambda];
currentSolution.status.(discreteState)     = ...
    [currentSolution.status.(discreteState);     tmpStatus];

if isempty(currentSolution.interpJ.(discreteState))
    if t.isStop()
        currentSolution.interpJ.(discreteState) = self.Grid.J.(discreteState).base.copy();
    else
        currentSolution.interpJ.(discreteState) = previousSolution.interpJ.(discreteState).copy();
    end
end

currentSolution.interpJ.(discreteState).fit(resortValuesToPoints( ...
        currentSolution.interpJ.(discreteState).gridPoints, ...
        currentSolution.gridPoints.(discreteState), ...
        currentSolution.J.(discreteState)));

if self.numberOfGradientStates > 0
    if ~t.isStop()
        % determine gradient and optimized grid points
        tmpGradJ = repmat(conStruct(self.gradientStateNames), k, 1);
        interpOptJ = currentSolution.interpJ.(discreteState).copy( ...
            self.Basis.BsplineType, self.Basis.BsplineDegree);
        [~, gradient] = interpOptJ.evaluate(state);

        for q = 1:self.numberOfGradientStates
            gradientStateName = self.gradientStateNames{q};
            stateIdx = strcmp(self.stateNames, gradientStateName);

            for i = 1 : k
                tmpGradJ(i).(gradientStateName) = gradient(i, stateIdx);
            end
        end
    end

    currentSolution.gradJ.(discreteState) = ...
        [currentSolution.gradJ.(discreteState); tmpGradJ];
end

for q = 1:self.numberOfGradientStates
    gradientStateName = self.gradientStateNames{q};

    if isempty(currentSolution.interpGradJ.(discreteState).(gradientStateName))
        if t.isStop()
            currentSolution.interpGradJ.(discreteState).(gradientStateName) = ...
                self.Grid.gradJ.(discreteState).(gradientStateName).base.copy();
        else
            gradientStateName = self.gradientStateNames{q};
            currentSolution.interpGradJ.(discreteState).(gradientStateName) = ...
                previousSolution.interpGradJ.(discreteState).(gradientStateName).copy();
        end

        currentSolution.interpGradJ.(discreteState).(gradientStateName).fit(...
            resortValuesToPoints( ...
                currentSolution.interpGradJ.(discreteState).(gradientStateName).gridPoints, ...
                currentSolution.gridPoints.(discreteState), ...
                [currentSolution.gradJ.(discreteState).(gradientStateName)]'));
    end
end

%Info.Time.evaluate    = 0;
%Info.Time.getJ        = 0;
Info.Time.optimizer   = 0;
Info.Time.COP         = 0;
Info.Calls.J          = 0;
Info.Calls.gradJ      = 0;
Info.Calls.Evaluate.J = 0;
Info.Calls.Evaluate.gradJ = 0;
if ~t.isStop()
    for i = 1 : k
        %Info.Time.evaluate = Info.Time.evaluate + Infos{i}.Time.evaluate;
        %Info.Time.getJ = Info.Time.getJ + Infos{i}.Time.getJ;
        Info.Time.optimizer = Info.Time.optimizer + Infos{i}.Time.optimizer;
        Info.Time.COP = Info.Time.COP + Infos{i}.Time.COP;
        Info.Calls.J = Info.Calls.J + Infos{i}.Calls.J;
        Info.Calls.gradJ = Info.Calls.gradJ + Infos{i}.Calls.gradJ;
        Info.Calls.Evaluate.J = Info.Calls.Evaluate.J + Infos{i}.Calls.Evaluate.J;
        Info.Calls.Evaluate.gradJ = Info.Calls.Evaluate.gradJ + Infos{i}.Calls.Evaluate.gradJ;
    end
end
