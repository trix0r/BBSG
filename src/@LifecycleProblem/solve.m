function [solution, Info] = solve(self)

%% allocate folders for output
if ~exist(self.Env.outdir, 'dir')
    mkdir(self.Env.outdir);
end

%% set time stepping parameters
tStart = self.Time.getStart();
tStop = self.Time.getStop();

if self.Env.resume
    loadVariables([self.Env.outdir filesep 'results.mat'], 'solution', 'Info');
    ds = self.discreteStateNames{1};
    l = find(~cell2mat(...
                cellfun(@(i) {isempty(solution(i).J.(ds))}, ...
                num2cell(self.Time.getStart():self.Time.getStop()))), 1); %#ok<NODEF>
    tStop = self.Time.copy(l);
    % unset resume flag after resuming
    self.Env.resume = 0;
else
    %% allocate last period's interpolants
    emptySolution = struct();
    emptySolution.gridPoints = conStruct(self.discreteStateNames, zeros(0, self.numberOfStates));
    emptySolution.J          = conStruct(self.discreteStateNames, zeros(0, 1));
    emptySolution.policy     = conStruct(self.discreteStateNames, ...
                                         repmat(conStruct(self.policyNames), 0, 1));
    emptySolution.lambda     = conStruct(self.discreteStateNames, ...
                                         repmat(conStruct({'isActive', 'multiplier'}), 0, 1));
    emptySolution.status     = conStruct(self.discreteStateNames, zeros(0, 1));
    emptySolution.interpJ    = conStruct(self.discreteStateNames);
    emptySolution.interpOptJ = conStruct(self.discreteStateNames);
    if self.numberOfGradientStates > 0
        emptySolution.gradJ       = conStruct(self.discreteStateNames, ...
                                              repmat(conStruct(self.gradientStateNames), 0, 1));
        emptySolution.interpGradJ = conStruct(self.discreteStateNames, ...
                                              conStruct(self.gradientStateNames));
    end
    solution = repmat(emptySolution, 1, tStop.index);
    
    %% compute last period's optimal solution
    % assumption: J and GradJ grids are the same in last period
    for k = 1:self.numberOfDiscreteStates
        discreteStateName = self.discreteStateNames{k};
        % set solution in the last period
        state = self.Grid.J.(discreteStateName).base.gridPoints;
        for q = 1:self.numberOfGradientStates
            gradientStateName = self.gradientStateNames{q};
            state = [state; self.Grid.gradJ.(discreteStateName). ...
                            (gradientStateName).base.gridPoints]; %#ok<AGROW>
        end
        state = unique(state, 'rows');

        solution(tStop) = self.optimize(solution(tStop), [], state, discreteStateName, tStop);
    end
    
    %% initialize timing
    %Info.Time.evaluate   = 0;
    %Info.Time.getJ       = 0;
    Info.Time.optimizer   = 0;
    Info.Time.COP         = 0;
    Info.Time.optimize    = 0;
    Info.Time.refine      = 0;
    Info.Calls.J          = 0;
    Info.Calls.gradJ      = 0;
    Info.Calls.Evaluate.J = 0;
    Info.Calls.Evaluate.gradJ = 0;
end

%% initialize output strings
headerRefine = sprintf('Type            All      J  ');
formatRefine = sprintf('%%-14s %%4u   %%4u  ');
minimumHeaderWidth = 4;
for q = 1:self.numberOfGradientStates
    gradientStateName = self.gradientStateNames{q};
    headerWidth = max(numel(gradientStateName) + 3, minimumHeaderWidth);
    headerRefine = sprintf(sprintf('%%s %%%us', headerWidth), ...
                           headerRefine, ['dJ_' gradientStateName]);
    formatRefine = sprintf('%s %%%uu', formatRefine, headerWidth);
end
headerRefine = sprintf('%s\n', headerRefine);
formatRefine = sprintf('%s\n', formatRefine);
headerOptimize = sprintf(sprintf('ID                 Code   State  %s\n', ...
                                 strtrim(repmat('%8s ', 1, self.numberOfStates))), ...
                         self.stateNames{:});

%% solve period by period backwards in time
if self.Env.resume % append to log file when resuming
    fid = fopen([self.Env.outdir filesep 'optimization_log.txt'], 'a');
else
    fid = fopen([self.Env.outdir filesep 'optimization_log.txt'], 'w');
end
timer = tic;

for t = tStop - 1: -1 : tStart

    if t.getNext().isStop()
        previousPreviousSolution = [];
    else
        previousPreviousSolution = solution(t + 2);
    end

    for k = 1:self.numberOfDiscreteStates
        discreteStateName = self.discreteStateNames{k};
        %% refine and remove points
        printToConsoleAndFile(fid, ...
            sprintf('Refining (t = %u, discrete state = %s)...\n', ...
                    t.age, discreteStateName));
        printToConsoleAndFile(fid, headerOptimize);
        time_refine = tic();
        [solution(t + 1), ...
            noStartPoints, noRefines, noInsertedPoints, noEndPoints, ...
            noPreviousPoints, noAddedPoints, noRemovedPoints, InfoRefine] = ...
            self.refine(solution(t + 1), previousPreviousSolution, ...
                        discreteStateName, t);
        time_refine = toc(time_refine);
        Info.Time.refine = Info.Time.refine + time_refine;
        Info.Time.optimizer = Info.Time.optimizer + InfoRefine.Time.optimizer;
        Info.Time.COP = Info.Time.COP + InfoRefine.Time.COP;
        Info.Calls.J = Info.Calls.J + InfoRefine.Calls.J;
        Info.Calls.gradJ = Info.Calls.gradJ + InfoRefine.Calls.gradJ;
        Info.Calls.Evaluate.J = Info.Calls.Evaluate.J + InfoRefine.Calls.Evaluate.J;
        Info.Calls.Evaluate.gradJ = Info.Calls.Evaluate.gradJ + InfoRefine.Calls.Evaluate.gradJ;
        printToConsoleAndFile(fid, ...
            sprintf('Done refining in %.2fs (t = %u, discrete state = %s).\n\n', ...
                    time_refine, t.age, discreteStateName));

        printToConsoleAndFile(fid, headerRefine);
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#Start pts.', noStartPoints));
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#Refines', noRefines));
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#Inserted pts.', noInsertedPoints));
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#End pts.', noEndPoints));
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#Previous pts.', noPreviousPoints));
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#Added pts.', noAddedPoints));
        printToConsoleAndFile(fid, ...
            sprintf(formatRefine, '#Removed pts.', noRemovedPoints));
        printToConsoleAndFile(fid, sprintf('\n')); %#ok<SPRINTFN>

        %% create interpolant
        for q = 1:self.numberOfDiscreteStates
            discreteStateName = self.discreteStateNames{q};
            % join adaptively refined gradient grid points to value
            % function grid
            solution(t + 1) = createBsplineInterpolant( ...
                self, solution(t + 1), previousPreviousSolution, t + 1, discreteStateName, ...
                fid, headerOptimize);
        end
    end

    for k = 1:self.numberOfDiscreteStates
        discreteStateName = self.discreteStateNames{k};
        %% compute optimum
        printToConsoleAndFile(fid, ...
            sprintf('Optimizing (t = %u, discrete state = %s)...\n', ...
                    t.age, discreteStateName));
        printToConsoleAndFile(fid, headerOptimize);

        % it is necessary to compute the optimum for interpGradJ grid points as the J
        % values at those points are needed and (due to refinement) the grid points
        % of J aren't, in general, a superset of the grid points of interpGradJ
        state = solution(t + 1).interpJ.(discreteStateName).gridPoints;
        for q = 1:self.numberOfGradientStates
            gradientStateName = self.gradientStateNames{q};
            state = [state; solution(t + 1).interpGradJ.(discreteStateName). ...
                            (gradientStateName).gridPoints]; %#ok<AGROW>
        end

        time_optimize = tic();
        [solution(t), InfoOptimize] = ...
            self.optimize(solution(t), solution(t + 1), state, discreteStateName, t);
        time_optimize = toc(time_optimize);
        printToConsoleAndFile(fid, ...
            sprintf('Done optimizing in %.2fs (t = %u, discrete state = %s).\n\n', ...
                    time_optimize, t.age, discreteStateName));

        %Info.Time.evaluate = Info.Time.evaluate + InfoOptimize.Time.evaluate;
        %Info.Time.getJ = Info.Time.getJ + InfoOptimize.Time.getJ;
        Info.Time.optimize = Info.Time.optimize + time_optimize;
        Info.Time.optimizer = Info.Time.optimizer + InfoOptimize.Time.optimizer;
        Info.Time.COP = Info.Time.COP + InfoOptimize.Time.COP;
        Info.Calls.J = Info.Calls.J + InfoOptimize.Calls.J;
        Info.Calls.gradJ = Info.Calls.gradJ + InfoOptimize.Calls.gradJ;
        Info.Calls.Evaluate.J = Info.Calls.Evaluate.J + InfoOptimize.Calls.Evaluate.J;
        Info.Calls.Evaluate.gradJ = Info.Calls.Evaluate.gradJ + InfoOptimize.Calls.Evaluate.gradJ;
    end

    % create interpolant for t = tStart
    if t.isStart()
        for q = 1:self.numberOfDiscreteStates
            discreteStateName = self.discreteStateNames{q};
            % join adaptively refined gradient grid points to value function grid
            solution(t) = createBsplineInterpolant( ...
                self, solution(t), solution(t + 1), t, discreteStateName, ...
                fid, headerOptimize);
        end
    end

    save([self.Env.outdir filesep 'results.mat'], 'self', 'solution', 'Info');
    
end

time = toc(timer);
printToConsoleAndFile(fid, sprintf('Calculation time was %0.2f seconds.\n', time));
fclose(fid);

end



function previousSolution = createBsplineInterpolant( ...
    self, previousSolution, previousPreviousSolution, previousT, discreteState, ...
    fid, headerOptimize)

printToConsoleAndFile(fid, ...
    sprintf('Creating interpolant (t = %u, discrete state = %s)...\n', ...
            previousT.getPrev().age, discreteState));
printToConsoleAndFile(fid, headerOptimize);
time_interpolant = tic();

previousSolution.interpOptJ.(discreteState) = ...
    previousSolution.interpJ.(discreteState).copy(self.Basis.BsplineType, ...
                                                  self.Basis.BsplineDegree);
for q = 1:self.numberOfGradientStates
    gradientStateName = self.gradientStateNames{q};
    previousSolution.interpOptJ.(discreteState).joinGrids( ...
        previousSolution.interpGradJ.(discreteState).(gradientStateName));
end

% we don't need to insert chains if numberOfGradientStates is zero,
% since chains are automatically inserted by the C++ interface after each refine
if self.Basis.enableUP && (self.numberOfGradientStates > 0)
    newGridPoints = ...
        previousSolution.interpOptJ.(discreteState).insertChains(self.Basis.BsplineDegree);
    previousSolution = self.optimize(previousSolution, previousPreviousSolution, ...
                                     newGridPoints, discreteState, previousT);
end

previousSolution.interpOptJ.(discreteState).fit(resortValuesToPoints( ...
    previousSolution.interpOptJ.(discreteState).gridPoints, ...
    previousSolution.gridPoints.(discreteState), ...
    previousSolution.J.(discreteState)));

time_interpolant = toc(time_interpolant);
printToConsoleAndFile(fid, ...
    sprintf('Done creating interpolant in %.2fs (t = %u, discrete state = %s).\n\n', ...
            time_interpolant, previousT.getPrev().age, discreteState));

end
