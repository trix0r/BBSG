function [consumption, utility] = computeCertaintyEquivalent(self, state, policy, t)

times = self.Time.getRange();
if nargin < 4; t = times(1); end

%% Compute non-normalized consumption
C = self.computeConsumptionDistribution(state, policy);

% %% compute CE
% g = self.riskAversion;
% p = self.elasticityOfIntertemporalSubstitution;
% df = self.discountFactor.^(0:self.Time.ageStep:self.Time.getStop().index - 1);
% sp = [1 cumprod(self.transitionMatrix(1:end - 1))'];
% utility = sum(df .* sp.^(p / g) .* mean(C.^p, 1), 2);
% consumption = (utility ./ (sum(df .* sp.^(p / g), 2)))^(1 / p);

%% compute CE via recursive formulation
utility = mean(evaluateRecursiveUtility(self, C, t), 1);
tgt = @(x) (utility - mean(evaluateRecursiveUtility(self, repmat(x, size(C)), t), 1))^2;
x0 = mean(mean(C(:, t.index:end)));
consumption = fminsearch(tgt, x0);
end

function utility = evaluateRecursiveUtility(self, C, t)
    if t.isStop()
        % terminal condition to be precise: utility = (C(:, t).^p).^(1 / p);
        utility = C(:, t);
        return
    end
    p = self.elasticityOfIntertemporalSubstitution;
    g = self.riskAversion;
    df = self.discountFactor^(t.ageStep);
    sp = self.transitionMatrix(t, 1, 1);
    utility = (C(:, t).^p + ...
        df * (sp * mean(evaluateRecursiveUtility(self, C, t.getNext()).^g, 1)).^(p / g)).^(1 / p);
end
