function checkNotEmpty(parserName, names)
    for name = names
        assert(~isempty(evalin('caller', [parserName '.' name{:}])), ...
               [name{:} ' was not supplied.']);
    end
end
