function [properties, problem, solution, Info, interpPolicy, errors, simulation, ...
          envelopeErrors] = loadResult(id, variablesToLoad) %#ok<*STOUT>

if ischar(id); id = str2double(id); end

if ~exist('variablesToLoad', 'var')
    variablesToLoad = {'properties', 'problem', 'solution', 'Info', ...
                       'interpPolicy', 'errors', 'simulation','envelopeErrors'};
end

shouldLoad = @(name) any(strcmp(name, variablesToLoad));

% set path
resultsPath = getResultsPath(id);

% load properties/results
loadVariables([resultsPath filesep 'properties.mat'], 'properties');

if shouldLoad('solution') || shouldLoad('Info') || shouldLoad('interpPolicy')
    if shouldLoad('interpPolicy')
        loadVariables([resultsPath filesep 'policies.mat'], ...
                      'self', 'solution', 'Info', 'interpPolicy');
    elseif shouldLoad('solution')
        loadVariables([resultsPath filesep 'results.mat'], 'self', 'solution', 'Info');
        interpPolicy = [];
    else
        loadVariables([resultsPath filesep 'results.mat'], 'self', 'Info');
        solution = [];
        interpPolicy = [];
    end

    % reload parameters
    problem = self;
    problem.loadParameter(properties.parameters);
else
    if shouldLoad('problem')
        if ~isfield(properties, 'problem') %#ok<*NODEF>
            properties.problem = 'TransactionCostsProblem';
            save([resultsPath filesep 'properties.mat'], 'properties');
        end
        problem = eval(sprintf('%s(properties.parameters)', properties.problem));
    else
        problem = [];
    end

    solution = [];
    interpPolicy = [];
    Info = [];
end

if shouldLoad('errors')
    loadVariables([resultsPath filesep 'euler_errors.mat'], 'errors');
else
    errors = [];
end

if shouldLoad('simulation')
    loadVariables([resultsPath filesep 'simulation.mat'], 'simulation');
else
    simulation = [];
end

if shouldLoad('envelopeErrors')
    generalizedErrors = errors;
    loadVariables([resultsPath filesep 'envelope_euler_errors.mat'], 'errors');
    envelopeErrors = errors;
    errors = generalizedErrors;
else
    envelopeErrors = [];
end

% if no output arguments specified
if nargout == 0
    % set properties/results in base workspace
    assignVariablesInBase(variablesToLoad{:});
    % prevent printing of first returned variable if called without semicolon
    clear('properties');
end

end

function assignVariablesInBase(varargin)
    for name = varargin
        try
            variable = evalin('caller', name{:});
        catch
            variable = [];
        end
        assignin('base', name{:}, variable);
    end
end
