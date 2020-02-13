classdef SimpleGridTransformation
    %% SimpleGridTransformation
    % SimpleGridTransformation objects let you combine simple 1D grid transformations to an nD grid
    % transformation $\vect{t}$ of the type $\vec{t}(\vec{x}), \mathbb{R}^d \mapsto \mathbb{R}^{d
    % \times d}$, which fullfills $\left(\partial t_j / \partial x_i\right)_{i,j} = 0$ for $i \neq
    % j$; i.e., only transformations that are applied to each dimension idenpendently

    properties
        trafos
    end

    properties (Dependent)
        dim
    end

    methods
        function self = SimpleGridTransformation(varargin)
            % pass a cell array of grid transformations as input
            self.trafos = varargin{:};
        end

        function trafo = map(self, X)
            % size(X, 1) must be equal to numel(trafo)
            numberOfEntries = size(X, 1);
            trafo = zeros(numberOfEntries, self.dim);
            for i = 1:self.dim
                trafo(:, i) = self.trafos{i}.map(X(:, i));
            end
        end

        function inv = inv(self, X)
            % size(X, 1) must be equal to numel(trafo)
            numberOfEntries = size(X, 1);
            inv = zeros(numberOfEntries, self.dim);
            for i = 1:self.dim
                inv(:, i) = self.trafos{i}.inv(X(:, i));
            end
        end

        function deriv = deriv(self, X)
            numberOfEntries = size(X, 1);
            selfDeriv = zeros(numberOfEntries, self.dim);
            deriv = zeros(numberOfEntries, self.dim, self.dim);
            for i = 1:self.dim
                selfDeriv(:, i) = self.trafos{i}.deriv(X(:, i));
            end
            for k = 1:numberOfEntries
                deriv(k, :, :) = diag(selfDeriv(k, :));
            end
        end

        function value = get.dim(self)
            value = numel(self.trafos);
        end
    end
end
