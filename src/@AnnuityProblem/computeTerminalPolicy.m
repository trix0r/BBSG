function policy = computeTerminalPolicy(~, state, ~)

policy.normS = zeros(size(state, 1), 1);
policy.normB = zeros(size(state, 1), 1);
policy.normA = zeros(size(state, 1), 1);

% create struct array from structure of arrays
policy = struct2struct(policy);
