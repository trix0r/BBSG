classdef RootTransformation
    properties
        exponent
    end

    methods
        function self = RootTransformation(exponent)
            self.exponent = exponent;
        end

        function trafo = map(self, X)
            trafo = X.^(1 / self.exponent);
        end

        function inv = inv(self, X)
            inv = X.^(self.exponent);
        end

        function deriv = deriv(self, X)
            % if this transformation is used for more than 1 dimension
            if size(X, 2) > 1
                deriv = zeros(size(X, 1), size(X, 2), size(X, 2));
                for k = 1:size(X, 1)
                    deriv(k, :, :) = diag(1 / self.exponent * X(k, :).^((1 - self.exponent) ...
                                                                        / self.exponent));
                end
            else
                deriv = 1 / self.exponent * X.^((1 - self.exponent) / self.exponent);
            end
        end
    end
end
