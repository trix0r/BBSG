function loadParameter(self, varargin)

%% parse input arguments
parser = inputParser();
parser.addParameter('numberOfStocks',          []);
parser.addParameter('baseLevel',               []);
parser.addParameter('policyBaseLevel',         []);
parser.addParameter('gridType',                'regular');
parser.addParameter('refineTolerance',         inf);
parser.addParameter('gradientRefineTolerance', inf);
parser.addParameter('policyRefineTolerance',   inf);
parser.addParameter('useGradients',            true);
parser.addParameter('gradientStateNames',      {});
parser.addParameter('BsplineDegree',           3);
parser.addParameter('optimizer',               'snopt');
parser.parse(varargin{:});
args = parser.Results;

self.numberOfStocks    = args.numberOfStocks;
self.allowBorrowing    = false;
self.enableIncome      = false;
uncertainSurvival      = false;

checkNotEmpty('args', {'numberOfStocks', 'baseLevel', 'policyBaseLevel', ...
               'refineTolerance', 'gradientRefineTolerance', 'policyRefineTolerance'});
assert(self.numberOfStocks <= 5, ...
       ['Invalid value for numberOfStocks. Only up to five stocks supported. ' ...
        'Inherit from this class and override loadParameter.']);

%% path and dependencies
self.loadParameter@LifecycleProblem;

%% risk aversion, EIS, narrow framing strength, discount
self.riskAversion = -2.5;
self.elasticityOfIntertemporalSubstitution = self.riskAversion;
self.narrowFramingStrength = zeros(self.numberOfStocks, 1);
self.discountFactor = 0.97;

%% Basis type
self.Basis.linearType    = 'linear-boundary';
if args.BsplineDegree > 1
    self.Basis.BsplineType = 'lagrange-notaknot-spline-boundary';
else
    self.Basis.BsplineType = 'bspline-boundary';
end
self.Basis.enableUP      = true;
self.Basis.BsplineDegree = args.BsplineDegree;

%% Names of State/Policy Variables
self.stateNames  = sprintfc('SF%i', 1 : self.numberOfStocks);
self.discreteStateNames = {'Alive'};
self.policyNames = [sprintfc('DeltaNormNormS%iBuy', 1 : self.numberOfStocks), ...
                    sprintfc('DeltaNormNormS%iSell', 1 : self.numberOfStocks), ...
                    {'normNormB'}];
self.gradientStateNames = args.gradientStateNames;

% minimum consumption
self.minConsumption = 0.001;

%% grids
% wealth and permanent income grid
self.Grid.lowerBounds = zeros(1, self.numberOfStocks);
self.Grid.upperBounds = ones(1, self.numberOfStocks);

identityTrafo = [];

% value function grid
self.Grid.J.Alive.DomainTrafo = identityTrafo;
self.Grid.J.Alive.ValueTrafo  = identityTrafo;
self.Grid.J.Alive.base = SgppInterpolant( ...
                            self.Basis.linearType, ...
                            args.gridType, ...
                            self.numberOfStates, ...
                            args.baseLevel, ...
                            [], ...
                            self.Grid.lowerBounds, ...
                            self.Grid.upperBounds, ...
                            [], ...
                            'linear', ...
                            1e-5, ...
                            self.Grid.J.Alive.DomainTrafo, ...
                            self.Grid.J.Alive.ValueTrafo ...
                            );
self.Grid.J.Alive.resetGridOnRefine = true; 
self.Grid.J.Alive.resetTimes        = @(t) true;
self.Grid.J.Alive.maxRefine         = 8;
self.Grid.J.Alive.refineType        = 'surplusvolume';
self.Grid.J.Alive.refineTolerance   = args.refineTolerance;
self.Grid.J.Alive.refineTimes       = @(t) ~isinf(args.refineTolerance);

for q = 1:self.numberOfGradientStates
    gradientStateName = self.gradientStateNames{q};
    self.Grid.gradJ.Alive.(gradientStateName).ValueTrafo = identityTrafo;
    self.Grid.gradJ.Alive.(gradientStateName).base = SgppInterpolant( ...
                self.Basis.linearType, ...
                args.gridType, ...
                self.numberOfStates, ...
                args.baseLevel, ...
                [], ...
                self.Grid.lowerBounds, ...
                self.Grid.upperBounds, ...
                [], ...
                'constant', ...
                1e-5, ...
                self.Grid.J.Alive.base.DomainTrafo, ...
                self.Grid.gradJ.Alive.(gradientStateName).ValueTrafo ...
                );
    self.Grid.gradJ.Alive.(gradientStateName).resetGridOnRefine = true;
    self.Grid.gradJ.Alive.(gradientStateName).resetTimes = @(t) true;
    self.Grid.gradJ.Alive.(gradientStateName).maxRefine = 8;
    self.Grid.gradJ.Alive.(gradientStateName).refineTolerance = args.gradientRefineTolerance;
    self.Grid.gradJ.Alive.(gradientStateName).refineType = 'surplusvolume';
    self.Grid.gradJ.Alive.(gradientStateName).refineTimes = ...
            @(t) ~isinf(args.gradientRefineTolerance);
end

for p = 1:self.numberOfPolicies
    policyName = self.policyNames{p};
    self.Grid.Policy.Alive.(policyName).DomainTrafo = identityTrafo;
    self.Grid.Policy.Alive.(policyName).ValueTrafo  = identityTrafo;
    self.Grid.Policy.Alive.(policyName).base = SgppInterpolant( ...
                    self.Basis.linearType, ...
                    args.gridType, ...
                    self.numberOfStates, ...
                    args.policyBaseLevel, ...
                    [], ...
                    self.Grid.lowerBounds, ...
                    self.Grid.upperBounds, ...
                    [], ...
                    'linear', ...
                    1e-5, ...
                    self.Grid.Policy.Alive.(policyName).DomainTrafo, ...
                    self.Grid.Policy.Alive.(policyName).ValueTrafo ...
                    );
    self.Grid.Policy.Alive.(policyName).Basis.type = self.Basis.linearType;
    self.Grid.Policy.Alive.(policyName).Basis.degree = [];
    % set true for Lagrange NAK
    self.Grid.Policy.Alive.(policyName).Basis.enableUP = false;
    self.Grid.Policy.Alive.(policyName).maxRefine = 8;
    self.Grid.Policy.Alive.(policyName).refineType = 'surplusvolume';
    self.Grid.Policy.Alive.(policyName).refineTolerance = args.policyRefineTolerance;
    self.Grid.Policy.Alive.(policyName).refineTimes = @(t) ~isinf(args.policyRefineTolerance);
end

% time grid
self.Time = Time([], 65, 71, 1);

%% return and income parameters and shocks
% return data from Cai/Judd 2010
self.Return.riskfreeRate   = log(1.0408);
self.Return.m              = [0.0572, 0.0638, 0.07, 0.0764, 0.0828];
self.Return.cov            = [0.0256, 0.00576, 0.00288, 0.00176, 0.00096; ...
                              0.00576, 0.0324, 0.0090432, 0.010692, 0.01296; ...
                              0.00288, 0.0090432, 0.04, 0.0132, 0.0168; ...
                              0.00176, 0.010692, 0.0132, 0.0484, 0.02112; ...
                              0.00096, 0.01296, 0.0168, 0.02112, 0.0576];
self.Return.factor = exp(self.Return.riskfreeRate * self.Time.ageStep);

% income data from tables 1, 2, and 4 of Cocco/Gomes/Maenhout 2005
self.Income.replacement   = 0.68212;
self.Income.retirementAge = 65;
if self.enableIncome
    self.Income.Permanent.v  = sqrt(0.0106);
    self.Income.Permanent.G  = @(t) exp(-2.17 + 2.7004 + 0.1682 * t - ...
                                        0.0323 * t.^2 ./10 + ...
                                        0.0020 * t.^3 ./ 100 - log(10));
    self.Income.Transitory.v = sqrt(0.0738);
    self.Income.Transitory.m = -0.5 * self.Income.Transitory.v^2;
    self.Income.Permanent.m  = -0.5 * self.Income.Permanent.v^2;
    self.Income.cov = [self.Income.Permanent.v^2, 0;
                       0, self.Income.Transitory.v^2];
    % integration nodes for return and permanent income shocks
    self.numberOfShocks = self.numberOfStocks + 2;
    if self.numberOfStocks > 1
        tmp = 3;
    else
        tmp = 6;
    end
    n = [ones(1, self.numberOfStocks) * tmp, 2, 2];
    m = [self.Return.m(1 : self.numberOfStocks), ...
         self.Income.Permanent.m, ...
         self.Income.Transitory.m] * ...
        self.Time.ageStep;
    s = [self.Return.cov(1 : self.numberOfStocks, 1 : self.numberOfStocks), ...
         zeros(self.numberOfStocks, 2); ...
        zeros(2, self.numberOfStocks), self.Income.cov] * self.Time.ageStep;
else
    self.Income.Permanent.v  = 0;
    self.Income.Permanent.G  = @(t) 0;
    self.Income.Transitory.v = 0;
    self.Income.Transitory.m = 0;
    self.Income.Permanent.m  = 0;
    self.Income.cov = zeros(2);
    self.numberOfShocks = self.numberOfStocks;
    if self.numberOfStocks > 1
        tmp = 3;
    else
        tmp = 8;
    end
    n = ones(1, self.numberOfStocks) * tmp;
    m = self.Return.m(1 : self.numberOfStocks) * self.Time.ageStep;
    s = self.Return.cov(1 : self.numberOfStocks, 1 : self.numberOfStocks) * ...
        self.Time.ageStep;
end
[x, w] = sgQuadLognorm(n, m, s);
self.Int.nodes   = x;
self.Int.weights = w;

%% transaction costs
self.linearTransactionCosts = 0.01;

%% discrete state transistion probalities (mortality table)
if uncertainSurvival
    load('us_pop_mortality_2009.mat', 'age_data', 'fom_data'); %#ok<UNRCH>
    m       = [age_data fom_data];
    % extrapolation of mortatilities (if needed)
    e       = [(length(m)-1 : 1 : self.Time.ageStop-1)'... 
        repmat(m(end - 1, 2 : 3), self.Time.ageStop - length(m) + 1, 1)];
    me      = [m(1 : end - 1, :); e]; % extrapolated mortatlities
    % survival probabilities, only femals so far
    sp      = 1 - me(self.Time.ageStart : self.Time.ageStop, 2);
    sp(end) = 0;
    n = 2;
    self.transitionMatrix = permute(reshape([sp, 1-sp, zeros(size(sp)), ...
                                    ones(size(sp))],[], n, n), [1 3 2]);
else
    self.transitionMatrix = ones(self.Time.getStop().index, 1, 1);
end

%% choose optimizer between fmincon, NPSOL, and SNOPT
self.Optimizer.routine = args.optimizer;
self.Optimizer.useGradients   = args.useGradients;
self.Optimizer.checkGradients = false;
self.Optimizer.tolCon  = 1e-6;
self.Optimizer.tolFun  = sqrt(eps);
self.Optimizer.maxIter = 100;
self.Optimizer.printLevel = 0;
self.Optimizer.printTimes = false;
self.Optimizer.noOfMultiStartPoints = 64;

%% Euler error computation
[points, weights] = self.constructErrorPoints();

emptyEulerError.names = {'normNormB', 'normNormB, weighted'};
emptyEulerError.points = points;
emptyEulerError.weights = weights;
self.EulerError = repmat(emptyEulerError, 1, numel(self.Time.getRange()) - 1);

end
