function updateQuadratureMaps(self, shortRates)

if ~iscell(shortRates); shortRates = num2cell(shortRates); end

idx = ~isKey(self.Int, shortRates);
keys = shortRates(idx);

% Interface to Gauss-Hermite type integration nodes and weights. For each short rate grid point R,
% it adds a key-value pair to the hashmaps quadratureNodes, yields, bondPortfolioYieldsGrids,
% bondPortfolioYieldsNodes, and annuityfactors
values = cell(numel(keys), 5);
if ~isempty(keys)
    parfor i = 1 : numel(keys)
        values(i, :) = computeValuesForKey(self, keys{i});
    end
    self.Int = [self.Int; containers.Map(keys, values(:, 1))];
    self.yields = [self.yields; containers.Map(keys, values(:, 2))];
    self.bondPortfolioYieldsGrids = [self.bondPortfolioYieldsGrids; containers.Map(keys, values(:, 3))];
    self.bondPortfolioYieldsNodes = [self.bondPortfolioYieldsNodes; containers.Map(keys, values(:, 4))];
    self.annuityfactors = [self.annuityfactors; containers.Map(keys, values(:, 5))];
end

end

function values = computeValuesForKey(self, key)

values = cell(1, 5);

n = self.maxQuadNodes;
R = key;

% computation of integration nodes and weights
m = [self.Return.mean(R, self.Time.ageStep), ...
    self.Income.Permanent.m * self.Time.ageStep, ...
    self.Income.Transitory.m * self.Time.ageStep, ...
    self.Interest.mean(R, ...
    self.Time.ageStep)];
s = [self.Return.Interest.cov(R, self.Time.ageStep, 1, 1), ...
    0, 0, self.Return.Interest.cov(R, self.Time.ageStep, 1, 2); ...
     0, self.Income.Permanent.v^2 * self.Time.ageStep, 0, 0; ...
     0, 0, self.Income.Transitory.v^2 * self.Time.ageStep, 0; ...
     self.Return.Interest.cov(R, self.Time.ageStep, 2, 1), 0, 0, ...
     self.Return.Interest.cov(R, self.Time.ageStep, 2, 2)];
[x, w] = sgQuadNorm(n, m, s);
% return shocks are lognormal
nodes = [exp(x(:,1)), x(:,2), x(:,3), x(:,4)];
weights = w;
values{1} = [nodes, weights];

 % computation of yields
yield = self.computeSpotRates(R, ...
                              self.Interest.kappa, ...
                              self.Interest.theta, ...
                              self.Interest.sigma, ...
                              self.Interest.lambda, ...
                              self.Time.ageStep, ...
                              self.Interest.model);
values{2} = yield;

% computation of annuity factors and returns of the equivalent, liquid
% bond portfolio
newR = self.Interest.trunc(R + x(:,4));
bondPortfolioYieldsGrids = zeros(1, numel(self.Time.getRange()));
bondPortfolioYieldsNodes = zeros(length(newR), numel(self.Time.getRange()));
annuityfactors = zeros(1, numel(self.Time.getRange()));
for t = self.Time.getRange()
    if t.age < self.Income.retirementAge - self.Time.ageStep
        bondPortfolioYieldsGrids(t) = self.computeBondPortfolioPrice(t.age, R, ...
                    self.Income.retirementAge - self.Time.ageStep - t.age);
        bondPortfolioYieldsNodes(:, t) = ...
            self.computeBondPortfolioPrice(t.age + self.Time.ageStep, newR, ...
                    self.Income.retirementAge - self.Time.ageStep - (t.age + self.Time.ageStep));
    else
        bondPortfolioYieldsGrids(t) = self.computeBondPortfolioPrice(t.age, R, 0);
        bondPortfolioYieldsNodes(:, t) = 1 + ...
                    self.computeBondPortfolioPrice(t.age + self.Time.ageStep, newR, 0);
    end
    if all(~strcmpi(self.modelVariant, {'noannuitywithbond', 'debug', 'debugonlybond'}))
        if t.age >= self.Income.retirementAge
            % buy immediate annuity
            annuityfactors(t) = self.computeAnnuityFactor(t.age, R, 0);
        else
            annuityfactors(t) = self.computeAnnuityFactor(t.age, R, self.Income.retirementAge - ...
                                                          t.age - self.Time.ageStep);
        end
    end
end
values{3} = bondPortfolioYieldsGrids;
values{4} = bondPortfolioYieldsNodes;
if all(~strcmpi(self.modelVariant, {'noannuitywithbond', 'debug', 'debugonlybond'}))
    values{5} = annuityfactors;
end

end
