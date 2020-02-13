function listResults(ids)

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

previousID = [];
previousParameters = [];

for i = 1:numel(resultsDirs)
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

    resultsPath = [resultsParentPath filesep resultsDirs(i).name];
    name = matches{1}{3};

    % print line if there is a gap of at least two missing IDs
    if ~isempty(previousID) && (id > previousID + 2)
        fprintf('%s\n', repmat('-', 1, 70));
    end

    % print comment if available
    commentPath = [resultsPath filesep 'comment.txt'];
    if exist(commentPath, 'file')
        comment = fileread(commentPath);
        fprintf(2, '%s\n', strip(comment));
    end

    % construct string
    s = sprintf('id=%s', idStr);
    if ~isempty(name); s = sprintf('%s name=%s', s, name); end
    load([resultsPath filesep 'properties.mat'], 'properties');
    parameters = properties.parameters;

    parameterNames = fieldnames(parameters);
    parameterNames = parameterNames(:)';

    % list parameters that were set for the previous ID,
    % but aren't set for the current ID
    if ~isempty(previousParameters)
        previousParameterNames = fieldnames(previousParameters);
        previousParameterNames = previousParameterNames(:)';

        for previousParameterName = previousParameterNames
            if ~isfield(parameters, previousParameterName{:})
                s = sprintf('%s %s=-', s, previousParameterName{:});
            end
        end
    end

    % list parameters of the current ID that changed compared with the previous ID
    % (or weren't set for the previous ID)
    for parameterName = parameterNames
        % isequal cannot compare fct. handles in R2017b... so we have to
        % make a string out of everything before hand
        parameterString = parameterToString(parameters.(parameterName{:}));
        if isempty(previousParameters) || ~isfield(previousParameters, parameterName{:})
            s = sprintf('%s %s=%s', s, parameterName{:}, parameterString);
        else
            previousParameterString = parameterToString(previousParameters.(parameterName{:}));
            if ~strcmp(parameterString, previousParameterString)
                s = sprintf('%s %s=%s', s, parameterName{:}, parameterString);
            end
        end
    end

    % printing string
    fprintf('%s\n', s);

    previousID = id;
    previousParameters = parameters;
end

end

function parameterString = parameterToString(parameterValue)

parameterString = parameterValue;

if iscell(parameterString)
    parameterString = objToString(parameterValue);
end
if ~ischar(parameterString)
    if isa(parameterValue, 'function_handle')
        parameterString = func2str(parameterValue);
    elseif isobject(parameterValue)
       parameterString = objToString({parameterValue});
    else
        parameterString = mat2str(parameterValue);
    end
end

end

function string = objToString(objs)

string = '{';
for i = 1:numel(objs)
    obj = objs{i};
    if ischar(obj)
        string = sprintf('%s%s,', string, obj);
    else
        objName = class(obj);
        props = properties(obj);
        if isempty(props)
            string = sprintf('%s%s,', string, objName);
        else
            string = sprintf('%s%s(', string, objName);
            for p = props
                propValue = obj.(p{:});
                if ~ischar(propValue); propValue = mat2str(propValue); end
                string = sprintf('%s%s,', string, propValue);
            end
            string = [string(1:end - 1) '),'];
        end
    end
end
if length(string) > 1; string = [string(1:end - 1) '}']; end

end
