classdef LogTransformation
    properties
        shift
    end

    methods
        function self = LogTransformation(shift)
            if nargin < 1; self.shift = 0; else; self.shift = shift; end
        end

        function trafo = map(self, X)
            trafo = log(X + self.shift);
        end

        function inv = inv(self, X)
            inv = exp(X) - self.shift;
        end

        function deriv = deriv(self, X)
            % if this transformation is used for more than 1 dimension
            if size(X, 2) > 1
                deriv = zeros(size(X, 1), size(X, 2), size(X, 2));
                for k = 1:size(X, 1)
                    deriv(k, :, :) = diag(1 ./ (X(k, :) + self.shift));
                end
            else
                deriv = 1 ./ (X + self.shift);
            end
        end
    end
end
