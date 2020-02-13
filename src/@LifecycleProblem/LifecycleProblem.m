classdef (Abstract) LifecycleProblem < handle
    properties
        stateNames
        discreteStateNames
        policyNames
        gradientStateNames
        numberOfShocks
        Basis
        Env
        EulerError
    end
    
    properties (Dependent)
        numberOfStates
        numberOfDiscreteStates
        numberOfPolicies
        numberOfGradientStates
    end
    
    methods (Abstract)       
        policy = computeTerminalPolicy(self, state, discreteState)
        
        [interpJ, interpGradJ] = ...
            computeTerminalValueFunction(self, state, discreteState)
        
        lambda = computeTerminalLambda(self, state, discreteState)
        
        [Info, J, gradientJ] = ...
            getJ(self, previousSolution, policy, state, discreteState, t)

        newState = ...
            computeStateTransition(self, state, discreteState, t, ...
                                   policy, shocks)
        
        shocks = ...
            generateRandomSample(self, numberOfSamples, state, ...
                                 discreteState, t)

        x0 = getOptimizationStartPolicy(self, state, discreteState, t)

        C = computeConsumptionForPolicy(self, state, discreteState, t, ...
                                        policy)

        gradient = ...
            computeGradientForConsumption(self, state, discreteState, ...
                                          t, policy)

        gradient = ...
            computeGradientForPolicy(self, J, gradientJ, state, ...
                                    discreteState, t, policy, shocks)

        valueFunction = ...
            computeValueFunctionForPolicy(self, J, state, ...
                                    discreteState, t, policy, shocks)

        lossAversion = computeLossAversion(self, J, state, ...
                                    discreteState, t, policy, shocks)

        [shocks, probability] = ...
            computeShockDistribution(self, state, discreteState, t)
        
        [A, b, Aeq, beq, lb, ub, nonlcon] = ...
            getConstraints(self, state, discreteState, t)
    end
    
    methods
        [J, policy, lambda, Info] = ...
            computeOptimalPolicy(self, previousSolution, state, ...
                                 discreteState, t, writeLog)
        
        [currentSolution, Info] = ...
            optimize(self, currentSolution, previousSolution, state, discreteState, t)
        
        [previousSolution, noStartPoints, noRefines, noInsertedPoints, noEndPoints, ...
            noPreviousPoints, noAddedPoints, noRemovedPoints, Info] = ...
            refine(self, previousSolution, previousPreviousSolution, ...
                   discreteState, t)
        
        [interpPolicy, Info] = generatePolicyInterpolant(self, solution, Info)
        
        [solution, Info] = solve(self)
        
        [state, discreteState, policy, shock] = ...
            simulate(self, interpPolicy, startPaths, numberOfPaths)
        
        errors = computeStateSpaceEulerErrors(self, solution, interpPolicy, times)

        errors = computeSimulationEulerErrors(self, solution, interpPolicy, state, ...
                                                   discreteState, times)

        errors = computeStateSpacePointwiseErrors(self, interpFctTarget, interpFctReal, times)

        [Info, J, gradientJ] = ...
            getEpsteinZinUtility(self, previousSolution, policy, ...
                                       state, discreteState, t)

        error = getEulerErrors(self, state, discreteState, t, solution, interpPolicy)

        options = getOptimizerOptions(self, state, discreteState, t)
        
        plotGridFunctions(self, solution, discreteState, labels, statuses)
        
        plotPolicies(self, solution, discreteState, interpPolicy, errors)

        plotJ(self, varargin)

        printErrors(self, errors, times)
        
        loadParameter(self)
        
        function value = get.numberOfStates(self)
            value = numel(self.stateNames);
        end
        
        function value = get.numberOfDiscreteStates(self)
            value = numel(self.discreteStateNames);
        end
        
        function value = get.numberOfPolicies(self)
            value = numel(self.policyNames);
        end
        
        function value = get.numberOfGradientStates(self)
            value = numel(self.gradientStateNames);
        end
    end
end
