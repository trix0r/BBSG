function evaluateAssetDemand(self, state, policy, policyName, method)

longTermStd = self.Interest.sigma / (sqrt(2 * self.Interest.kappa));
R = self.Interest.theta - 3 * longTermStd : 0.001 : self.Interest.theta + 3 * longTermStd;
retirement =self.Time;
retirement.age = self.Income.retirementAge;
time = self.Time.getRange();
time = time(1:retirement.index - 1);

switch lower(method)
    case 'kerneldensity'
        %% evaluation using kernel density estimation
        assetDemand = kernelDensityEstimation(self, state, policy, policyName, time, R);
    case 'policy'
        %% evalaution using policies at mean
        assetDemand = evaluatePolicy(self, state, policy, policyName, time, R);
    otherwise
        error('Method not implemented!')
end

if strcmp(policyName, 'A')
    annuityPrice = zeros(numel(R), numel(time));
    for t=time
        if t.age >= self.Income.retirementAge
            % buy immediate annuity
            annuityPrice(:, t) = self.computeAnnuityFactor(t.age, R', 0);
        else
            annuityPrice(:, t) = self.computeAnnuityFactor(t.age, R', ...
                                        self.Income.retirementAge - t.age - self.Time.ageStep);
        end
    end
    ZZ = 10 * assetDemand ./ annuityPrice;
    lbl = 'Acquired annuity claims in 1000 US dollars';
else
    ZZ = 10 * assetDemand;
    lbl = [policyName '  demand in 1000 US dollars'];
end

fs = 18;
figure1 = figure;
axes1 = axes('Parent', figure1);
hold(axes1, 'on');
ages = [time.age];
[XX, YY] = meshgrid(ages, R);
surf(XX, YY, ZZ, 'EdgeColor', 'None', 'Facecolor', 'interp');
% x axes
xlim([min(ages), max(ages)]);
xticks(axes1, [min(ages):10:max(ages)-4, 64]);
a = get(axes1,'XTickLabel');
set(axes1,'XTickLabel', a, 'FontSize', fs)
xlabel('Age', 'FontSize', fs);
% y axes with duplicated ticks on right hand side
numberOfYticks = 5;
yyaxis left;
ylim([min(R), max(R)]);
set(axes1,'YTick',[])
a = get(axes1,'YTickLabel');
set(axes1,'YTickLabel', a, 'FontSize', fs)
ylabel('Short rate', 'FontSize', fs);
yyaxis right
ylim([min(R), max(R)]);
yticks(axes1, min(R):(max(R) - min(R)) / (numberOfYticks - 1):max(R));
axes1.YTickLabel = sprintfc('%.1f%%', axes1.YTick * 100);
set(axes1, 'YColor', 'k')

% set x-y view and color coding
view(axes1, [0 90]);
c = colorbar(axes1, 'Location', 'northoutside');
c.Label.String = lbl;
colormap(axes1, 'jet');
% compute max value in plotted r range
% idx = R >= ymin & R <= ymax;
% zmax = max(max(ZZ(idx,:)));
% caxis(axes1, [0 4])


if self.Env.print
    sigma = strrep(sprintf('%1.4f', self.Interest.sigma), '.', '_dot_');
    filename = sprintf('sigma_r_%s_purchase_ages_%d-%d_asset_demand.pdf', ...
                       sigma, ...
                       self.eligibleAnnuityPurchaseAges(1), ...
                       self.eligibleAnnuityPurchaseAges(end));
    print([self.Env.outdir filesep filename],  '-opengl', '-r300', '-dpdf', '-bestfit');
    close(figure1);
end

%% evalaution using regression on means
% a = zeros(size(rGrid));
% p = 0.25;
% for i = 1 : length(T)
%     t = T(i);
%     idxW = W(:,t) <= mean(W(:,t)) + mean(W(:,t)) * p & W(:,t) >= mean(W(:,t)) - mean(W(:,t)) * p;
%     idxL = L(:,t) <= mean(L(:,t)) + max(mean(L(:,t)) * p, 0.001) & L(:,t) >= mean(L(:,t)) - max(mean(L(:,t)) * p, 0.001) ;
%     idx = idxW & idxL;
%     tbl = table(R(idx,t), Asset(idx,t));
%     mdl = fitlm(tbl);
%     mdl.Coefficients.Estimate;
%     a(:,i)  = mdl.Coefficients.Estimate(1) + mdl.Coefficients.Estimate(2) * rGrid(:,i);
% end
%
% figure;
% surf(self.startAge - 1 + tGrid, rGrid, a);
end

function assetDemand = kernelDensityEstimation(self, state, policy, policyName, time, R)
    assetDemand = zeros(length(R), numel(time));
    deNormStateNames = strrep(self.stateNames(1:end - 1), 'norm', '');
    N = size(state.R, 1);
    alpha = zeros(1, numel(deNormStateNames));
    weights = zeros(N, numel(deNormStateNames));
    p = -1/8; % rule of thumb: p = -1/5; before: p = log10(sqrt(2))/log10(length(W(:,end));
    for t = time
        for s = 1:numel(deNormStateNames)
            deNormStateName = deNormStateNames{s};
            alpha(s) = N^p * std(state.(deNormStateName)(:, t));
            weights(:, s) = exp(- 0.5 * ((state.(deNormStateName)(:, t) - ...
                                nanmean(state.(deNormStateName)(:, t))) ./ alpha(s)).^2);
        end
        alphaR = N^p * std(state.R(:,t));
        weightsR = exp(- 0.5 * (bsxfun(@minus, state.R(:, t), R) ./ alphaR).^2);
        w = bsxfun(@times, prod(weights, 2), weightsR);
        w = bsxfun(@times, w, 1 ./ sum(w, 1));
        assetDemand(:, t)  = sum(bsxfun(@times, w, policy.(policyName)(:, t)), 1);
    end
end

function assetDemand = evaluatePolicy(self, state, policy, policyName, time, R)
    assetDemand = zeros(length(R), numel(time));
    s = zeros(length(R), self.numberOfStates);
    normPolicyName = ['norm' policyName];
    for t = time
        for q = 1:self.numberOfStates - 1
            stateName = self.stateNames{q};
            s(:, q) = repmat(mean(state.(stateName)(:, t)), [length(R), 1]);
        end
        s(:, end) = R;
        assetDemand(:, t) = policy(t).Alive.(normPolicyName).evaluate(s) .* ...
                                                            mean(exp(state.logP(:, t)));
    end
end