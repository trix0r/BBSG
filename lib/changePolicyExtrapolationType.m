function interpPolicy = changePolicyExtrapolationType(id, type)

resultsPath = sprintf('results/%0.4u',id);
matFile = [resultsPath filesep 'policies.mat'];

% faster than loadVariables if problem is not needed as problem is constructed anew in loadVariables
load(matFile, 'self', 'solution', 'Info', 'interpPolicy');
for t = self.Time.getRange()
    for p = 1:self.numberOfPolicies
        policyName = self.policyNames{p};
        interpPolicy(t).Alive.(policyName).extrapolationType = type;
    end
end

save(matFile, 'self', 'solution', 'Info', 'interpPolicy');

end
