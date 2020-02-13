classdef TransactionCostsProblem < LifecycleProblem
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
        linearTransactionCosts
        numberOfStocks
        allowBorrowing
        enableIncome
    end
    
    % methods that implement Abstract methods of LifecycleProblem
    methods
        loadParameter(self, varargin)
        
        policy = computeTerminalPolicy(self, state, discreteState)
        
        [interpJ, interpGradJ] = ...
            computeTerminalValueFunction(self, state, discreteState)
        
        lambda = computeTerminalLambda(self, state, discreteState)
        
        [Info, J, gradientJ] = ...
            getJ(self, previousSolution, policy, state, discreteState, t)

        x0 = getOptimizationStartPolicy(self, state, discreteState, t)
        
        [A, b, Aeq, beq, lb, ub, nonlcon] = ...
            getConstraints(self, state, discreteState, t)

        C = computeConsumptionForPolicy(self, state, discreteState, t, ...
                                        policy)

        gradient = ...
            computeGradientForConsumption(self, state, discreteState, ...
                                          t, policy)

        gradient = ...
            computeGradientForPolicy(self, J, gradientJ, state, ...
                                    discreteState, t, policy, shocks)

        valueFunction = ...
            computeValueFunctionForPolicy(self, J,  state, ...
                                    discreteState, t, policy, shocks)

        lossAversion = computeLossAversion(self, J,  state, ...
                                    discreteState, t, policy, shocks)

        [shocks, probability] = ...
            computeShockDistribution(self, state, discreteState, t)
    end

    % methods that override methods of LifecycleProblem
    methods
        [state, discreteState, policy, shock] = ...
            simulate(self, interpPolicy)

        [J, policy, lambda, Info] = ...
            computeOptimalPolicy(self, previousSolution, state, ...
                                 discreteState, t, writeLog)

         errors = ...
             getEulerErrors(self, state, discreteState, t, solution, interpPolicy)

         plotJ(self, varargin)
    end
    
    % additional methods
    methods
        function self = TransactionCostsProblem(varargin)
            self.loadParameter(varargin{:});
        end

        optStockFractions = computeMertonPoint(self)

        [newNormW, newNormNormS] = computeNormalizedWealth(self, state, ...
                                           discreteState, t, policy, shock)

        [points, weights] = constructErrorPoints(self)

        eligibleState = cropToEligibleState(self, state)

        plotLifecycleProfile(self, state, discreteState, policy, shock)
    end
end
