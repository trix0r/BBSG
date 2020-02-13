classdef SquareTransformation < handle
    %% SquareTransformation
    % This is a value transformation that is applied to the function values before interpolation and
    % inverted afterwards.
    % Intented to be applied to all dimensions at once.
    % DO NOT USE AS GRID TRAFO VIA SimpleGridTransformation
    methods
        function trafo = map(~, X)
            trafo = X.^2;
        end

        function inv = inv(~, X)
            inv = sqrt(X);
        end

        function deriv = deriv(~, X)
            % if this transformation is used for more than 1 dimension
            if size(X, 2) > 1
                deriv = zeros(size(X, 1), size(X, 2), size(X, 2));
                for k = 1:size(X, 1)
                    deriv(k, :, :) = diag(2 * X(k, :));
                end
            else
                deriv = 2 * X;
            end
        end
    end
end
