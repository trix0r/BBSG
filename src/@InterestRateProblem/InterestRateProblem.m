classdef InterestRateProblem < LifecycleProblem
   properties
        Grid
        Interest
        Return
        Income
        Optimizer
        Time
        riskAversion
        elasticityOfIntertemporalSubstitution
        narrowFramingStrength
        discountFactor
        transitionMatrix
        minConsumption
        enableIncome
        annuityType
        annuity
        eligibleAnnuityPurchaseAges
        mortality
        Int
        yields
        bondPortfolioYieldsGrids
        bondPortfolioYieldsNodes
        annuityfactors
        modelVariant
        maxQuadNodes
    end
    
    % methods that implement Abstract methods of LifecycleProblem
    methods
        loadParameter(self, varargin)
        policy = computeTerminalPolicy(self, state, discreteState)
        [interpJ, interpGradJ] = computeTerminalValueFunction(self, state, discreteState)
        lambda = computeTerminalLambda(self, state, discreteState)
        newState = computeStateTransition(self, state, discreteState, t, policy, shocks)
        shocks = generateRandomSample(self, numberOfSamples, state, discreteState, t)
        [Info, J, gradientJ] = getJ(self, previousSolution, policy, state, discreteState, t)
        x0 = getOptimizationStartPolicy(self, state, discreteState, t)
        [A, b, Aeq, beq, lb, ub, nonlcon] = getConstraints(self, state, discreteState, t)
        C = computeConsumptionForPolicy(self, state, discreteState, t, policy)
        gradient = computeGradientForConsumption(self, state, discreteState, t, policy)
        gradient = computeGradientForPolicy(self, J, gradientJ, state, discreteState, t, ...
                                            policy, shocks)
        valueFunction = computeValueFunctionForPolicy(self, J,  state, discreteState, t, ...
                                            policy, shocks)
        lossAversion = computeLossAversion(self, J,  state, discreteState, t, policy, shocks)
        [shocks, probability] = computeShockDistribution(self, state, discreteState, t)
        points = constructErrorPoints(self)
    end

    % methods that override methods of LifecycleProblem
    methods
        [state, discreteState, policy, shock] = simulate(self, interpPolicy)
        [currentSolution, Info] = optimize(self, currentSolution, previousSolution, state, ...
                                           discreteState, t)
        errors = computeStateSpaceEulerErrors(self, solution, interpPolicy, times)
    end
    
    % additional methods
    methods
        function self = InterestRateProblem(varargin)
            self.loadParameter(varargin{:});
        end
        annuityFactor = computeAnnuityFactor(self, age, shortRate, deferral)
        [holdings, fractions] = computeAssetAllocation(self, state, policy)
        portfolioPrice = computeBondPortfolioPrice(self, age, shortRate, deferral)
        [consumption, utility] = computeCertaintyEquivalent(self, state, policy, t)
        C = computeConsumptionDistribution(self, state, policy)
        [newLogNormP, newLogNormY] = computeIncomeTransition(self, t, shocks)
        evaluateAssetDemand(self, state, policy, policyName, method)
        [deNormPolicy, deNormPolicyNames] = getDeNormPolicies(self, policy)
        plotAnnuityClaimDistribution(self, distribution, age)
        plotInterestRateDistribution(self, R, t, rGrid)
        plotLifecycleProfile(self, state, discreteState, policy, shock, showLegend)
        updateQuadratureMaps(self, shortRate)
    end

    methods (Static)
        [spotRatesDistribution, bondPrice] = computeSpotRates(shortRateDistribution, kappa, ...
                                                              theta, sigma, lambda, tau, model)
    end
end
