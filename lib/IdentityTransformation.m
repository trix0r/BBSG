classdef IdentityTransformation
    methods
        function trafo = map(~, X)
            trafo = X;
        end

        function inv = inv(~, X)
            inv = X;
        end

        function deriv = deriv(~, X)
            % if this transformation is used for more than 1 dimension
            if size(X, 2) > 1
                deriv = zeros(size(X, 1), size(X, 2), size(X, 2));
                for k = 1:size(X, 1)
                    deriv(k, :, :) = diag(ones(size(X, 2)));
                end
            else
                deriv = ones(size(X));
            end
        end
    end
end
