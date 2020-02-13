function errors = computeStateSpaceEulerErrors(self, solution, interpPolicy, times)

if nargin < 4
    times = self.Time.getRange();
    times = times(1:end-1);
end

emptyError = conStruct({'All', 'L1', 'L2', 'Max'});
errors = repmat(emptyError, numel(self.Time.getRange()) - 1, 1);

if isfield(self.EulerError, 'names')
    noOfErrs = numel(self.EulerError(1).names);
else
    noOfErrs = self.numberOfPolicies;
end

parfor r = 1:numel(times)
    t = times(r);
    for q = 1:self.numberOfDiscreteStates %#ok<PFBNS>
        discreteStateName = self.discreteStateNames{q};
        err = nan(size(self.EulerError(t).points, 1), noOfErrs);
        for i = 1:size(self.EulerError(t).points, 1)
            err(i, :) = self.getEulerErrors(self.EulerError(t).points(i, :), discreteStateName, ...
                                            t, solution, interpPolicy);
        end

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
    save([self.Env.outdir filesep 'euler_errors.mat'], 'self', ...
         'interpPolicy', 'times', 'errors');
catch
    warning('Couldn''t save euler_errors.mat.');
end

end
