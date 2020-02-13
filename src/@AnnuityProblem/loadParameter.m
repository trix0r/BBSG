function loadParameter(self, varargin)

%% parse input arguments
parser = inputParser();
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
parser.addParameter('domainTrafo',             []);
parser.addParameter('policyDomainTrafo',       []);
parser.addParameter('EIS',                     -4);
parser.parse(varargin{:});
args = parser.Results;

checkNotEmpty('args', {'baseLevel', 'policyBaseLevel', ...
               'refineTolerance', 'gradientRefineTolerance', 'policyRefineTolerance'});

%% path and dependencies
self.loadParameter@LifecycleProblem;

%% risk aversion, EIS, narrow framing strength, discount
self.riskAversion = -4;
self.elasticityOfIntertemporalSubstitution = args.EIS;
self.narrowFramingStrength = 0;
self.discountFactor = 0.96;

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
self.stateNames  = {'normW', 'normL'};
self.discreteStateNames = {'Alive'};
self.policyNames = {'normS', 'normB', 'normA'};
self.gradientStateNames = args.gradientStateNames;

% minimum consumption
self.minConsumption = 0.001;

%% grids
% wealth grid
self.Grid.lowerBounds = [0.02, 0];
self.Grid.upperBounds = [40, 20];

% grid transformations
identityTrafo = [];
if isempty(args.domainTrafo)
    domainTrafo = identityTrafo;
else
    domainTrafo = SimpleGridTransformation(args.domainTrafo);
end
% value function grid
self.Grid.J.Alive.DomainTrafo = domainTrafo;
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
self.Grid.J.Alive.refineType        = 'surplus';
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
    self.Grid.gradJ.Alive.(gradientStateName).refineType = 'surplus';
    self.Grid.gradJ.Alive.(gradientStateName).refineTimes = ...
            @(t) ~isinf(args.gradientRefineTolerance);
end

identityTrafo = [];
if isempty(args.domainTrafo)
    policyDomainTrafo = identityTrafo;
elseif ~isempty(args.policyDomainTrafo)
    policyDomainTrafo = args.policyDomainTrafo;
else
    policyDomainTrafo = domainTrafo;
end
for p = 1:self.numberOfPolicies
    policyName = self.policyNames{p};
    self.Grid.Policy.Alive.(policyName).DomainTrafo = policyDomainTrafo;
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
self.Time = Time([], 20, 100, 1);

%% return and income parameters and shocks
% return data from Cai/Judd 2010
self.Return.riskfreeRate   = log(1.02);
self.Return.m              = 0.06;
self.Return.cov            = 0.18^2;
self.Return.factor = exp(self.Return.riskfreeRate * self.Time.ageStep);

% income data from tables 1, 2, and 4 of Cocco/Gomes/Maenhout 2005
self.Income.replacement = 0.68212;
self.Income.retirementAge = 65;
self.Income.Permanent.G = @(t) exp(2.7004 - 2.17 + 0.1682 * t - 0.0323 * t.^2 ./10 + ...
                                    0.0020 * t.^3 ./ 100 - log(10));
self.Income.Permanent.v  = sqrt(0.0106);
self.Income.Transitory.v = sqrt(0.0738);
self.Income.Transitory.m = -0.5 * self.Income.Transitory.v^2;
self.Income.Permanent.m  = -0.5 * self.Income.Permanent.v^2;
self.Income.cov = [self.Income.Permanent.v^2, 0; 0, self.Income.Transitory.v^2];
% integration nodes for return and permanent income shocks
self.numberOfShocks = 3;
n = [8, 4, 4];
m = [self.Return.m, self.Income.Permanent.m, self.Income.Transitory.m] * self.Time.ageStep;
s = [self.Return.cov, zeros(1, 2); zeros(2, 1), self.Income.cov] * self.Time.ageStep;
[x, w] = sgQuadLognorm(n, m, s);
self.Int.nodes   = x;
self.Int.weights = w;

%% Mortality table for annuity price computation
self.annuity = MortalityTable;
% load population mortalities
self.annuity.loadMortalityTable('us_pop_mortality_2009.mat', ...
                                self.Time.ageStart, self.Time.ageStop);

%% Discrete state transistion probalities (mortality table)
self.mortality = MortalityTable;
self.mortality.loadMortalityTable('us_pop_mortality_2009.mat', ...
                                  self.Time.ageStart, self.Time.ageStop);
self.transitionMatrix = self.mortality.survivalProbabilitiesFemale;

%% choose optimizer between fmincon, NPSOL, and SNOPT
self.Optimizer.routine = args.optimizer;
self.Optimizer.useGradients   = args.useGradients;
self.Optimizer.checkGradients = false;
self.Optimizer.tolCon  = 1e-6;
self.Optimizer.tolFun  = sqrt(eps);
self.Optimizer.maxIter = 100;
self.Optimizer.printLevel = 0;
self.Optimizer.printTimes = false;
self.Optimizer.noOfMultiStartPoints = 20;

%% Euler error computation
emptyEulerError.names = self.policyNames(1:2);
emptyEulerError.points = self.constructErrorPoints();
self.EulerError = repmat(emptyEulerError, 1, numel(self.Time.getRange()) - 1);

end
