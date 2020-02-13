classdef (Abstract) EnvelopeLifecycleProblem < LifecycleProblem

    methods (Abstract)       
        newC = computeNewConsumptionForPolicy(self, C, state, discreteStateName, t, policy, shocks)
    end
    
    methods
        errors = computeStateSpaceEnvelopeEulerErrors(self, solution, interpPolicy, times)
        error = getEnvelopeEulerErrors(self, state, discreteState, t, solution, interpPolicy)
    end
end
