function generateResult(varargin)

% parse input arguments
parser = inputParser();
parser.addParameter('problem', []);
parser.addParameter('name', []);
parser.addParameter('id', []);
parser.addParameter('reuseSolution', []);
parser.addParameter('parameters', {});
parser.addParameter('resume', false);
parser.addParameter('comment', []);
parser.parse(varargin{:});
properties = parser.Results;

checkNotEmpty('properties', {'problem'});

% set paths
rootPath = pwd;
externalPath      = [rootPath filesep 'external'];
logPath           = [rootPath filesep 'log'];
outPath           = [rootPath filesep 'out'];
resultsParentPath = [rootPath filesep 'results'];

% prepare directories
if ~isempty(dir([logPath filesep '*.mat'])); delete([logPath filesep '*.mat']); end
if ~exist(resultsParentPath, 'dir'); mkdir(resultsParentPath); end

% determine ID by incrementing largest existing ID
if isempty(properties.id)
    resultsDirs = dir(resultsParentPath);
    id = 0;
    
    for i = 1:numel(resultsDirs)
        if resultsDirs(i).isdir
            matches = regexp(resultsDirs(i).name, '^([0-9]{4})($|_)', 'tokens');
            if ~isempty(matches); id = max(id, str2double(matches{1}{1}) + 1); end
        end
    end
    
    properties.id = id;
end

% create results directory
resultsDir = sprintf('%04u', properties.id);
if ~isempty(properties.name); resultsDir = [resultsDir '_' properties.name]; end
resultsPath = [resultsParentPath filesep resultsDir];
assert(~exist(resultsPath, 'dir') || properties.resume, 'Results path already exists.');
warning('off', 'MATLAB:MKDIR:DirectoryExists')
mkdir(resultsPath);
warning('on', 'MATLAB:MKDIR:DirectoryExists')

% add comment.txt if properties.comment is set
if ~isempty(properties.comment)
    fid = fopen([resultsPath filesep 'comment.txt'], 'w');
    fprintf(fid, properties.comment);
    fclose(fid);
end

% convert properties to struct if given as cell array (can be parsed better)
if iscell(properties.parameters)
    properties.parameters = struct(properties.parameters{:});
end

% save properties
save([resultsPath filesep 'properties.mat'], 'properties');

% save version info (Git commits and diffs)
versionInfo = struct();
versionInfo.date     = datestr(now(), 31);
versionInfo.root     = getGitVersionInfo(rootPath);
versionInfo.external = getGitVersionInfo(externalPath);
save([resultsPath filesep 'version_info.mat'], 'versionInfo');

if ~isempty(properties.reuseSolution)
    % load existing solution
    reusedID = properties.reuseSolution;
    [~, problem, solution, Info] = loadResult(reusedID, 'solution');
    problem.loadParameter(properties.parameters);
    if properties.resume; problem.Env.resume = 1; end
    reusedResultsPath = getResultsPath(reusedID);
    copyResultFiles(reusedResultsPath, resultsPath, {'results.mat', 'optimization_log.txt'});
else
    % create and solve problem
    problem = eval(sprintf('%s(properties.parameters)', properties.problem));
    if properties.resume; problem.Env.resume = 1; end
    [solution, Info] = problem.solve();
    copyResultFiles(outPath, resultsPath, {'results.mat', 'optimization_log.txt'});
end

% generate policy interpolant
interpPolicy = problem.generatePolicyInterpolant(solution, Info);
copyResultFiles(outPath, resultsPath, {'policies.mat', 'policy_log.txt'});

% compute and print errors
errors = problem.computeStateSpaceEulerErrors(solution, interpPolicy);
problem.printErrors(errors);
copyResultFiles(outPath, resultsPath, {'euler_errors.mat', 'errors.txt'});

% compute and print conventional euler errors w/ envelope theorem
if isa(problem, 'EnvelopeLifecycleProblem')
    envelope_errors = problem.computeStateSpaceEnvelopeEulerErrors(solution, interpPolicy);
    problem.printErrors(envelope_errors);
    copyResultFiles(outPath, resultsPath, {'envelope_euler_errors.mat', 'envelope_errors.txt'});
end

% simulate
[state, discreteState, policy, shock] = problem.simulate(interpPolicy);
simulation = struct();
simulation.state         = state;
simulation.discreteState = discreteState;
simulation.policy        = policy;
simulation.shock         = shock;
save([resultsPath filesep 'simulation.mat'], 'simulation');

% serialize output *.mat files so that SgppInterpolant objects can be analyzed in Python
for name = {'results', 'policies'}
    serializeMat([resultsPath filesep name{:} '.mat'], ...
                 [resultsPath filesep name{:} '_serialized.mat']);
end

% copy log files
if ~isempty(dir([logPath filesep '*.mat']))
    copyfile([logPath filesep '*.mat'], resultsPath);
end

end

% get Git version info if possible (e.g., not possible if run on neon,
% because the Git directory is missing)
function info = getGitVersionInfo(path)
try
    info = struct();
    info.gitCommitHash = strip(runCommand(sprintf( ...
            'git -C "%s" rev-parse --short HEAD', path)));
    info.gitCommitDate = strip(runCommand(sprintf( ...
            'git -C "%s" --no-pager show -s --format="%%ci" HEAD', path)));
    info.gitDiff = runCommand(sprintf( ...
            'git -C "%s" --no-pager diff HEAD', path));
catch
    info = [];
end
end
