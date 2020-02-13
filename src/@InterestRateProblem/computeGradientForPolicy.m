function gradient = computeGradientForPolicy(self, ~, gradientJ, state, ~, t, ~, shocks)

gradient = zeros(size(gradientJ, 1), self.numberOfPolicies);

% return parameters
R = state(:, end); % short rate is always last dimension
rStock = shocks(:, 1); % stock return
vals = values(self.yields, {R});
yields = vals{:};
rf = exp(yields * self.Time.ageStep); % risk-free return

% asset derivatives
switch lower(self.modelVariant)
    case {'debug', 'debugannuity'}
        gradient(:, 1) = rf .* gradientJ(:, 1);
    case {'termcertainannuitynobond', 'lifeannuitynobond', 'noannuitywithbond', ...
          'lifeannuitywithbond'}
        gradient(:, 1) = rStock .* gradientJ(:, 1);
        gradient(:, 2) = rf .* gradientJ(:, 1);
end

% bond portfolio derivatives
switch lower(self.modelVariant)
    case {'noannuitywithbond', 'lifeannuitywithbond'}
        rBondPortfolio = computeBondPortfolioReturn(self, R, t);
        gradient(:, 3) = rBondPortfolio .* gradientJ(:, 1);
    case 'debugonlybond'
        rBondPortfolio = computeBondPortfolioReturn(self, R, t);
        gradient(:, 1) = rBondPortfolio .* gradientJ(:, 1);
end

% annuity derivative
switch lower(self.modelVariant)
    case 'debug'
        return
    case 'noannuitywithbond'
        return
    case {'termcertainannuitynobond', 'lifeannuitynobond', 'lifeannuitywithbond', 'debugannuity'}
        if ismember(t.age, self.eligibleAnnuityPurchaseAges)
            vals = values(self.annuityfactors, {R});
            annuityfactors = vals{:};
            a = annuityfactors(t);
            gradient(:, end) = 1 / a * gradientJ(:, 2);
        else
            gradient(:, end) = zeros(size(gradientJ, 1), 1);
        end
end

end


function rBondPortfolio = computeBondPortfolioReturn(self, R, t)
vals = values(self.bondPortfolioYieldsNodes, {R});
bondPortfolioYieldsNodes = vals{:};
vals = values(self.bondPortfolioYieldsGrids, {R});
bondPortfolioYieldsGrids = vals{:};
rBondPortfolio = bondPortfolioYieldsNodes(:, t) ./ bondPortfolioYieldsGrids(t);
end
