function copyResults(copiedIds, newIds, comment)
% copy existing results to a new IDs

if ~exist('comment', 'var'); comment = []; end
assert(numel(copiedIds) == numel(newIds), 'Different number of ids given for source and target.');

rootPath = pwd;
resultsParentPath = [rootPath filesep 'results'];

for i = 1:numel(copiedIds)
    %% modify properties for new ID
    properties = loadResult(copiedIds(i), {'properties'});
    % set reuse solution as anchor to copied ID
    properties.reuseSolution = copiedIds(i);
    properties.id = newIds(i);
    properties.comment = comment;

    %% create new result path
    resultsDir = sprintf('%04u', properties.id);
    resultsPath = [resultsParentPath filesep resultsDir];
    assert(~exist(resultsPath, 'dir'), 'Results path already exists.');
    warning('off', 'MATLAB:MKDIR:DirectoryExists')
    mkdir(resultsPath);
    warning('on', 'MATLAB:MKDIR:DirectoryExists')

    %% save modified properties
    save([resultsPath filesep 'properties.mat'], 'properties');
    %% copy files
    % exclude comment, properties, and plotJ log files
    copiedResultsPath = getResultsPath(copiedIds(i));
    copyResultFiles(copiedResultsPath, resultsPath, ...
        {'version_info.mat', 'results.mat', 'optimization_log.txt', 'policies.mat', ...
         'policy_log.txt', 'euler_errors.mat', 'errors.txt', 'simulation.mat'});

    % serialize output *.mat files so that SgppInterpolant objects can be analyzed in Python
    for name = {'results', 'policies'}
        serializeMat([resultsPath filesep name{:} '.mat'], ...
                     [resultsPath filesep name{:} '_serialized.mat']);
    end
end
