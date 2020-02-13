function simulation = runSimulation(id)

[~, problem, ~, ~, interpPolicy] = loadResult(id, {'problem', 'interpPolicy'});

resultsPath = sprintf('results/%0.4u',id);
[state, discreteState, policy, shock] = problem.simulate(interpPolicy);
simulation = struct();
simulation.state         = state;
simulation.discreteState = discreteState;
simulation.policy        = policy;
simulation.shock         = shock;
save([resultsPath filesep 'simulation.mat'], 'simulation');

end