function path = getResultsPath(id)

% set paths
rootPath = pwd;
resultsParentPath = [rootPath filesep 'results'];

% search for directory with matching ID
resultsDirs = dir(resultsParentPath);
resultsDir = [];
    
for i = 1:numel(resultsDirs)
    if resultsDirs(i).isdir
        matches = regexp(resultsDirs(i).name, '^([0-9]{4})($|_)', 'tokens');
        if ~isempty(matches)
            if str2double(matches{1}{1}) == id
                resultsDir = resultsDirs(i).name;
                break;
            end
        end
    end
end

assert(~isempty(resultsDir), 'Specified ID not found.');
path = [resultsParentPath filesep resultsDir];
