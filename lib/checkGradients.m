function checkGradients(fun, numberOfArguments, argumentNoValue, argumentNoGradient, lb, ub)

seed = 1;
NN = 1000;
h = 1e-8;

d = numel(lb);
rng(seed);
XX = bsxfun(@plus, lb, bsxfun(@times, rand(NN, d), ub - lb));

errors = nan(NN, 1);
gradients = nan(NN, d);
gradientApprs = nan(NN, d);

parfor i = 1:NN
    x = XX(i,:);
    output = cell(1, numberOfArguments);
    [output{:}] = fun(x); %#ok<PFBNS>
    value    = output{argumentNoValue};
    gradient = output{argumentNoGradient};

    if ~isreal(value) || ~isreal(gradient)
        continue;
    end

    gradientAppr = nan(size(gradient));

    for t = 1:d
        e = zeros(1, d);
        e(t) = 1;

        xl = XX(i,:) - h * e;
        xr = XX(i,:) + h * e;

        if xl(t) < lb(t) %#ok<PFBNS>
            [output{:}] = fun(xr);
            valueR = output{argumentNoValue};
            gradientAppr(t) = (valueR - value) / h;
        elseif xr(t) > ub(t) %#ok<PFBNS>
            [output{:}] = fun(xl);
            valueL = output{argumentNoValue};
            gradientAppr(t) = (value - valueL) / h;
        else
            [output{:}] = fun(xl);
            valueL = output{argumentNoValue};
            [output{:}] = fun(xr);
            valueR = output{argumentNoValue};
            gradientAppr(t) = (valueR - valueL) / (2 * h);
        end
    end

    error = norm(gradient - gradientAppr) / norm(gradient);

    errors(i) = error;
    gradients(i,:) = gradient;
    gradientApprs(i,:) = gradientAppr;
end

K = ~isnan(errors);
errors = errors(K);
gradients = gradients(K,:);
gradientApprs = gradientApprs(K,:);
XX = XX(K,:);

[errors, K] = sort(errors, 'descend');
gradients = gradients(K,:);
gradientApprs = gradientApprs(K,:);
XX = XX(K,:);

formatStrScalar = '%+.15f';
formatStrVector = ['%+.15f', repmat(' %+.15f', 1, d-1)];

for i = 1:5
    fprintf('Point no. %u\n', i);
    fprintf(['x = [' formatStrVector ']\n'], XX(i,:));
    fprintf(['Given gradient = [' formatStrVector ']\n'], gradients(i,:));
    fprintf(['Appr. gradient = [' formatStrVector ']\n'], gradientApprs(i,:));
    fprintf(['Error = ' formatStrScalar '\n'], errors(i));
    fprintf('\n');
end
