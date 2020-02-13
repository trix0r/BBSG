function eligibleState = cropToEligibleState(self, state)

tau = self.linearTransactionCosts;
c   = 2 * self.minConsumption; % factor 2 only for numerical reasons
x   = state;

if self.allowBorrowing
    % crop x such that min consumption is possible
    normalization = (2 * x * tau) ./ ...
                    (tau + x * tau + sqrt(...
                        (1 - 4 * c * tau + 2 * tau + ...
                         tau^2 - 2 * x * tau^2 + ...
                         x.^2 * tau^2 - 2 * x * tau)) - 1);
else 
    % crop sum(x) such that min consumption is possible
    if tau > 0
        normalization = (2 * sum(x, 2) * tau) ./ ...
                        (tau + sum(x, 2) * tau + sqrt(...
                            (1 - 4 * c * tau + 2 * tau + tau^2 * ...
                             1 - 2 * sum(x, 2) * tau^2 + ...
                             sum(x, 2).^2 * tau^2 - 2 * sum(x, 2) * ...
                             tau)) - 1);
    else
        normalization = sum(x, 2) / (1 - c);
    end
end

eligibleState = x ./ max(normalization + 1e-10, 1);

end
