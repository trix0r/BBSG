    function plotConsumptionProfiles(ids, outdir)

    %% initialize figures
    fs = 20;
    % rates
    figure1 = figure;
    axes1 = axes('Parent', figure1, 'FontSize', fs);
    hold(axes1, 'on');

    styles = {'ks-', 'k^--'};
    labels = cell(numel(ids), 1);
    for i = 1:numel(ids)
        %% load result
        [~, problem, ~, ~, ~, ~, simulation] = loadResult(ids(i), {'problem', 'simulation'});

        %% Get times
        times = problem.Time.getRange();

        %% Compute non-normalized consumption
        C = problem.computeConsumptionDistribution(simulation.state, simulation.policy);

        %% plot into plot
        if problem.eligibleAnnuityPurchaseAges(1) == problem.eligibleAnnuityPurchaseAges(end)
            labels{i} = sprintf('%d', problem.eligibleAnnuityPurchaseAges(end));
        else
            labels{i} = sprintf('%d-%d', problem.eligibleAnnuityPurchaseAges(1), ...
                                         problem.eligibleAnnuityPurchaseAges(end));
        end
        plot(axes1, [times.age], mean(C(:, times) * 10), styles{i}, 'LineWidth', 2);
    end
    xlabel('Age', 'FontSize', fs);
    ylabel('1000 US dollars', 'FontSize', fs);
    legend(axes1, labels, 'Location', 'East', 'Interpreter', 'latex', 'FontSize', fs);
    hold off

    %% print plot
    if exist('outdir', 'var')
        % painters option ensures no OpenGL and thus true vector graphics
        sigma = strrep(sprintf('%1.4f', problem.Interest.sigma), '.', '_dot_');
        filename = sprintf('sigma_r_%s_consumption_profile', sigma);
        print(figure1, [outdir filesep filename],  '-painters', '-dpdf', '-bestfit');
        close(figure1);

    end

    end
