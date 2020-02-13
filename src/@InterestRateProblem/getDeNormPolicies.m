function [deNormPolicy, deNormPolicyNames] = getDeNormPolicies(self, policy)
%% Compute non-normalized policies

numberOfPaths = size(policy.(self.policyNames{1}), 1);
numberOfTimes = size(policy.(self.policyNames{1}), 2);
deNormPolicyNames = strrep(self.policyNames, 'norm', '');

deNormPolicy = zeros(numberOfPaths, numberOfTimes, numel(deNormPolicyNames));
for p = 1:numel(deNormPolicyNames)
    deNormPolicyName = deNormPolicyNames{p};
    deNormPolicy(:, :, p) = policy.(deNormPolicyName);
end

end
