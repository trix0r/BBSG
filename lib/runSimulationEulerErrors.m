function errors = runSimulationEulerErrors(id)

loadVars = {'problem', 'solution', 'interpPolicy', 'simulation'};
[~, problem, solution, ~, interpPolicy, ~, simulation] = loadResult(id, loadVars);

if isempty(simulation)
    simulation = runSimulation(id);
end

resultsPath = sprintf('results/%0.4u',id);
errors = problem.computeSimulationEulerErrors(solution, interpPolicy, simulation.state, ...
                                              simulation.discreteState); 
problem.printErrors(errors);
save([resultsPath filesep 'simulation_euler_errors.mat'], loadVars{:}, 'errors');

end
