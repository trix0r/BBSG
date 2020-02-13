function annuityFactor = computeAnnuityFactor(self, age, deferral)
%% NOTE: all annuities are payed with a lag of 1 year,
% i.e., deferral = 0 means that the first payment will occur one year later
% E.g.: self.computeAnnuityFactor(64, 0.02, 0) is the price of an
% immediate annuity bought at age 64 with first payoff in age 65

r = self.Return.riskfreeRate;
tau = (deferral + self.Time.ageStep : self.Time.ageStep : (self.annuity.endAge - age))';
tpx = arrayfun(@(t) self.annuity.computeCumulatedSurvivalProbability(age, t, self.Time.ageStep, ...
                                                                     'female'), ...
                    (age + deferral + self.Time.ageStep : self.Time.ageStep : self.annuity.endAge));
annuityFactor = sum(exp(-r .* tau) .* tpx', 1);

end
