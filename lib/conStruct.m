function s = conStruct(fields, value)

if ~exist('value', 'var'); value = []; end
[values{1:numel(fields)}] = deal(value);
args = [fields(:)'; values];
s = struct(args{:});

end
