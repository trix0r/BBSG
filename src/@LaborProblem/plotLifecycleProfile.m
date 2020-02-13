function plotLifecycleProfile(self, state, discreteState, policy, ~)

times = self.Time.getRange();
numberOfPaths = size(state.W, 1);

%% Compute non-normalized policies
deNormPolicyNames = strrep(self.policyNames, 'norm', '');
deNormPolicy = zeros(numberOfPaths, numel(times), numel(deNormPolicyNames));
for p = 1:numel(deNormPolicyNames)
    deNormPolicyName = deNormPolicyNames{p};
    deNormPolicy(:, :, p) = policy.(deNormPolicyName);
end

%% Compute non-normalized consumption
C = zeros(numberOfPaths, numel(times));
for t = times
    C(:, t) = self.computeConsumptionForPolicy(state.W(:, t), discreteState, t, ...
                                               squeeze(deNormPolicy(:, t, :)));
end

%% calculate and plot means (conditional on survival)
h   = figure;
ax1 = axes('Parent',h,'FontSize',14);
age = [times.age];
hold on;
plot(age, mean(state.W(:, times)) * 10, 'k', 'LineWidth', 2);
plot(age, mean(C(:, times)) * 10, 'g', 'LineWidth', 2);
plot(age, mean(policy.S(:, times)) * 10, 'b', 'LineWidth', 2);
stockFraction = policy.S(:, times) ./ (policy.S(:, times) + policy.B(:, times));
plot(age, mean(stockFraction), 'b--', 'LineWidth', 2);
plot(age, mean(policy.B(:, times)) * 10, 'm', 'LineWidth', 2);
plot(age, mean(state.Y(:, times)) * 10, 'r', 'LineWidth', 2);
legend('cash on hand', 'consumption', 'stocks', 'bonds', 'income', 'Location', 'best')
set(gca,'Box','off');   % Turn off the box surrounding the whole axes
xlim(ax1,[age(1) age(end)]);
ylim(ax1,[0 200]);
xlabel('Age','FontSize',14);
ylabel('$1,000','FontSize',14);
legend(ax1,'show');
hold off

%% for other measures (like Expected Shortfall) consider the survival probabilities
if self.Env.print; print([self.Env.outdir filesep 'lifecycle_profile'], '-dpng', '-r300'); end

if self.Env.print; close all; end


end

