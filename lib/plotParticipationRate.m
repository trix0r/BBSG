function plotParticipationRate(ids, outdir, saveLegend)

if ~exist('saveLegend', 'var'); saveLegend = false; end
%% input only ids with same interest rate vola

%% initialize figures
fs = 24;
% rates
figure1 = figure;
axes1 = axes('Parent', figure1, 'FontSize', 14);
hold(axes1, 'on');
% expected claims
figure2 = figure;
axes2 = axes('Parent', figure2, 'FontSize', 14);
hold(axes2, 'on');


styles = {'bv--', 'b^--', 'bo-', 'bd:', 'bs:'};
labels = cell(numel(ids), 1);
for i = 1:numel(ids)
    %% load result
    [~, problem, ~, ~, ~, errors, simulation] = loadResult(ids(i), ...
                                                           {'problem', 'simulation', 'errors'});

    %% determine error tolerance as max. error of annuity policy
    err = struct2struct(errors);
    errorTolerance = nanmean(err.Max(:,3));

    %% compute participation rate
    retirement = problem.Time;
    retirement.age = problem.Income.retirementAge;
    times = problem.Time.getRange();
    times = times(1:retirement.index);
    rate = NaN(1, numel(times));
    expectedClaims = NaN(1, numel(times));
    numberOfPaths = size(simulation.state.L, 1);
    for t = times
        idx = simulation.state.L(:, t) > errorTolerance;
        rate(t) = sum(idx, 1) / numberOfPaths;
        expectedClaims(t) = 10 * mean(simulation.state.L(idx, t), 1);
    end    
    
    %% plot into plot
    % rate
    plot(axes1, [times.age], rate, styles{i}, 'LineWidth', 2);
    labels{i} = sprintf('$\\psi = %.2f \\, , \\gamma = %.2f$', ...
                        1 - problem.elasticityOfIntertemporalSubstitution, ...
                        1 - problem.riskAversion);
    % expectedClaims
    plot(axes2, [times.age], expectedClaims, styles{i}, 'LineWidth', 2);
    labels{i} = sprintf('$\\psi = %.2f \\, , \\gamma = %.2f$', ...
                        1 - problem.elasticityOfIntertemporalSubstitution, ...
                        1 - problem.riskAversion);
end

%% set xlabels etc.
% rates
xlim(axes1, [20 65]);
ylim(axes1, [0 1]);
xticks(axes1, 20:5:65);
yticks(axes1, 0:0.2:1);
a = get(axes1,'XTickLabel');
set(axes1,'XTickLabel', a, 'FontSize', fs)
a = get(axes1,'YTickLabel');
set(axes1,'YTickLabel', a, 'FontSize', fs)
xlabel(axes1, 'Age', 'FontSize', fs);
ylabel(axes1, 'Cumulative participation rate', 'FontSize', fs);
hold(axes1, 'off');

% expected claims
ymax = 20;
xlim(axes2, [20 65]);
ylim(axes2, [0 ymax]);
xticks(axes2, 20:5:65);
yticks(axes2, 0:5:ymax);
a = get(axes2,'XTickLabel');
set(axes2,'XTickLabel', a, 'FontSize', fs)
a = get(axes2,'YTickLabel');
set(axes2,'YTickLabel', a, 'FontSize', fs)
xlabel(axes2, 'Age', 'FontSize', fs);
ylabel(axes2, 'Average cumulated annuity claims', 'FontSize', fs);
hold(axes2, 'off');

%% print plot
if exist('outdir', 'var') && ~isempty(outdir)
    % painters option ensures no OpenGL and thus true vector graphics
    sigma = strrep(sprintf('%1.4f', problem.Interest.sigma), '.', '_dot_');
    filename = sprintf('sigma_r_%s_participation_rates.pdf', sigma);
    print(figure1, [outdir filesep filename],  '-painters', '-dpdf', '-bestfit');
    filename = sprintf('sigma_r_%s_expected_claims.pdf', sigma);
    print(figure2, [outdir filesep filename],  '-painters', '-dpdf', '-bestfit');

    % print legends to separate file
    if saveLegend == true
        legend1 = legend(axes1, labels, 'Location', 'Northoutside', 'Orientation', 'horizontal', ...
                         'Interpreter', 'latex', 'FontSize', 10);
        filename = sprintf('sigma_r_%s_participation_rates_legend.pdf', sigma);
        set(0, 'currentfigure', figure1);
        set(figure1, 'currentaxes', axes1);
        saveLegendToFile(figure1, legend1, [outdir filesep filename])
        close(figure1);
        close(figure2);
        return
    end
    close(figure1);
    close(figure2);
end

end
