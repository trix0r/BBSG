function [ spotRatesDistribution, bondPrice ] = computeSpotRates(...
    shortRateDistribution, ...
    kappa, ...
    theta, ...
    sigma, ...
    lambda, ...
    tau, ...
    model)


switch lower(model)
    case 'cir'
        aFun = @aFunCir;
        bFun = @bFunCir;
    case 'vasicek'
        aFun = @aFunVasicek;
        bFun = @bFunVasicek;
    otherwise
        error('Interest rate model not supported!');
end

n       = size(shortRateDistribution, 1); %no of factors
lt      = size(shortRateDistribution, 3);
ltau    = length(tau);

% compute Q parameters
theta = kappa ./ (kappa + lambda) .* theta;
kappa = kappa + lambda;

r   = permute(repmat(shortRateDistribution, [1, 1, 1, ltau]), [2 1 3 4]);
a   = permute(repmat(aFun(tau, kappa, theta, sigma, n), [1, 1, 1, lt]), ...
              [2 3 4 1]);
b   = permute(repmat(bFun(tau, kappa, sigma, n), [1, 1, 1, lt]), ...
              [2 3 4 1]);
tau = permute(repmat(repmat(tau, [1, n]), [1, 1, lt]), [2 3 1]);

bondPrice = shiftdim(sum(a, 1), 1) .* exp(-shiftdim(sum(b .* r, 1), 1));
spotRatesDistribution = -log(bondPrice) ./ tau ;

end

function [ a ] = aFunCir(tau, kappa, theta, sigma, n)

nt    = length(tau);
k     = length(kappa);

tau   = repmat(tau, 1, k);

gamma  = repmat(sqrt(kappa.^2 + 2 * sigma.^2), nt, 1);
kappa  = repmat(kappa, nt, 1);
theta  = repmat(theta, nt, 1);
sigma  = repmat(sigma, nt, 1);

a = ((2 * gamma .* exp((kappa + gamma) .* tau / 2) ...
    ./ ((kappa + gamma) .* (exp(gamma .* tau) - 1) + 2 * gamma))).^ ...
    (2 * kappa .* theta ./ sigma.^2);

% dirty hack: set a = 1 for all values where sigma_i == 0 by setting
% kappa_i = 0 and sigma_i = 1
a(sigma == 0) = 1;

a = repmat(a, [1, 1, n]);

end

function [ a ] = aFunVasicek(tau, kappa, theta, sigma, n)

nt    = length(tau);
k     = length(kappa);

tau   = repmat(tau, 1, k);

gamma  = repmat(theta - sigma.^2 ./ (2 * kappa.^2), nt, 1);
kappa  = repmat(kappa, nt, 1);
sigma  = repmat(sigma, nt, 1);

b = 1 ./ kappa .* (1 - exp(-kappa .* tau));
a = exp(gamma .* (b - tau) - sigma.^2 .* b.^2 ./ (4 * kappa));

% dirty hack: set a = 1 for all values where sigma_i == 0 by setting
% kappa_i = 0 and sigma_i = 1
a(sigma == 0) = 1;

a = repmat(a, [1, 1, n]);

end

function [ b ] = bFunCir(tau, kappa, sigma, n)

nt    = length(tau);
k     = length(kappa);

tau   = repmat(tau, 1, k);

gamma  = repmat(sqrt(kappa.^2 + 2 * sigma.^2), nt, 1);
kappa  = repmat(kappa, nt, 1);
sigma  = repmat(sigma, nt, 1);

b = 2 * (exp(gamma .* tau) - 1) ./ ...
    ((kappa + gamma) .* (exp(gamma .* tau) - 1) + 2 * gamma);

% dirty hack: set b = 1 for all values where sigma_i == 0 by setting
% kappa_i = 0 and sigma_i = 1
b(sigma == 0) = tau(sigma == 0);

b = repmat(b, [1, 1, n]);

end

function [ b ] = bFunVasicek(tau, kappa, sigma, n)

nt    = length(tau);
k     = length(kappa);

tau   = repmat(tau, 1, k);

kappa  = repmat(kappa, nt, 1);
sigma  = repmat(sigma, nt, 1);

b = 1 ./ kappa .* (1 - exp(-kappa .* tau));

% dirty hack: set b = 1 for all values where sigma_i == 0 by setting
% kappa_i = 0 and sigma_i = 1
b(sigma == 0) = tau(sigma == 0);

b = repmat(b, [1, 1, n]);

end