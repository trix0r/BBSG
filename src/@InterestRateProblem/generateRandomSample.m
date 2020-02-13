function shocks = generateRandomSample(self, numberOfSamples, state, ~, ~)

n = numberOfSamples;
dt = self.Time.ageStep;
R = state(:, end);

shocks = zeros(n, self.numberOfShocks);

% Cholesky decomposition matrix for co-movement of stocks and short rate
Q = zeros(size(state, 1), 2, 2);
switch lower(self.Interest.model)
    case 'cir'
        Q(:,2,2) = self.Interest.sigma * sqrt(R) * sqrt(dt);
        Q(:,1,1) = self.Return.v * sqrt(dt);
        Q(:,2,1) = 0;
        Q(:,1,2) = 0;
    case 'vasicek'
    % for vasicek, the cov is not R-dependent
        tmp = chol(self.Return.Interest.cov(0, dt, ':', ':'), 'lower');
        Q(:, 1, 1) = tmp(1, 1);
        Q(:, 2, 2) = tmp(2, 2);
        Q(:, 2, 1) = tmp(2, 1);
        Q(:, 1, 2) = tmp(1, 2);
end

% Random numbers -- must be drawn before to make sure that short rate and stock are correlated
stockRand = randn(n, 1);
permanentRand =  randn(n, 1);
transitoryRand = randn(n, 1);
shortRateRand = randn(n, 1);

% Stock return
shocks(:, 1) = exp(self.Return.mean(R, dt) + (Q(:, 2, 1) .* shortRateRand + ...
                                              Q(:, 1, 1) .* stockRand));
% Income shocks
% permanent shocks
shocks(:, 2) = self.Income.Permanent.m * dt + self.Income.Permanent.v * sqrt(dt) * permanentRand;
% transitory shocks
shocks(:, 3) = self.Income.Transitory.m * dt + self.Income.Transitory.v * sqrt(dt) * transitoryRand; 

% Short rate shock
shocks(:, 4) = self.Interest.mean(R, dt) + Q(:, 2, 2) .* shortRateRand;

end
