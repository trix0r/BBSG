function [x, w] = sgQuadLognorm(n, mu, cov)
%SGQUADLOGNORM Computes nodes and weights for multivariate lognormal 
%distribution using sparse grids and Gauss-Hermite quadrature
% USAGE
%   [x, w] = sgQuadLognorm(n, mu, cov);
% INPUTS
%   n   : 1 by d array of number of refinements
%   mu  : 1 by d mean array [optional]
%         Default: zeros(1,d)
%   var : d by d positive definite covariance matrix [optional]
%         Default: diag(diag(ones(d,d))),
% OUTPUTS
%   x   : matrix of evaluation nodes
%   w   : array of quadrature weights
% 
% To compute expectation of f(x), where x is LogN(mu,cov), write a
% function f that returns m-array of values when passed an m by d
% matrix, and write [x, w] = sgQuadLognorm(n, mu, cov); E[f] = w' * f(x);
%
% USES: sgQuadNorm

if nargin < 1
    error('Please provide a 1 by d array of number of refinements!');
end

if nargin < 3
    [x, w] = sgQuadNorm(n, mu);
    if nargin < 2
        [x, w] = sgQuadNorm(n);
    end
else
    [x, w] = sgQuadNorm(n, mu, cov);
end

x = exp(x);

end

