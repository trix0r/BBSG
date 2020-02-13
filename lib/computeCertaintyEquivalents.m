function [ces, utils] = computeCertaintyEquivalents(ids, times)

ces = zeros(numel(ids), numel(times));
utils = zeros(numel(ids), numel(times));

for i = 1:numel(ids)
    %% load result
    [~, problem, ~, ~, ~, ~, simulation] = loadResult(ids(i), {'problem', 'simulation'});
    for j = 1:numel(times)
        [ces(i, j), utils(i, j)] = problem.computeCertaintyEquivalent(simulation.state, ...
                                                       simulation.policy, times{j});
    end
end
