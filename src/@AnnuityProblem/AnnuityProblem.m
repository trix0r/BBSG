classdef AnnuityProblem < EnvelopeLifecycleProblem
    properties
        Grid
        Return
        Income
        Int
        Optimizer
        Time
        riskAversion
        elasticityOfIntertemporalSubstitution
        narrowFramingStrength
        discountFactor
        transitionMatrix
        minConsumption
        mortality
        annuity
    end

    % methods that implement Abstract methods of (Envelope)LifecycleProblem
    methods
        loadParameter(self, varargin)
        policy = computeTerminalPolicy(self, state, discreteState)
        [interpJ, interpGradJ] = computeTerminalValueFunction(self, state, discreteState)
        lambda = computeTerminalLambda(self, state, discreteState)
        [Info, J, gradientJ] = getJ(self, previousSolution, policy, state, discreteState, t)
        x0 = getOptimizationStartPolicy(self, state, discreteState, t)
        [A, b, Aeq, beq, lb, ub, nonlcon] = getConstraints(self, state, discreteState, t)
        C = computeConsumptionForPolicy(self, state, discreteState, t, policy)
        gradient = computeGradientForConsumption(self, state, discreteState, t, policy)
        gradient = computeGradientForPolicy(self, J, gradientJ, state, discreteState, t, policy, ...
            shocks)
        valueFunction = computeValueFunctionForPolicy(self, J,  state, discreteState, t, policy, ...
            shocks)
        lossAversion = computeLossAversion(self, J,  state, discreteState, t, policy, shocks)
        [shocks, probability] = computeShockDistribution(self, state, discreteState, t)
    end

    % methods that override methods of (Envelope)LifecycleProblem
    methods
        [state, discreteState, policy, shock] = simulate(self, interpPolicy)
        points = constructErrorPoints(self)
    end

    % additional methods
    methods
        function self = AnnuityProblem(varargin)
            self.loadParameter(varargin{:});
        end
        annuityFactor = computeAnnuityFactor(self, age, deferral)
        [newNormP, newNormY] = computeIncomeTransition(self, t, shocks)
        plotLifecycleProfile(self, state, discreteState, policy, shock)
    end
end
