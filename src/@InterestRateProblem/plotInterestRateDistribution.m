function plotInterestRateDistribution(self, R, t, rGrid)

if ~exist('rGrid', 'var')
    longTermStd = self.Interest.sigma / (sqrt(2 * self.Interest.kappa));
    rGrid = self.Interest.theta - 3 * longTermStd : 0.0001 : self.Interest.theta + 3 * longTermStd;
end
%% determine distribution
density = @(x) normpdf(x, R + self.Interest.mean(R, t), sqrt(self.Return.Interest.cov(R, t, 2, 2)));

%% plot distribution
fs = 16;
figure1 = figure;
axes1 = axes('Parent', figure1, 'FontSize', fs);
hold(axes1, 'all');
plot(axes1, rGrid, density(rGrid), 'Linewidth', 2);
xlim(axes1, [min(rGrid) max(rGrid)]);
set(axes1, 'XTickLabel', []);
set(axes1, 'XTick', []);
set(axes1, 'YTickLabel', []);
set(axes1, 'YTick', []);
axes1.YAxis.Visible = 'off';
hold off

if self.Env.print
    % rotate for use in paper
    camroll(-90);
    % painters option ensures no OpenGL and thus true vector graphics
    sigma = strrep(sprintf('%1.4f', self.Interest.sigma), '.', '_dot_');
    filename = sprintf('sigma_r_%s_purchase_ages_%d-%d_r_distribution.pdf', ...
                       sigma, ...
                       self.eligibleAnnuityPurchaseAges(1), ...
                       self.eligibleAnnuityPurchaseAges(end));
    print([self.Env.outdir filesep filename],  '-painters', '-dpdf', '-bestfit');
    close(figure1);
end

end

