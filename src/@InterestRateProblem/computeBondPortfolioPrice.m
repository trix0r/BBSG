function portfolioPrice = computeBondPortfolioPrice(self, age, shortRate, deferral)
%% THIS IS THE SAME AS THE ANNUITY FACTOR BUT WITHOUT MORTALITIES
% NOTE: all annuities are payed with a lag of 1 year,
% i.e., deferral = 0 means that the first payment will occur one year later
% E.g.: self.computeBondPortfolioPrice(64, 0.02, 0) is the price of an
% immediate annuity bought at age 64 with first payoff in age 65

if age == self.Time.ageStop
    portfolioPrice = zeros(size(shortRate));
else
    tau = (deferral + self.Time.ageStep : self.Time.ageStep : (self.Time.ageStop - age))';
    y   = self.computeSpotRates(shortRate, self.Interest.kappa, self.Interest.theta, ...
                                self.Interest.sigma, self.Interest.lambda, tau, ...
                                self.Interest.model);
    tau = repmat(tau, 1, length(shortRate))';
    r   = permute(y, [1 3 2]);
    portfolioPrice = exp(-r .* tau) * ones(size(tau, 2), 1);
end

end
