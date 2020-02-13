function plotAnnuityClaimDistribution(self, distribution, age)

t = self.Time;
t.age = age;

%% plot histogram
fs = 24;
figure1 = figure;
axes1 = axes('Parent', figure1, 'FontSize', fs);
xbins1 = 0:5:100;
histogram(axes1, distribution(:, t) * 10, xbins1, 'Normalization', 'probability');
xmax = 75;
ymax = 0.4;
xlim(axes1, [0 xmax]);
ylim(axes1, [0 ymax]);
xticks(axes1, 0:25:xmax);
yticks(axes1, 0:0.1:ymax);
a = get(axes1,'XTickLabel');
set(axes1,'XTickLabel', a, 'FontSize', fs)
a = get(axes1,'YTickLabel');
set(axes1,'YTickLabel', a, 'FontSize', fs)
xlabel(axes1, '1000 US dollars', 'FontSize', fs);
ylabel(axes1, 'Frequencey', 'FontSize', fs);
avg = mean(distribution(:, t) * 10);
line(axes1, [avg avg], ylim, 'Color','red');
text(avg + 0.5, ymax - 0.02, sprintf('%.3f', avg), 'Color', 'red', 'FontSize', fs);

if self.Env.print
    % painters option ensures no OpenGL and thus true vector graphics
    sigma = strrep(sprintf('%1.4f', self.Interest.sigma), '.', '_dot_');
    filename = sprintf('sigma_r_%s_purchase_ages_%d-%d_claim_distribution.pdf', ...
                       sigma, ...
                       self.eligibleAnnuityPurchaseAges(1), ...
                       self.eligibleAnnuityPurchaseAges(end));
    print([self.Env.outdir filesep filename],  '-painters', '-dpdf', '-bestfit');
    close(figure1);
end

end
