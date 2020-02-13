function [interpPolicy, Info] = generatePolicyInterpolant(self, solution, Info)

headerNormal = sprintf('Age    Time\n');
formatNormal = sprintf('%%3u  %%5.2fs\n');

% output for refinement
fid = fopen([self.Env.outdir filesep 'policy_log.txt'], 'w');
headerRefine = sprintf('Type           ');
formatRefine = sprintf('%%-14s ');
headerOptimize = sprintf(sprintf('ID                 Code   State  %s\n', ...
                                 strtrim(repmat('%8s ', 1, self.numberOfStates))), ...
                         self.stateNames{:});
minimumHeaderWidth = 4;
for p = 1:self.numberOfPolicies
    policyName = self.policyNames{p};
    headerWidth = max(numel(policyName), minimumHeaderWidth);
    headerRefine = sprintf(sprintf('%%s %%%us', headerWidth), headerRefine, policyName);
    formatRefine = sprintf('%s %%%uu', formatRefine, headerWidth);
end
headerRefine = sprintf('%s\n', headerRefine);
formatRefine = sprintf('%s\n', formatRefine);

printToConsoleAndFile(fid, headerNormal);

times = self.Time.getRange();
if self.Env.resume
    loadVariables([self.Env.outdir filesep 'policies.mat'], 'solution', 'Info', 'interpPolicy');
    idx = cellfun(@isempty, {interpPolicy.(self.discreteStateNames{1})}); %#ok<NODEF>
    times = times(idx);
    % unset resume flag after resuming
    self.Env.resume = 0;
else
    % in case we only have the solution for some time steps
    fct = {solution.interpOptJ};
    idx = true(1, numel(times));
    for i = 1:numel(times)
        if  isempty(fct{i}) || ...
            isempty(fct{i}.(self.discreteStateNames{1}))
            idx(i) = false;
        else
            break;
        end
    end
    times = times(idx);
end

for t = fliplr(times)
    tic();
    for q = 1:self.numberOfDiscreteStates
        discreteStateName = self.discreteStateNames{q};
        if t.isStop()
            previousSolution = [];
        else
            previousSolution = solution(t + 1);
        end

        state = [];

        % construct policy interpolants
        for p = 1:self.numberOfPolicies
            policyName = self.policyNames{p};
            tmpInterpPolicy.(policyName) = ...
                self.Grid.Policy.(discreteStateName).(policyName).base.copy( ...
                    self.Grid.Policy.(discreteStateName).(policyName).Basis.type, ...
                    self.Grid.Policy.(discreteStateName).(policyName).Basis.degree);
            state = [state; tmpInterpPolicy.(policyName).gridPoints]; %#ok<AGROW>
        end

        fprintf(headerOptimize);

        % compute missing policies
        [solution(t), InfoOptimize] = self.optimize(solution(t), previousSolution, state, ...
                                                    discreteStateName, t);
        % Update timing
        Info.Time.optimizer = Info.Time.optimizer + InfoOptimize.Time.optimizer;
        Info.Time.COP = Info.Time.COP + InfoOptimize.Time.COP;
        Info.Calls.J = Info.Calls.J + InfoOptimize.Calls.J;
        Info.Calls.gradJ = Info.Calls.gradJ + InfoOptimize.Calls.gradJ;
        Info.Calls.Evaluate.J = Info.Calls.Evaluate.J + InfoOptimize.Calls.Evaluate.J;
        Info.Calls.Evaluate.gradJ = Info.Calls.Evaluate.gradJ + InfoOptimize.Calls.Evaluate.gradJ;

        % fit policies
        for p = 1:self.numberOfPolicies
            policyName = self.policyNames{p};
            tmpInterpPolicy.(policyName).fit(resortValuesToPoints(...
                tmpInterpPolicy.(policyName).gridPoints, ...
                solution(t).gridPoints.(discreteStateName), ...
                [solution(t).policy.(discreteStateName).(policyName)]'));
        end

        % refinement
        [tmpInterpPolicy, noStartPoints, noRefines, noInsertedPoints, noEndPoints, Info] = ...
            refinePolicy(self, tmpInterpPolicy, solution(t), previousSolution, ...
            discreteStateName, t, Info);
        interpPolicy(t).(discreteStateName) = tmpInterpPolicy; %#ok<AGROW>

        printToConsoleAndFile(fid, sprintf('\n')); %#ok<*SPRINTFN>
        printToConsoleAndFile(fid, sprintf('Discrete State: %s \n', discreteStateName));
        printToConsoleAndFile(fid, headerRefine);
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#Start pts.', noStartPoints));
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#Refines', noRefines));
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#Inserted pts.', noInsertedPoints));
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#End pts.', noEndPoints));
        printToConsoleAndFile(fid, sprintf('\n'));
    end

    time = toc();
    printToConsoleAndFile(fid, headerNormal);
    printToConsoleAndFile(fid, sprintf(formatNormal, t.age, time));
    save([self.Env.outdir filesep 'policies.mat'], 'self', 'solution', 'interpPolicy', 'Info');
end

fclose(fid);

end

function [tmpInterpPolicy, noStartPoints, noRefines, noInsertedPoints, noEndPoints, Info] = ...
    refinePolicy(...
        self, ...
        tmpInterpPolicy, ...
        currentSolution, ...
        previousSolution, ...
        discreteState, ...
        t, ...
        Info)

for p = 1:self.numberOfPolicies
    policyName = self.policyNames{p};
    toleranceFlag.(policyName) = true;
end
i = zeros(1, self.numberOfPolicies);
noStartPoints    = nan(1, self.numberOfPolicies);
noRefines        = noStartPoints;
noInsertedPoints = noStartPoints;
noEndPoints      = noStartPoints;

for p = 1:self.numberOfPolicies
    policyName = self.policyNames{p};
    noStartPoints(p)    = size(tmpInterpPolicy.(policyName).gridPoints, 1);
    noRefines(p)        = 0;
    noInsertedPoints(p) = 0;
end
while true
    additionalPointsUnion = zeros(0, self.numberOfStates);
    for p = 1:self.numberOfPolicies
        policyName = self.policyNames{p};
        additionalPoints.(policyName) = zeros(0, self.numberOfStates);
        if toleranceFlag.(policyName) && ...
                (i(p) < self.Grid.Policy.(discreteState).(policyName).maxRefine) && ...
                self.Grid.Policy.(discreteState).(policyName).refineTimes(t.age)
            toleranceFlag.(policyName) = false;
            additionalPoints.(policyName) = tmpInterpPolicy.(policyName).refine( 'points', ...
                                self.Grid.Policy.(discreteState).(policyName).refineType, ...
                                size(tmpInterpPolicy.(policyName).gridPoints, 1), ...
                                self.Grid.Policy.(discreteState).(policyName).refineTolerance,...
                                self.Grid.Policy.(discreteState).(policyName).Basis.enableUP, ...
                                self.Grid.Policy.(discreteState).(policyName).Basis.degree);
            if size(additionalPoints.(policyName) , 1) > 0
                toleranceFlag.(policyName) = true;
                noRefines(p)        = noRefines(p) + 1;
                noInsertedPoints(p) = noInsertedPoints(p) + ...
                                        size(additionalPoints.(policyName) , 1);
            end
            i(p) = i(p) + 1;
        end
        additionalPointsUnion = union(additionalPointsUnion, ...
                                      additionalPoints.(policyName), 'rows');
    end

    if ~isempty(additionalPointsUnion)
        [currentSolution, InfoOptimize] = self.optimize(currentSolution, previousSolution, ...
                                            additionalPointsUnion, discreteState, t);
        for p = 1:self.numberOfPolicies
            policyName = self.policyNames{p};
            if ~isempty(additionalPoints.(policyName))
                tmpInterpPolicy.(policyName).fit(resortValuesToPoints( ...
                    tmpInterpPolicy.(policyName).gridPoints, ...
                    currentSolution.gridPoints.(discreteState), ...
                    [currentSolution.policy.(discreteState).(policyName)]'));
            end
        end

        % Update timing
        Info.Time.optimizer = Info.Time.optimizer + InfoOptimize.Time.optimizer;
        Info.Time.COP = Info.Time.COP + InfoOptimize.Time.COP;
        Info.Calls.J = Info.Calls.J + InfoOptimize.Calls.J;
        Info.Calls.gradJ = Info.Calls.gradJ + InfoOptimize.Calls.gradJ;
        Info.Calls.Evaluate.J = Info.Calls.Evaluate.J + InfoOptimize.Calls.Evaluate.J;
        Info.Calls.Evaluate.gradJ = Info.Calls.Evaluate.gradJ + InfoOptimize.Calls.Evaluate.gradJ;
    else
        break;
    end  
end

for p = 1:self.numberOfPolicies
    policyName = self.policyNames{p};
    noEndPoints(p) = size(tmpInterpPolicy.(policyName).gridPoints, 1);
end

end
