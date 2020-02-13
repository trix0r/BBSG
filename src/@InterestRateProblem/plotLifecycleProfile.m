function plotLifecycleProfile(self, state, ~, policy, ~, saveLegend)

if ~exist('saveLegend', 'var'); saveLegend = false; end

times = self.Time.getRange();

%% Compute non-normalized consumption
C = self.computeConsumptionDistribution(state, policy);

%% calculate and plot means (conditional on survival)
colorC = [116, 252, 125] ./ 255;
colorS = [117, 163, 255] ./ 255;
colorBP = [231, 113, 252] ./ 255;
colorB = [252, 112, 112] ./ 255;
colorA = [232, 213, 190] ./ 255;
colorL = [112, 252, 233] ./ 255;
% Lifecycle plot
fs = 16;
figure1 = figure;
axes1 = axes('Parent', figure1, 'FontSize', fs);
hold(axes1, 'all');
age = [times.age];
plot(age, mean(C(:, times) * 10), 'Parent', axes1, 'LineWidth', 2, 'Color', colorC , ...
         'DisplayName','Consumption');
if isfield(policy, 'S')
    plot(age, mean(policy.S(:, times) * 10), 'Parent', axes1, 'LineWidth', 2, 'Color', colorS, ...
         'DisplayName','Stocks');
end
if isfield(policy, 'BP')
    plot(age, mean(policy.BP(:, times) * 10), 'Parent', axes1, 'LineWidth', 2, 'Color', colorBP, ...
         'DisplayName','Bond portfolio');
end
if isfield(policy, 'B')
    plot(age, mean(policy.B(:, times) * 10), 'Parent', axes1, 'LineWidth', 2, 'Color', colorB, ...
         'DisplayName','Money market');
end
if isfield(state, 'L')
    plot(age, mean(state.L(:, times) * 10), 'Parent', axes1, 'LineWidth', 2, 'Color', colorL, ...
         'DisplayName','Cumulated annuity claims');
    plot(age, [zeros(1, self.Income.retirementAge - self.Time.ageStart), ...
         mean(state.L(:, (self.Income.retirementAge : self.Time.ageStep : self.Time.ageStop) - ...
                         self.Time.ageStart + self.Time.ageStep)) * 10], ...
        'Parent', axes1, 'LineWidth', 2, 'LineStyle', '--', 'Color', [0.5 0.5 0.5], ...
        'DisplayName','Annuity payouts');
end
plot(age, mean(exp(state.logY(:, times))) * 10, 'Parent', axes1, 'LineWidth', 1, 'Color', ...
     [0.5 0.5 0.5], 'LineStyle', '-.', 'DisplayName','Labor income');
% maximum of $200T
xlim(axes1, [min(age) max(age)]);
ylim(axes1, [0 200]);
a = get(axes1, 'XTickLabel');
set(axes1, 'XTickLabel', a, 'FontSize', fs)
a = get(axes1, 'YTickLabel');
set(axes1, 'YTickLabel', a, 'FontSize', fs)
xlabel('Age', 'FontSize', fs);
ylabel('1000 US dollars', 'FontSize', fs);
hold off

%% plot asset allocatios
[~, fractions] = self.computeAssetAllocation(state, policy);
fractions = squeeze(nanmean(fractions, 1)) * 100;

figure2 = figure;
% Create axes
axes2 = axes('Parent', figure2, 'FontSize', fs);
area2 = area(fractions, 'LineWidth', 2);
deNormPolicyNames = strrep(self.policyNames, 'norm', '');
sIdx = strcmp('S', deNormPolicyNames);
bIdx = strcmp('B', deNormPolicyNames);
bpIdx = strcmp('BP', deNormPolicyNames);
aIdx = strcmp('A', deNormPolicyNames);
set(area2(sIdx),'DisplayName', 'Stocks', 'FaceColor', colorS);
set(area2(bIdx),'DisplayName', 'Money market', 'FaceColor', colorB);
set(area2(bpIdx),'DisplayName', 'Bond portfolio', 'FaceColor', colorBP);
set(area2(aIdx),'DisplayName', 'Annuity claims (PV)', 'FaceColor', colorA);
% set limits
xlim(axes2, [1 80]);
ylim(axes2, [0 100]);
xticks(axes2, [1, 20:20:80]);
xtickLabels = min(age):20:max(age);
set(axes2, 'XTickLabel', {xtickLabels}, 'FontSize', fs)
a = get(axes2, 'YTickLabel');
set(axes2,'YTickLabel', a, 'FontSize', fs)
% Create xlabel
xlabel('Age', 'FontSize', fs);
% Create ylabel
ylabel('%', 'FontSize', fs);

%% print plots
if self.Env.print
    % painters option ensures no OpenGL and thus true vector graphics
    sigma_r = strrep(sprintf('%1.4f', self.Interest.sigma), '.', '_dot_');
    sigma_p = strrep(sprintf('%1.4f', self.Income.Permanent.v), '.', '_dot_');
    filename = sprintf('sigma_r_%s_sigma_p_%s_purchase_ages_%d-%d_lifecycle_profile.pdf', ...
                       sigma_r, sigma_p, ...
                       self.eligibleAnnuityPurchaseAges(1), ...
                       self.eligibleAnnuityPurchaseAges(end));
    print(figure1, [self.Env.outdir filesep filename],  '-painters', '-dpdf', '-bestfit');
    filename = sprintf('sigma_r_%s_sigma_p_%s_purchase_ages_%d-%d_asset_allocation.pdf', ...
                       sigma_r, sigma_p, ...
                       self.eligibleAnnuityPurchaseAges(1), ...
                       self.eligibleAnnuityPurchaseAges(end));
    print(figure2, [self.Env.outdir filesep filename],  '-painters', '-dpdf', '-bestfit');

    % print legends to separate file
    if saveLegend == true
        legend1 = legend(axes1, 'Location', 'Northoutside');
        legend1.FontSize = fs;
        filename = sprintf(['sigma_r_%s_sigma_p_%s_purchase_ages_%d-%d_' ...
                            'lifecycle_profile_legend.pdf'], ...
                           sigma_r, sigma_p, ...
                           self.eligibleAnnuityPurchaseAges(1), ...
                           self.eligibleAnnuityPurchaseAges(end));
        set(0, 'currentfigure', figure1);
        set(figure1, 'currentaxes', axes1);
        saveLegendToFile(figure1, legend1, [self.Env.outdir filesep filename])
        close(figure1);
        legend2 = legend(axes2, 'Location', 'Northoutside');
        legend2.FontSize = fs;
        filename = sprintf(['sigma_r_%s_sigma_p_%s_purchase_ages_%d-%d_' ...
                            'asset_allocation_legend.pdf'], ...
                           sigma_r, sigma_p, ...
                           self.eligibleAnnuityPurchaseAges(1), ...
                           self.eligibleAnnuityPurchaseAges(end));
        set(0, 'currentfigure', figure2);
        set(figure2, 'currentaxes', axes2);
        saveLegendToFile(figure2, legend2, [self.Env.outdir filesep filename])
        close(figure2);
        return
    end
    close(figure1);
    close(figure2);
end

end

