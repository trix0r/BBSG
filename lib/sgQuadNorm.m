function [x, w] = sgQuadNorm(n, mu, cov)
%SGQUADNORM Computes nodes and weights for multivariate normal distribution
%using sparse grids and Gauss-Hermite quadrature
% USAGE
%   [x, w] = sgQuadNorm(n, mu, cov);
% INPUTS
%   n   : 1 by d array of number of refinements
%   mu  : 1 by d mean array [optional]
%         Default: zeros(1,d)
%   var : d by d positive definite covariance matrix [optional]
%         Default: diag(diag(ones(d,d)))
% OUTPUTS
%   x   : matrix of evaluation nodes
%   w   : array of quadrature weights
%
% To compute expectation of f(x), where x is N(mu,cov), write a
% function f that returns m-array of values when passed an m by d
% matrix, and write [x, w] = sgQuadNorm(n, mu, cov); E[f] = w' * f(x);
%
% USES: tsgMakeQuadrature

if nargin < 1
    error('Please provide a 1 by d array of number of refinements!');
end
dim    = length(n);

% set default arguments
if nargin < 3
    cov = eye(dim);
    if nargin < 2
        mu = zeros(1, dim);
    end
end


% set tensor
tensor = 'level';

% set type
type = 'gauss-hermite';

% calculate anistropic weights from refinements per dimension
if dim == 1
    refine = [];
else
    refine  = (1 ./ n * prod(n))';
end
level   = max(n);

[w, x]  = tsgMakeQuadrature( ...
                            uint32(dim), ...    % dimension
                            uint32(level), ...  % max refinements for any dimension
                            tensor, ...         % tensor selection type 
                            type, ...           % quadrature method
                            int32(refine), ...  % anisotripc refinements per dimension
                            0.0, ...            % alpha = 0 for Gauss-Hermite
                            [], ...             % beta -- not used here
                            [], ...             % integral boundaries
                            [] ...
                            );

% transformation from Gauss-Hermite nodes and weights to normal nodes and weights
x = repmat(mu, size(x, 1), 1) + sqrt(2) * x * chol(cov);
w = pi^(-dim / 2) * w;

end

