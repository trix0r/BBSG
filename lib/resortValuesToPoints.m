function targetValues = resortValuesToPoints(targetPoints, sourcePoints, sourceValues)

[~, Idx] = ismember(targetPoints, sourcePoints, 'rows');
assert(all(Idx ~= 0), 'targetPoints is not a subset of sourcePoints.');
targetValues = sourceValues(Idx, :);

end
