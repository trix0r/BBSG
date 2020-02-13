function plotPolicies(self, solution, discreteState, interpPolicy, errors)

if ~exist('interpPolicy', 'var'); interpPolicy = []; end
if ~exist('errors', 'var');       errors = []; end

plotCount = 1 + self.numberOfGradientStates;
if ~isempty(interpPolicy)
    plotCount = plotCount + self.numberOfPolicies;
end
if ~isempty(errors)
    if isfield(self.EulerError, 'names')
        numberOfErrors = numel(self.EulerError(1).names);
        errorNames = self.EulerError(1).names;
    else
        numberOfErrors = size(errors(1).All, 2);
        errorNames = [];
    end
    plotCount = plotCount + numberOfErrors;
else
    numberOfErrors = 0;
end

functions = cell(1, plotCount);
labels    = cell(1, plotCount);
statuses  = cell(1, plotCount);

q = 1;
functions{q} = {solution.interpJ};
labels{q} = 'J';
statuses{q} = cell(size(functions{q}));

for t = self.Time.getRange()
    if ~isempty(functions{q}{t}.(self.discreteStateNames{1}))
        statuses{q}{t} = resortValuesToPoints( ...
            functions{q}{t}.(discreteState).gridPoints, ...
            solution(t).gridPoints.(discreteState), ...
            solution(t).status.(discreteState));
    end
end

if self.numberOfGradientStates > 0
    tmpGradientStates = {solution.interpGradJ};

    for i = 1:self.numberOfGradientStates
        gradientStateName = self.gradientStateNames{i};
        q = q + 1;
        functions{q} = cell(1, numel(solution));
        labels{q} = sprintf('\\nabla_{%s} J', gradientStateName);
        statuses{q} = cell(size(functions{q}));
        
        for t = self.Time.getRange()
            if ~isempty(tmpGradientStates{t}.(discreteState).(gradientStateName))
                functions{q}{t}.(discreteState) = ...
                    tmpGradientStates{t}.(discreteState).(gradientStateName);
                statuses{q}{t} = resortValuesToPoints( ...
                    functions{q}{t}.(discreteState).gridPoints, ...
                    solution(t).gridPoints.(discreteState), ...
                    solution(t).status.(discreteState));
            end
        end
    end
end

if ~isempty(interpPolicy)
    tmpPolicies = {interpPolicy.(discreteState)};
    
    for i = 1:self.numberOfPolicies
        policyName = self.policyNames{i};
        q = q + 1;
        functions{q} = cell(1, numel(solution));
        labels{q} = policyName;
        
        for t = self.Time.getRange()
            if ~isempty(tmpPolicies{t})
                functions{q}{t}.(discreteState) = tmpPolicies{t}.(policyName);
            end
        end
    end
end

if ~isempty(errors)
    for i = 1:numberOfErrors
        q = q + 1;
        functions{q} = cell(1, numel(solution));
        if ~isempty(errorNames)
            labels{q} = sprintf('Log10 of Euler error %s', errorNames{i});
        else
            labels{q} = sprintf('Log10 of Euler error %u', i);
        end

        for t = self.Time.getRange()
            if (t.index <= numel(errors)) && ~isempty(errors(t))
                functions{q}{t}.(discreteState).points = self.EulerError(t).points;
                functions{q}{t}.(discreteState).data   = log10(abs(errors(t).All(:,i)));
            end
        end
    end
end

self.plotGridFunctions(functions, discreteState, labels, statuses);
