function plotPrecautionarySavings(ids, outdir, saveLegend)

if ~exist('saveLegend', 'var'); saveLegend = false; end

%% initialize figures
fs = 24;

figure1 = figure;
axes1 = axes('Parent', figure1, 'FontSize', fs);
hold(axes1, 'on');

figure2 = figure;
axes2 = axes('Parent', figure2, 'FontSize', fs);
hold(axes2, 'on');

color = {[117, 163, 255] ./ 255, [252, 112, 112] ./ 255, [232, 213, 190] ./ 255};
lineStyles = {'-o', '-', '-+'};
lineColor = [100, 100, 100] ./ 255;
labels = cell(numel(ids), 1);
for i = 1:numel(ids)
    %% load result
    [~, problem, ~, ~, ~, ~, simulation] = loadResult(ids(i), {'problem', 'simulation'});

    %% Get times
    times = problem.Time.getRange();

    %% Compute asset allocatios
    holdings = problem.computeAssetAllocation(simulation.state, simulation.policy);
    precautionarySavings = sum(holdings, 3);
    averageHoldings = squeeze(mean(holdings, 1))' * 10;

    %% plot into plot
    labels{i} = sprintf('$\\sigma_{\\varepsilon} = %07.4f\\%%$', problem.Income.Permanent.v * 100);
    labels{i} = regexprep(labels{i}, '=\ 0', '=\ \\hspace{0.5em}');
    plot(axes1, [times.age], mean(precautionarySavings(:, times) * 10), lineStyles{i}, ...
        'Color', lineColor, 'LineWidth', 2, 'MarkerSize', 10);
    for j = 1:size(averageHoldings, 1)
        plot(axes2, [times.age], averageHoldings(j, times), lineStyles{i}, 'Color', color{j}, ...
             'LineWidth', 2, 'MarkerSize', 10);
    end
end

% figure 1
xlabel(axes1, 'Age', 'FontSize', fs);
ylabel(axes1, '1000 US dollars', 'FontSize', fs);
ylim(axes1, [0, 350])

% figure 2
xlabel(axes2, 'Age', 'FontSize', fs);
ylabel(axes2, '1000 US dollars', 'FontSize', fs);
ylim(axes2, [0, 350])
hold off

%% print plot
if exist('outdir', 'var') && ~isempty(outdir)
    % painters option ensures no OpenGL and thus true vector graphics
    sigma_r = strrep(sprintf('%1.4f', problem.Interest.sigma), '.', '_dot_');
    filename = sprintf('sigma_r_%s_purchase_ages_%d-%d_precautionary_savings', ...
                       sigma_r, problem.eligibleAnnuityPurchaseAges(1), ...
                       problem.eligibleAnnuityPurchaseAges(end));
    print(figure1, [outdir filesep filename],  '-painters', '-dpdf', '-bestfit');
    filename = sprintf('sigma_r_%s_purchase_ages_%d-%d_precautionary_holdings', ...
                       sigma_r, problem.eligibleAnnuityPurchaseAges(1), ...
                       problem.eligibleAnnuityPurchaseAges(end));
    print(figure2, [outdir filesep filename],  '-painters', '-dpdf', '-bestfit');

    % print legends to separate file
    if saveLegend == true
        legend1 = legend(axes1, labels, 'Location', 'Northoutside', 'Orientation', 'horizontal', ...
                         'Interpreter', 'latex', 'FontSize', fs);
        filename = sprintf('sigma_r_%s_purchase_ages_%d-%d_precautionary_savings_legend.pdf', ...
                           sigma_r, problem.eligibleAnnuityPurchaseAges(1), ...
                           problem.eligibleAnnuityPurchaseAges(end));
        set(0, 'currentfigure', figure1);
        set(figure1, 'currentaxes', axes1);
        saveLegendToFile(figure1, legend1, [outdir filesep filename])
        close(figure1);
        [legend2, objh] = legend(axes2, {'Stocks', 'Money market', 'Annuity claims (PV)'}, ...
                         'Location', 'Northoutside', 'Orientation', 'horizontal', 'FontSize', fs);
         % choose correct line style
        lineh = findobj(objh, 'type', 'line');
        set(lineh, 'LineStyle', '-');
        set(lineh, 'Marker', 'none');
        filename = sprintf('sigma_r_%s_purchase_ages_%d-%d_precautionary_holdings_legend.pdf', ...
                           sigma_r, problem.eligibleAnnuityPurchaseAges(1), ...
                           problem.eligibleAnnuityPurchaseAges(end));
        set(0, 'currentfigure', figure2);
        set(figure2, 'currentaxes', axes2);
        saveLegendToFile(figure2, legend2, [outdir filesep filename])
        close(figure2);
        return
    end
    close(figure1);
    close(figure2);
end

end
