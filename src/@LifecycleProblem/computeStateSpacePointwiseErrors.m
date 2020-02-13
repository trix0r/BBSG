function errors = computeStateSpacePointwiseErrors(self, interpFctTarget, interpFctReal, times)

if nargin < 4
    times = self.Time.getRange();
    times = times(1:end-1);
end

emptyError = conStruct({'All', 'L1', 'L2', 'Max'});
errors = repmat(emptyError, numel(self.Time.getRange()) - 1, 1);

parfor r = 1:numel(times)
    t = times(r);
    for q = 1:self.numberOfDiscreteStates %#ok<PFBNS>
        discreteStateName = self.discreteStateNames{q};
        err = getPointwiseError(self.EulerError(t).points, discreteStateName, t, ...
                                 interpFctTarget, interpFctReal);

        errors(r).All = err;
        % l1 error
        errors(r).L1 = nanmean(abs(err));
        % l2 error
        errors(r).L2 = sqrt(nanmean(err.^2));
        % max error
        errors(r).Max = nanmax(abs(err));
    end
end

try
    save([self.Env.outdir filesep 'pointwise_errors.mat'], 'self', ...
        'interpFctTarget', 'interpFctReal', 'times', 'errors');
catch
    warning('Couldn''t save pointwise_errors.mat.');
end

end

function err = getPointwiseError(state, discreteState, t, ...
                                 interpFctTarget, interpFctReal)

target   = interpFctTarget{t}.(discreteState).evaluate(state);
realized = interpFctReal{t}.(discreteState).evaluate(state);

err = zeros(length(state), 2);

err(:, 1) = target - realized;
err(:, 2) = (target - realized) ./ target;

end
