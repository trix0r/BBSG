function new = struct2struct(old)

% Note: might not work for non-numerical values

f = fieldnames(old);

if ~isscalar(old)
    % from struct array to structure of arrays
    tmp = struct2cell(old);
    siz = size(old);
    index = repmat({':'}, 1, ndims(old));
    for i = 1:numel(f)
        new.(f{i}) = cell2mat(reshape(tmp(i, index{:}), siz));
    end
else
    % from structure of arrays of fields with _same_ size(.)
    % to struct array
    new = repmat(struct(), size(old.(f{1})));
    for i = 1:numel(f)
        t = num2cell(old.(f{i}));
        [new.(f{i})] = t{:};
    end
end
