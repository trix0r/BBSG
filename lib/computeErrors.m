function [errors, envelope_errors] = computeErrors(id, type)

if ~exist('type', 'var'); type = 'all'; end

[~, problem, solution, ~, interpPolicy] = loadResult(id, {'problem', 'solution', 'interpPolicy'});
resultsPath = sprintf('results/%0.4u',id);

errors = [];
if strcmpi('generalized', type) || strcmpi('all', type)
    % compute and print errors
    errors = problem.computeStateSpaceEulerErrors(solution, interpPolicy);
    problem.printErrors(errors);
    copyResultFiles(problem.Env.outdir, resultsPath, {'euler_errors.mat', 'errors.txt'});
end

envelope_errors = [];
if strcmpi('envelope', type) || strcmpi('all', type)
    % compute and print conventional euler errors w/ envelope theorem
    envelope_errors = problem.computeStateSpaceEnvelopeEulerErrors(solution, interpPolicy);
    problem.printErrors(envelope_errors);
    copyResultFiles(problem.Env.outdir, resultsPath, {'envelope_euler_errors.mat', ...
                                                      'envelope_errors.txt'});
end

end

% copy one or multiple files from out/ to results/
function copyResultFiles(outPath, resultsPath, filenames)
if ~iscell(filenames); filenames = {filenames}; end
for filename = filenames
    copyfile([outPath filesep filename{:}], [resultsPath filesep filename{:}]);
end
end
