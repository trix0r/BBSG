function serializeMat(fromPath, toPath)

try
    warningState = warning('off', 'MATLAB:structOnObject');
    contents = load(fromPath);
    contents = serializeEntry(contents);
    save(toPath, '-struct', 'contents');
catch e
    warning(warningState.state);
    rethrow(e);
end

warning(warningState.state);

end

function entry = serializeEntry(entry)
    if isstruct(entry)
        fieldNames = fields(entry);
        
        for i = 1:numel(entry)
            for j = 1:numel(fieldNames)
                entry(i).(fieldNames{j}) = ...
                    serializeEntry(entry(i).(fieldNames{j}));
            end
        end
    elseif iscell(entry)
        for i = 1:numel(entry)
            entry{i} = serializeEntry(entry{i});
        end
    elseif isobject(entry)
        if isa(entry, 'SgppInterpolant')
            entry = entry.saveobj();
        else
            entry = struct(entry);
        end
        
        entry = serializeEntry(entry);
    end
end
