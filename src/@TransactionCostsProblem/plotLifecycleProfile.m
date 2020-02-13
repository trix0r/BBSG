function plotLifecycleProfile(self, state, discreteState, policy, shock)

times = self.Time.getRange();
normW = state.normW;
n = size(normW, 1);

x = zeros(n, numel(times) + 1, self.numberOfStocks);
for s = 1:self.numberOfStocks
    stateName = self.stateNames{s};
    buy  = self.policyNames{s};
    sell = self.policyNames{s + self.numberOfStocks};
    x(:, :, s) = state.(stateName);
    normS.(stateName) = (x(:, 1:end-1, s) + policy.(buy) - policy.(sell)) .* normW(:, 1:end-1);
end
normB = policy.normNormB .* normW(:, 1:end-1);

% compute income from permanent income factor
if self.enableIncome
    Y = zeros(size(normW));
    t = self.Time.copy();
    t.age = self.Income.retirementAge;
    idx = t.index;
    timesBeforeRetirement = self.Time.getStart():(t - 1);
    Y(:, 1:idx-1) = repmat(self.Income.Permanent.G([timesBeforeRetirement.age]), [length(shock(:, 3)), 1]) .* repmat(shock(:, 3), [1, length(timesBeforeRetirement)]);
    Y(:, idx:end) = self.Income.Permanent.G(self.Income.retirementAge) * self.Income.replacement;
end

%% plot only path where people are alive
idx = discreteState == 2;
normW(idx) = nan;
% P(idx) = nan;
for s = 1:self.numberOfStocks
    stateName = self.stateNames{s};
    normS.(stateName)(idx) = nan;
end
normB(idx) = nan;
if self.enableIncome; Y(idx) = nan; end

%% get consumption
tmpPolicy = reshape(cell2mat(struct2cell(policy)), ...
                    n, self.numberOfPolicies, numel(times));
C = zeros(n, numel(times));
for t = times
    C(:, t) = self.computeConsumptionForPolicy(squeeze(x(:, t, :)), ...
                                    discreteState, t, ...
                                    tmpPolicy(:, :, t)) .* normW(:, t);
end
%% calculate and plot means (conditional on survival)
h   = figure;
ax1 = axes('Parent',h,'FontSize',14);
age = [times.age];
hold on;
plot(age, max(nanmean(normW(:, times) * 10), 0), 'k', 'LineWidth', 2);
plot(age, max(nanmean(C(:, times)) * 10, 0), 'g', 'LineWidth', 2);
styles = {'b+-', 'bs-', 'bx-', 'b^-', 'bv-'};
for s = 1:self.numberOfStocks
    stateName = self.stateNames{s};
    plot(age, max(nanmean(normS.(stateName)(:, times)) * 10, 0), ...
         styles{s}, 'LineWidth', 2);
end
plot(age, max(nanmean(normB(:, times)) * 10, 0), 'm', 'LineWidth', 2);
if self.enableIncome; plot(age, max(nanmean(Y(:, times)) * 10, 0), 'r', 'LineWidth', 2); end
stockStrings = sprintfc('stock %i', (1:self.numberOfStocks));
if self.enableIncome
    legend( 'cash on hand', 'consumption', stockStrings{:}, 'bonds', ...
            'income', 'Location', 'best')
else
    legend( 'cash on hand', 'consumption', stockStrings{:}, 'bonds', 'Location', 'best')
end
set(gca,'Box','off');   % Turn off the box surrounding the whole axes
xlim(ax1,[age(1) age(end)]);
ylim(ax1,[0 10]);
xlabel('Age','FontSize',14);
ylabel('$1,000','FontSize',14);
legend(ax1,'show');
hold off

%% for other measures (like Expected Shortfall) consider the survival probabilities
if self.Env.print; print([self.Env.outdir filesep 'lifecycle_profile'], '-dpng', '-r300'); end

if self.Env.print; close all; end


end

