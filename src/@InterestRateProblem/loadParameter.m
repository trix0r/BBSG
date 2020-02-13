function loadParameter(self, varargin)

%% Parse input arguments
parser = inputParser();
parser.addParameter('interestModel',           []);
parser.addParameter('modelVariant',            []);
parser.addParameter('incomeCase',              'highschool');
parser.addParameter('annuityPurchaseAges',     []);
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
parser.addParameter('noOfMultiStartPoints',    @(s,d,t) 20);
parser.addParameter('tolFun',                  @(s,d,t) sqrt(eps));
parser.addParameter('extrapolationType',       'linear');
parser.addParameter('enableIncome',            'true');
parser.addParameter('domainTrafo',             []);
parser.addParameter('policyDomainTrafo',       []);
parser.addParameter('maxQuadNodes',            []);
parser.addParameter('valueTrafo',              []);
parser.addParameter('policyValueTrafo',        []);
parser.addParameter('interestVola',            []);
parser.addParameter('EIS',                     -4);
parser.addParameter('riskAversion',            -4);
parser.addParameter('permanentShockVola',      []);
parser.parse(varargin{:});
args = parser.Results;

self.enableIncome = args.enableIncome;

checkNotEmpty('args', {'interestModel', 'modelVariant', 'baseLevel', 'policyBaseLevel', ...
               'refineTolerance', 'gradientRefineTolerance', 'policyRefineTolerance'});

%% Path and dependencies
self.loadParameter@LifecycleProblem;

%% Model variant
self.modelVariant = args.modelVariant;

%% Interest rate and return parametrization
switch lower(args.interestModel)
    case 'cir'
        % short rate
        self.Interest.kappa  = 0.107209; % speed of adaption
        self.Interest.theta  = 0.023339; % long term mean
        % volatility
        if isempty(args.interestVola)
            self.Interest.sigma  = 0.081435;
        else
            self.Interest.sigma  = args.interestVola;
        end
        self.Interest.lambda = -0.880667 * self.Interest.sigma; % market price of risk for p measure
        self.Interest.mean   = @(R, t) self.Interest.kappa * (self.Interest.theta - R) * t;
        self.Interest.trunc  = @(R) max(R, 0);
        % log stock return
        self.Return.lambda   = 0.030509;
        self.Return.v        = 0.190349;
        self.Return.mean     = @(R, t) (R + self.Return.lambda - 0.5 * self.Return.v^2) * t;
        % covariance
        self.Return.Interest.cov = @(R, t, i, j) subsref(...
            [self.Return.v^2 * t, 0; 0, self.Interest.sigma^2 * R * t], ...
            struct('type','()','subs',{{i,j}}));
    case 'vasicek'
        % short rate
        self.Interest.kappa  = 0.166687; % speed of adaption
        self.Interest.theta  = 0.018211; % long term mean
        % volatility
        if isempty(args.interestVola)
            self.Interest.sigma  = 0.010506;
        else
            self.Interest.sigma  = args.interestVola;
        end
        self.Interest.lambda = -9.594063 * self.Interest.sigma; % market price of risk for p measure
        self.Interest.mean   = @(R, t) self.Interest.theta - self.Interest.theta * ...
                                       exp(-self.Interest.kappa * t) + ...
                                       (exp(-self.Interest.kappa * t) - 1) * R;
        self.Interest.trunc  = @(R) R;
        % log stock return
        self.Return.lambda   = 0.035811;
        self.Return.v        = 0.187558;
        self.Return.mean     = @(R, t) ...
                                (self.Interest.theta * exp(-self.Interest.kappa * t) - ...
                                    self.Interest.theta + self.Interest.kappa * t * ...
                                    (self.Return.lambda - self.Return.v^2 / 2) + ...
                                    self.Interest.kappa * t * self.Interest.theta) / ...
                                self.Interest.kappa - (exp(-self.Interest.kappa * t) - 1) / ...
                                self.Interest.kappa * R;
        % covariance
        self.Return.Interest.cov = @(R, t, i, j) subsref(...
            [(self.Interest.sigma^2 * (4 * exp(-self.Interest.kappa * t) - ...
              exp(-2 * self.Interest.kappa * t) + 2 * self.Interest.kappa * t - 3) + ...
              2 * self.Interest.kappa^3 * self.Return.v^2 * t) / (2 * self.Interest.kappa^3), ...
              (self.Interest.sigma^2 * exp(-2 * self.Interest.kappa * t) * ...
             (exp(self.Interest.kappa * t) - 1)^2) / (2 * self.Interest.kappa^2); ...
             (self.Interest.sigma^2 * exp(-2 * self.Interest.kappa * t) * ...
             (exp(self.Interest.kappa * t) - 1)^2) / (2 * self.Interest.kappa^2), ...
             -(self.Interest.sigma^2 * (exp(-2 * self.Interest.kappa * t) - 1)) / ...
              (2 * self.Interest.kappa)], ...
            struct('type','()','subs',{{i,j}}));
%     case 'vasicek' % euler discretization
%         % short rate
%         self.Interest.kappa  = 0.166687; % speed of adaption
%         self.Interest.theta  = 0.018211; % long term mean
%         self.Interest.sigma  = 0.010506;  % volatility
%         self.Interest.lambda = -9.594063 * self.Interest.sigma; % market price of risk for p meas.
%         self.Interest.mean   = @(R, t) self.Interest.kappa * (self.Interest.theta - R) * t;
%         self.Interest.trunc  = @(R) R;
%         % log stock return
%         self.Return.lambda   = 0.035811;
%         self.Return.v        = 0.187558;
%         self.Return.mean     = @(R, t) (R + self.Return.lambda - 0.5 * self.Return.v^2) * t;
%         % covariance
%         self.Return.Interest.cov = @(R, t, i, j) subsref(...
%             [self.Return.v^2 * t, 0; 0, self.Interest.sigma^2 * t], ...
%             struct('type','()','subs',{{i,j}}));
    otherwise
        error('Interest rate model not supported!');
end
self.Interest.model  = args.interestModel;

%% Income parametrization
% income data from tables 1, 2, and 4 of Cocco/Gomes/Maenhout 2005
self.Income.retirementAge = 65;
switch lower(args.incomeCase)
    case 'nohighschool'
        self.Income.logReplacement = log(0.88983);
        self.Income.Permanent.logG = @(t) (-2.1361 + 2.6275 + 0.1684 * t - 0.0353 * t.^2 ./10 + ...
                                           0.0023 * t.^3 ./ 100) - ...
                                           log(10);
        self.Income.Permanent.v = sqrt(0.0105);
        self.Income.Transitory.v = sqrt(0.1056);
    case 'highschool'
        self.Income.logReplacement = log(0.68212);
        self.Income.Permanent.logG = @(t) (-2.17 + 2.7004 + 0.1682 * t - 0.0323 * t.^2 ./10 + ...
                                           0.0020 * t.^3 ./ 100) - ...
                                           log(10);
        self.Income.Permanent.v = sqrt(0.0106);
        self.Income.Transitory.v = sqrt(0.0738);
    case 'college'
        self.Income.logReplacement = log(0.938873);
        self.Income.Permanent.logG = @(t) (-4.3148 + 2.3831 + 0.3194 * t - 0.0577 * t.^2 ./10 + ...
                                           0.0033 * t.^3 ./ 100) - ...
                                           log(10);
        self.Income.Permanent.v = sqrt(0.0169);
        self.Income.Transitory.v = sqrt(0.0584);
    otherwise
        error('Income process not implemented!');
end
if ~isempty(args.permanentShockVola); self.Income.Permanent.v = args.permanentShockVola; end
if ~self.enableIncome
    self.Income.Permanent.v = eps;
    self.Income.Transitory.v = eps;
end
self.Income.Permanent.m = -0.5 * self.Income.Permanent.v^2;
self.Income.Transitory.m = -0.5 * self.Income.Transitory.v^2;

%% Time grid
self.Time = Time([], 20, 100, 1);

%% Names of State/Policy Variables
switch lower(args.modelVariant)
    case 'debug'
        self.stateNames = {'normW', 'R'};
        self.policyNames = {'normB'};
    case 'debugonlybond'
        self.stateNames = {'normW', 'R'};
        self.policyNames = {'normBP'};
    case 'debugannuity'
        self.stateNames = {'normW', 'normL', 'R'};
        self.policyNames = {'normB', 'normA'};
    case 'noannuitywithbond'
        self.stateNames = {'normW', 'R'};
        self.policyNames = {'normS', 'normB', 'normBP'};
    case {'termcertainannuitynobond', 'lifeannuitynobond'}
        self.stateNames = {'normW', 'normL', 'R'};
        self.policyNames = {'normS', 'normB', 'normA'};
    case 'lifeannuitywithbond'
        self.stateNames = {'normW', 'normL', 'R'};
        self.policyNames = {'normS', 'normB', 'normBP', 'normA'};
    otherwise
        error('Model variant not implemented!');
end
if ~iscell(args.gradientStateNames); args.gradientStateNames = {args.gradientStateNames}; end
self.gradientStateNames = args.gradientStateNames;
self.discreteStateNames = {'Alive'};

%% Risk aversion, EIS, narrow framing strength, discount
self.riskAversion = args.riskAversion;
self.elasticityOfIntertemporalSubstitution = args.EIS;
self.narrowFramingStrength = zeros(self.numberOfPolicies, 1);
self.discountFactor = 0.97;

%% Annuity type and mortalities
switch lower(args.modelVariant)
    case 'debug'
        self.annuityType = [];
        self.annuity = [];
    case {'noannuitywithbond', 'debugonlybond'}
        self.annuityType = [];
        self.annuity = [];
    case 'termcertainannuitynobond'
        self.annuityType = 'termCertain';
        self.annuity = MortalityTable;
        % load mortalities and override with 1 (sure survival)
        self.annuity.loadMortalityTable('us_act_mortality_2000.mat', ...
                                         self.Time.ageStart, self.Time.ageStop);
        self.annuity.survivalProbabilitiesFemale = [ones(self.Time.ageStop, 1); 0];
    case {'lifeannuitynobond', 'lifeannuitywithbond', 'debugannuity'}
        self.annuityType = 'life';
        self.annuity = MortalityTable;
        % load population mortalities
        self.annuity.loadMortalityTable('us_pop_mortality_2009.mat', ...
                                        self.Time.ageStart, self.Time.ageStop);
    otherwise
        error('Model variant not implemented!');
end
if isempty(args.annuityPurchaseAges)
    self.eligibleAnnuityPurchaseAges = self.Time.ageStart : self.Income.retirementAge - 1;
else
    self.eligibleAnnuityPurchaseAges = args.annuityPurchaseAges;
end

%% Minimum consumption
self.minConsumption = 0.001;

%% Basis type
self.Basis.linearType    = 'linear-boundary';
if args.BsplineDegree > 1
    self.Basis.BsplineType = 'lagrange-notaknot-spline-boundary';
else
    self.Basis.BsplineType = 'bspline-boundary';
end
self.Basis.enableUP      = true;
self.Basis.BsplineDegree = args.BsplineDegree;

%% Grids
switch lower(args.modelVariant)
    case 'debug'
        wllb = 0.02;
        wlub = 20;
    case {'noannuitywithbond', 'debugonlybond'}
        wllb = 0.02;
        wlub = 20;
    case 'termcertainannuitynobond'
        wllb = [0.02, 0];
        wlub = [50, 1];
    case {'lifeannuitynobond', 'lifeannuitywithbond', 'debugannuity'}
        wllb = [0.02, 0];
        if isempty(args.annuityPurchaseAges)
            wlub = [50, 10];
        else
            wlub = [80, 10];
        end
    otherwise
        error('Model variant not implemented!');
end
switch lower(args.interestModel)
    case 'cir'
        rlb = 0.0001;
        rub = 2 * self.Interest.theta + 0.0001;
    case 'vasicek'
        longTermStd = self.Interest.sigma / (sqrt(2 * self.Interest.kappa));
        rlb = self.Interest.theta - 3 * longTermStd;
        rub = self.Interest.theta + 3 * longTermStd;
    otherwise
        error('Interest rate model not supported!');
end
self.Grid.lowerBounds = [wllb, rlb];
self.Grid.upperBounds = [wlub, rub];

%% transformations
identityTrafo = [];
% grid transformations
if isempty(args.domainTrafo)
    domainTrafo = identityTrafo;
else
    domainTrafo = SimpleGridTransformation(args.domainTrafo);
end
%value transformations
if isempty(args.valueTrafo)
    valueTrafo = identityTrafo;
else
    valueTrafo = args.valueTrafo;
end

%% base grid definitions
% value function grid
self.Grid.J.Alive.DomainTrafo = domainTrafo;
self.Grid.J.Alive.ValueTrafo  = valueTrafo;
self.Grid.J.Alive.base = SgppInterpolant( ...
                            self.Basis.linearType, ...
                            args.gridType, ...
                            self.numberOfStates, ...
                            args.baseLevel, ...
                            [], ...
                            self.Grid.lowerBounds, ...
                            self.Grid.upperBounds, ...
                            [], ...
                            args.extrapolationType, ...
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

% grid transformations
if isempty(args.policyDomainTrafo)
    policyDomainTrafo = domainTrafo;
else
    policyDomainTrafo = SimpleGridTransformation(args.policyDomainTrafo);
end
%value transformations
if isempty(args.policyValueTrafo)
    policyValueTrafo = SquareTransformation;
else
    policyValueTrafo = args.policyValueTrafo;
end

for p = 1:self.numberOfPolicies
    policyName = self.policyNames{p};
    self.Grid.Policy.Alive.(policyName).DomainTrafo = policyDomainTrafo;
    self.Grid.Policy.Alive.(policyName).ValueTrafo  = policyValueTrafo;
    self.Grid.Policy.Alive.(policyName).base = SgppInterpolant( ...
                    self.Basis.linearType, ...
                    args.gridType, ...
                    self.numberOfStates, ...
                    args.policyBaseLevel, ...
                    [], ...
                    self.Grid.lowerBounds, ...
                    self.Grid.upperBounds, ...
                    [], ...
                    'constant', ...
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

%% Quadrature nodes
self.numberOfShocks = 4;
if isempty(args.maxQuadNodes)
    switch lower(args.modelVariant)
        case 'debug'
            self.maxQuadNodes = [1 1 1 2];
        case {'debugonlybond'}
            self.maxQuadNodes = [1 1 1 3];
        case 'debugannuity'
            self.maxQuadNodes = [1 1 1 2];
        case {'noannuitywithbond', 'lifeannuitywithbond'}
            self.maxQuadNodes = [3 1 1 3];
        case {'termcertainannuitynobond', 'lifeannuitynobond'}
            self.maxQuadNodes = [3 1 1 2];
        otherwise
            error('Model variant not implemented!');
    end
else
    self.maxQuadNodes = args.maxQuadNodes;
end
self.Int = containers.Map('KeyType', 'double', 'ValueType', 'any');
self.yields = containers.Map('KeyType', 'double', 'ValueType', 'double');
self.bondPortfolioYieldsGrids = containers.Map('KeyType', 'double', 'ValueType', 'any');
self.bondPortfolioYieldsNodes = containers.Map('KeyType', 'double', 'ValueType', 'any');
self.annuityfactors = containers.Map('KeyType', 'double', 'ValueType', 'any');
self.updateQuadratureMaps(unique(self.Grid.J.Alive.base.gridPoints(:, end))');


%% Discrete state transistion probalities (mortality table)
self.mortality = MortalityTable;
self.mortality.loadMortalityTable('us_pop_mortality_2009.mat', ...
                                  self.Time.ageStart, self.Time.ageStop);
self.transitionMatrix = self.mortality.survivalProbabilitiesFemale;

%% Optimizer (choose between fmincon, NPSOL, and SNOPT)
self.Optimizer.routine = args.optimizer;
self.Optimizer.useGradients = args.useGradients;
if ~args.useGradients
    self.Optimizer.checkGradients = false;
else
    self.Optimizer.checkGradients = false;
end
self.Optimizer.tolCon  = 1e-6;
self.Optimizer.tolFun  = args.tolFun;
self.Optimizer.maxIter = 100;
self.Optimizer.printLevel = 0;
self.Optimizer.printTimes = false;
self.Optimizer.noOfMultiStartPoints = args.noOfMultiStartPoints;

%% Euler error computation
emptyEulerError.names = self.policyNames;
emptyEulerError.points = self.constructErrorPoints();
self.EulerError = repmat(emptyEulerError, 1, numel(self.Time.getRange()) - 1);

end
