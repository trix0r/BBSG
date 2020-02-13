function optStockFractions = computeMertonPoint(self)

ns = self.numberOfStocks;
sigma = self.Return.cov(1:ns, 1:ns);
mu = self.Return.m(1:ns);
rf = self.Return.riskfreeRate;
gamma = self.riskAversion;

% Merton (1969) solution; not normalized w/ regard to overall stock share in portfolio with ns
% stocks and one bond.
optStockFractions = (mu - rf) * sigma^-1 / (1 - gamma);
