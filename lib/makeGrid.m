function g = makeGrid(x)

d = size(x, 1);
if ~iscell(x); x = mat2cell(x, ones(1, d)); end
X = cell(size(x));
[X{:}] = ndgrid(x{:});
g = nan(prod(cellfun(@numel, x)), d);
for i = 1 : d
    g(:, i) = X{i}(:);
end

end
