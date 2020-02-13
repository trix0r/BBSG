function newState = computeStateTransition(self, state, discreteState, ...
                                           t, policy, shock)

[newNormW, newNormNormS] = self.computeNormalizedWealth(state, ...
                                        discreteState, t, ...
                                        policy, shock);
newX = bsxfun(@rdivide, newNormNormS, newNormW);
newState = newX;

end
