function serializeResult(ids)

if ~exist('ids', 'var'); ids = []; end
if ischar(ids); ids = eval(ids); end

% set paths
rootPath = pwd;
resultsParentPath = [rootPath filesep 'results'];

% sort sub-directories corresponding to results by ascending ID
resultsDirs = dir(resultsParentPath);
resultsNames = {resultsDirs.name};
[~, I] = sort(resultsNames);
resultsDirs = resultsDirs(I);

parfor i = 1:numel(resultsDirs)
    % parse directory name
    if ~resultsDirs(i).isdir; continue; end
    matches = regexp(resultsDirs(i).name, '^([0-9]{4})($|_)(.*)', 'tokens');
    if isempty(matches); continue; end
    idStr = matches{1}{1};
    id = str2double(idStr);
    if ~isempty(ids)
        if isscalar(ids)
            if id < ids; continue; end
        else
            if isempty(find(ids == id, 1)); continue; end
        end
    end

    % set path
    resultsPath = getResultsPath(id);
    
    % serialize output *.mat files so that SgppInterpolant objects can be analyzed in Python
    for name = {'results', 'policies'}
        matFile = [resultsPath filesep name{:} '.mat'];
        serializedMatFile = [resultsPath filesep name{:} '_serialized.mat'];
        if exist(matFile, 'file') && ~exist(serializedMatFile, 'file')
            serializeMat(matFile, serializedMatFile);
        end
    end
        
end

end
