function [J, optPolicy, lambda, Info] = ...
    computeOptimalPolicy(self, previousSolution, state, discreteState, t, writeLog)

if ~exist('writeLog', 'var') || isempty(writeLog)
    writeLog = true;
end

x0 = self.getOptimizationStartPolicy(state, discreteState, t);
[A, b, Aeq, beq, lb, ub, nonlcon] = self.getConstraints(state, discreteState, t);
options = self.getOptimizerOptions(state, discreteState, t);

user.self = self;
user.previousSolution = previousSolution;
user.state = state;
user.discreteState = discreteState;
user.t = t;
user.Info = conStruct({'Time', 'Calls'}, conStruct({'J', 'gradJ'}, 0));
user.Info.Calls.Evaluate = conStruct({'J', 'gradJ'}, 0);

time_optimizer = tic();
switch lower(self.Optimizer.routine)
    case 'fmincon'
        [opt, optPolicies, lambda, status, user] = ...
                runFmincon(self, x0, user, A, b, Aeq, beq, lb, ...
                           ub, nonlcon, options);
        fail = (status < 1);
    case 'patternsearch'
        [opt, optPolicies, lambda, status, user] = ...
                runPatternsearch(self, x0, user, A, b, Aeq, beq, lb, ...
                           ub, nonlcon, options);
        fail = (status < 1);
    case 'npsol'
        [opt, optPolicies, lambda, status, user] =...
                runNpsol(self, x0, user, A, b, Aeq, beq, lb, ...
                         ub, nonlcon, options);
        fail = (status ~= 0);
     case 'snopt'
        [opt, optPolicies, lambda, status, user] =...
                runSnopt(self, x0, user, A, b, Aeq, beq, lb, ...
                         ub, nonlcon, options);
        fail = (status ~= 0);
    otherwise
        error('Unsupported optimizer chosen!')
end
Info = user.Info;
Info.Time.optimizer = toc(time_optimizer);
Info.status = status;

if self.Optimizer.printTimes
    fprintf('%6.2fs %2.0f%% %2.0f%% %2.0f%% %4u %5.1fms %4u %5.1fms\n', ...
            Info.Time.optimizer, ...
            100 * (Info.Time.J) / Info.Time.optimizer, ...
            100 * (Info.Time.gradJ / Info.Time.optimizer), ...
            100 * (Info.Time.optimizer - Info.Time.J - Info.Time.gradJ) / Info.Time.optimizer, ...
            Info.Calls.J, 1e3 * Info.Time.J / Info.Calls.J, ...
            Info.Calls.gradJ, 1e3 * Info.Time.gradJ / Info.Calls.gradJ);
end



if fail
    if writeLog
        id = datestr(now(), 'yyyymmddTHHMMSSFFF');
        filename = sprintf('%s/plotJ_%s.mat', self.Env.logdir, id);
        if ~exist(self.Env.logdir, 'dir'); mkdir(self.Env.logdir); end
        save(filename, 'status', 'previousSolution', 'state', 'discreteState', 't');
    else
        id = 'N/A';
    end

    format = sprintf('%%18s %%4u  %%6s  %s\n', strtrim(repmat('%8.5f ', 1, self.numberOfStates)));
    stateCell = num2cell(state);
    fprintf(format, id, status, discreteState, stateCell{:});
end

J = -opt;
optPolicy = struct();
for q = 1:self.numberOfPolicies
    policyName = self.policyNames{q};
    optPolicy.(policyName) = optPolicies(q);
end

end

function [opt, optPolicies, lambda, status, user] = ...
    runNpsol(self, x0, user, A, b, Aeq, beq, lb, ub, nonlcon, options) %#ok<INUSL>
% TODO: non-linear constraints
confun = 'nag_opt_nlp1_dummy_confun';

a  = [A; Aeq];
bl = [lb, -Inf(size(b)), beq]';
bu = [ub, b, beq]';
cjac   = [];
istate = nag_int([zeros(size(x0)), zeros(size(b)), zeros(size(beq))]');
clamda = [zeros(size(x0)), zeros(size(b)), zeros(size(beq))]';
r      = zeros(numel(x0), numel(x0));
x = x0';

if options{1}
    nag_issue_warnings(true);
    warning('off','NAG:warning');
else
    nag_issue_warnings(false);
end

%Initialize
[cwsav,lwsav,iwsav,rwsav,ifail] = e04wb('e04uc'); %#ok<ASGLU>
for i = 2 : numel(options)
    [lwsav, iwsav, rwsav, inform] = e04ue(options{i}, lwsav, iwsav, rwsav); %#ok<ASGLU>
end
%Solve
[iter, istate, c, cjac, clamda, objf, objgrd, r, x, user, ...
    lwsav, iwsav, rwsav, ifail] = ...
    e04uc(...
    a, bl, bu, confun, @objfunNag, istate, cjac, ...
    clamda, r, x, lwsav, iwsav, rwsav ,...
    'user', user); %#ok<ASGLU>

opt = objf;

optPolicies = x;

lambda.isActive   = istate;
lambda.multiplier = clamda;

status = ifail;

end

function [opt, optPolicies, lambda, status, user] = ...
    runSnopt(self, x0, user, A, b, Aeq, beq, lb, ub, nonlcon, options)
n = nag_int(numel(x0(1, :)));
if ~isempty(nonlcon)
    ncnln = nag_int(numel(nonlcon(x0(1, :), user)));
else
    ncnln = nag_int(0);
end

if ncnln > 0
    confun = @confunNag;
    njnln = n;
    user.nonlcon = nonlcon;
else
    confun = 'nag_opt_nlp1_sparse_dummy_confun';
    njnln = nag_int(0);
    user.nonlcon = [];
end

m = nag_int(size([A; Aeq], 1));
nonln = n;
iobj  = nag_int(0);
a     = [A(:); Aeq(:)];
% this can, but does not account for sparsity of A!
[row, col] = ind2sub(size([A; Aeq]), 1:numel(a));
ha = nag_int(row');
if ~isempty(a)
    ka = nag_int([col'; numel(a) + 1]);
else
    ka = nag_int(ones(n + 1, 1));
end
bl = [lb, -Inf(1, ncnln), -Inf(size(b)), beq]';
bu = [ub, zeros(1, ncnln), b, beq]';
start = 'C';
names = {''};
ns = nag_int(0);
istate = nag_int(zeros(1, n + m));
clamda = zeros(1, n + m);

if options{1}
    nag_issue_warnings(true);
    warning('off','NAG:warning');
else
    nag_issue_warnings(false);
end

%Initialize
[cwsav,lwsav,iwsav,rwsav,ifail] = e04wb('e04ug'); %#ok<ASGLU>
for i = 2 : numel(options)
    [lwsav, iwsav, rwsav, inform] = e04uj(options{i}, lwsav, iwsav, rwsav); %#ok<ASGLU>
end

optTmp = zeros(size(x0, 1), 1);
optPoliciesTmp = zeros(size(x0));
statusTmp = zeros(size(x0, 1), 1);
lambdaTmp(size(x0, 1), 1) = struct('isActive', [], 'multiplier', []);

if self.Optimizer.printLevel > 0
    fprintf('Running multistart with %i start points.\n', size(x0, 1));
end

for i = 1 : size(x0, 1)
    xs = [x0(i, :), zeros(1, m)]';

    %Solve
    [a, ns, xs, istate, clamda, miniz, minz, ninf, sinf, obj, user, lwsav, ...
        iwsav, rwsav, ifail] = ...
        e04ug(...
        confun, @objfunNag, n, m, ncnln, nonln, njnln, ...
        iobj, a, ha, ka, bl, bu, start, names, ns, ...
        xs, istate, clamda, lwsav, iwsav, rwsav, ...
        'user', user); %#ok<ASGLU>

    if (ifail == 15 || ifail == 16)
        % Default amount of workspace is insufficient, use values bigger than those
        % returned in minz and miniz
        minz  = 10*minz;
        miniz = 10*miniz;
        [a, ns, xs, istate, clamda, miniz, minz, ninf, sinf, obj, user, lwsav, ...
            iwsav, rwsav, ifail] = ...
            e04ug(...
            confun, @objfunNag, n, m, ncnln, nonln, njnln, ...
            iobj, a, ha, ka, bl, bu, start, names, ns, ...
            xs, istate, clamda, lwsav, iwsav, rwsav, ...
            'lenz', minz, 'leniz', miniz,  ...
            'user', user); %#ok<ASGLU>
    end
    
    optTmp(i) = obj;
    optPoliciesTmp(i, :) = xs(1:end-m);
    lambdaTmp(i).isActive   = istate;
    lambdaTmp(i).multiplier = clamda;
    statusTmp(i) = ifail;
end

% sort results by objective function value (best to worst)
[optTmp, Idx] = sort(optTmp);
optPoliciesTmp = optPoliciesTmp(Idx, :);
lambdaTmp = lambdaTmp(Idx);
statusTmp = statusTmp(Idx);

% index of last objective function value which is approximately equal to the best
% (index should be >= 1, as the best value as error 0)
equalIdx = find(abs((optTmp - optTmp(1)) / optTmp(1)) > 1e-10, 1) - 1;
% search for result with "success" error value
idx = find(statusTmp(1:equalIdx) == 0, 1);
% if not available, choose best index (will have a non-zero error code in this case)
if isempty(idx); idx = 1; end

opt = optTmp(idx);
optPolicies = optPoliciesTmp(idx, :);
lambda = lambdaTmp(idx);
status = statusTmp(idx);

end

function [mode, objf, objgrd, user] = ...
                                objfunNag(mode, n, x, objgrd, nstate, user) %#ok<INUSL>

timer = tic();
if (mode == 1 || mode == 2) && user.self.Optimizer.useGradients
    [Info, J, gradJ] = user.self.getJ(user.previousSolution, x', ...
                                   user.state, user.discreteState, user.t);
    objgrd = -gradJ;
    user.Info.Time.gradJ = user.Info.Time.gradJ + toc(timer);
    user.Info.Calls.gradJ = user.Info.Calls.gradJ + 1;
    user.Info.Calls.Evaluate.gradJ = user.Info.Calls.Evaluate.gradJ + Info.Calls.Evaluate.gradJ;
else
    [Info, J] = user.self.getJ(user.previousSolution, x', ...
                            user.state, user.discreteState, user.t);
    user.Info.Time.J = user.Info.Time.J + toc(timer);
    user.Info.Calls.J = user.Info.Calls.J + 1;
    user.Info.Calls.Evaluate.J = user.Info.Calls.Evaluate.J + Info.Calls.Evaluate.J;
end
objf = -J;

if (mode == 1 || mode == 2) && user.self.Optimizer.useGradients
    if ~isreal(objf) || ~isreal(objgrd)
        objf = nan;
        objgrd = nan(size(objgrd));
    end
else
    if ~isreal(objf)
        objf = nan;
    end
end
end

function [mode, f, fjac, user] = ...
        confunNag(mode, ncnln, njnln, nnzjac, x, fjac, nstate, user) %#ok<INUSL>
if (mode == 1 || mode == 2) && user.self.Optimizer.useGradients
    [f, fjac] = user.nonlcon(x', user);
else
    f = user.nonlcon(policy, user);
end
end


function [opt, optPolicies, lambda, status, user] = ...
    runFmincon(self, x0, user, A, b, Aeq, beq, lb, ub, nonlcon, options)
% assumes that first row of x0 matrix ist default start point in multistart
if isempty(nonlcon)
    myconfun = [];
else
    myconfun = @confun;
end
problem = createOptimProblem('fmincon', ...
                'objective', @objfun, ...
                'x0', x0(1, :), ...
                'Aineq', A, ...
                'bineq', b, ...
                'Aeq', Aeq, ...
                'beq', beq, ...
                'lb', lb, ...
                'ub', ub, ...
                'nonlcon', myconfun, ...
                'options', options);

% ensure backwards compatibility with previous code
if isa(self.Optimizer.noOfMultiStartPoints, 'function_handle')
    noOfMultiStartPoints = self.Optimizer.noOfMultiStartPoints(user.state, user.discreteState, ...
                                                               user.t);
else
    noOfMultiStartPoints = self.Optimizer.noOfMultiStartPoints;
end

if noOfMultiStartPoints > 0
    if size(x0, 1) > 1
        startPoints = CustomStartPointSet(x0);
    else
        startPoints = RandomStartPointSet('NumStartPoints', noOfMultiStartPoints);
    end
    ms = MultiStart('StartPointsToRun', 'bounds-ineqs', ...
                    'TolFun', options.TolFun, ...
                    'TolX', options.TolX, ...
                    'Display', options.Display);
    [optPolicies, opt, status, Info.output, solutions] = ...
        run(ms, problem, startPoints); %#ok<ASGLU>
else
    [optPolicies, opt, status, Info.output, lambda] = fmincon(problem); %#ok<ASGLU>
end

%TODO map this to isActive and multiplier
% lambda(k) = struct('lower', [], 'upper', [], 'ineqlin', [], ...
%                    'eqlin', [], 'ineqnonlin', [], 'eqnonlin', []);
tmp.isActive = [];
tmp.multiplier = [];
lambda = tmp;

    function [J, varargout] = objfun(policy)
        timer = tic();
        if strcmp(options.GradObj, 'on')
            [Info, J, gradJ]   = self.getJ(user.previousSolution, policy, ...
                                        user.state, user.discreteState, user.t);
            user.Info.Time.gradJ = user.Info.Time.gradJ + toc(timer);
            user.Info.Calls.gradJ = user.Info.Calls.gradJ + 1;
            varargout{1} = -gradJ;
            user.Info.Calls.Evaluate.gradJ = user.Info.Calls.Evaluate.gradJ + ...
                                             Info.Calls.Evaluate.gradJ;
        else
            [Info, J] = self.getJ(user.previousSolution, policy, ...
                                  user.state, user.discreteState, user.t);
            user.Info.Time.J = user.Info.Time.J + toc(timer);
            user.Info.Calls.J = user.Info.Calls.J + 1;
            user.Info.Calls.Evaluate.J = user.Info.Calls.Evaluate.J + Info.Calls.Evaluate.J;
        end
        J = -J;
    end

    function [con, coneq, varargout] = confun(policy)
        coneq = [];

        if strcmp(options.GradConstr, 'on')
            [con, varargout{1}] = nonlcon(policy, user);
            varargout{2} = [];
        else
            con = nonlcon(policy, user);
        end
    end
end


function [opt, optPolicies, lambda, status, user] = ...
    runPatternsearch(self, x0, user, A, b, Aeq, beq, lb, ub, nonlcon, options)
fun     = @objfun;

% TODO: non-linear constraints

[optPolicies, opt, status, ~] = ...
    patternsearch(fun, x0, A, b, Aeq, beq, lb, ub, nonlcon, options);

tmp.isActive = [];
tmp.multiplier = [];
lambda = tmp;

    function J = objfun(policy)
            timer = tic();
            [Info, J] = self.getJ(user.previousSolution, policy, user.state, ...
                          user.discreteState, user.t);
            user.Info.Time.J = user.Info.Time.J + toc(timer);
            user.Info.Calls.J = user.Info.Calls.J + 1;
            user.Info.Calls.Evaluate.J = user.Info.Calls.Evaluate.J + Info.Calls.Evaluate.J;
            J = -J;
    end
end
