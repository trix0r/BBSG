function loadVariables(matPath, varargin)
    warningState = warning('off', 'MATLAB:load:variableNotFound');
    try
        load(matPath, varargin{:});
    catch
    end
    warning(warningState);

    for name = varargin
        if exist(name{:}, 'var'); variable = eval(name{:});
        else;                     variable = []; end
        assignin('caller', name{:}, variable);
    end
end
