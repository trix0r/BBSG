function annuityFactor = computeAnnuityFactor(self, age, shortRate, deferral)
%% NOTE: all annuities are payed with a lag of 1 year,
% i.e., deferral = 0 means that the first payment will occur one year later
% E.g.: self.computeAnnuityFactor(64, 0.02, 0) is the price of an
% immediate annuity bought at age 64 with first payoff in age 65

tau = (deferral + self.Time.ageStep : self.Time.ageStep : (self.annuity.endAge - age))';
y   = self.computeSpotRates(shortRate, self.Interest.kappa, self.Interest.theta, ...
                            self.Interest.sigma, self.Interest.lambda, tau, self.Interest.model);
tau = repmat(tau, 1, length(shortRate))';
tpx = arrayfun(@(t) self.annuity.computeCumulatedSurvivalProbability(age, t, self.Time.ageStep, ...
                                                                     'female'), ...
                    (age + deferral + self.Time.ageStep : self.Time.ageStep : self.annuity.endAge));
r   = permute(y, [1 3 2]);
annuityFactor = exp(-r .* tau) * tpx';

end
