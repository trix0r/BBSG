function newState = computeStateTransition(self, state, ~, t, policy, shock)

newState = zeros(size(shock, 1), self.numberOfStates);

% income transition
[newLogNormP, newLogNormY] = self.computeIncomeTransition(t, shock);

% short rate transition
R = state(:, end); % short rate is always last dimension
dR = shock(:, 4); % change of short rate
newR = self.Interest.trunc(R + dR);
newState(:, end) = newR;

% wealth transition
newState(:, 1) = computePortfolioValue(self, R, newR, policy, shock, t) ./ exp(newLogNormP) + ...
                 exp(newLogNormY) * self.Time.ageStep;

% annuity transition
switch lower(self.modelVariant)
    case 'debug'
        return
    case {'noannuitywithbond', 'debugonlybond'}
        return
    case {'termcertainannuitynobond', 'lifeannuitynobond'}
        normL = state(:, 2);
        normA = policy(:, 3);
    case 'lifeannuitywithbond'
        normL = state(:, 2);
        normA = policy(:, 4);
    case 'debugannuity'
        normL = state(:, 2);
        normA = policy(:, 2);
end
if ismember(t.age, self.eligibleAnnuityPurchaseAges)
    % for the optimization, we have numel(R) == 1 and the key is in the map; for the simulation,
    % compute everything on the fly
    if numel(R) == 1 && isKey(self.annuityfactors, {R})
        vals = values(self.annuityfactors, {R});
        annuityfactors = vals{:};
        annuityPrice = annuityfactors(t);
    else
        if t.age >= self.Income.retirementAge
            % buy immediate annuity
            annuityPrice = self.computeAnnuityFactor(t.age, R, 0);
        else
            annuityPrice = self.computeAnnuityFactor(t.age, R, self.Income.retirementAge - ...
                                                     t.age - self.Time.ageStep);
        end
    end
    newState(:, 2) = (normL + normA ./ annuityPrice) ./ exp(newLogNormP);
else
    newState(:, 2) = normL ./ exp(newLogNormP);
end

end


function portfolioValue = computePortfolioValue(self, R, newR, policy, shock, t)

dt = self.Time.ageStep;

% return parameters
rStock = shock(:, 1); % stock return
% for the optimization, we have numel(R) == 1 and the key is in the map; for the simulation, compute
% everything on the fly
if numel(R) == 1 && isKey(self.yields, {R})
    vals = values(self.yields, {R});
    yield = vals{:};
else
    yield = self.computeSpotRates(R(1), self.Interest.kappa, self.Interest.theta, ...
                                   self.Interest.sigma, self.Interest.lambda, self.Time.ageStep, ...
                                   self.Interest.model);
end
rf = exp(yield * dt); % risk-free return

switch lower(self.modelVariant)
    case {'debug', 'debugannuity'}
        normB = policy(:, 1);
        portfolioValue = normB .* rf;
    case 'debugonlybond'
        normBP = policy(:, 1);
        rBondPortfolio = computeBondPortfolioReturn(self, R, newR, t);
        portfolioValue = normBP .* rBondPortfolio;
    case {'noannuitywithbond', 'lifeannuitywithbond'}
        normS = policy(:, 1);
        normB = policy(:, 2);
        normBP = policy(:, 3);
        rBondPortfolio = computeBondPortfolioReturn(self, R, newR, t);
        portfolioValue = normS .* rStock + normB .* rf + normBP .* rBondPortfolio;
    case {'termcertainannuitynobond', 'lifeannuitynobond'}
        normS = policy(:, 1);
        normB = policy(:, 2);
        portfolioValue = normS .* rStock + normB .* rf;
end

end

function rBondPortfolio = computeBondPortfolioReturn(self, R, newR, t)
% for the optimization, we have numel(R) == 1 and the key is in the map; for the simulation, compute
% everything on the fly
if numel(R) == 1 && isKey(self.bondPortfolioYieldsNodes, {R})
    vals = values(self.bondPortfolioYieldsNodes, {R});
    bondPortfolioYieldsNodes = vals{:};
    vals = values(self.bondPortfolioYieldsGrids, {R});
    bondPortfolioYieldsGrids = vals{:};
    rBondPortfolio = bondPortfolioYieldsNodes(:, t) ./ bondPortfolioYieldsGrids(t);
else
    if t.age < self.Income.retirementAge - self.Time.ageStep
        lastPrice = self.computeBondPortfolioPrice(t.age, R, ...
                                            self.Income.retirementAge - self.Time.ageStep - t.age);
        currentPrice = self.computeBondPortfolioPrice(t.age + self.Time.ageStep, newR, ...
                                            self.Income.retirementAge - self.Time.ageStep - ...
                                            (t.age + self.Time.ageStep));
    else
        lastPrice = self.computeBondPortfolioPrice(t.age, R, 0);
        currentPrice = 1 + self.computeBondPortfolioPrice(t.age + self.Time.ageStep, newR, 0);
    end
    rBondPortfolio = currentPrice ./ lastPrice;
end

end
