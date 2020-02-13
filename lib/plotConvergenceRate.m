function plotConvergenceRate(tbl, policyName, outdir, saveLegend)

%% initialize figures
fs = 20;
figure1 = figure;
axes1 = axes('Parent', figure1, 'FontSize', fs);
hold(axes1, 'on');
axes1.XScale = 'log';
axes1.YScale = 'log';
xlim([min(tbl.nPPts), max(tbl.nPPts)]);
ylim([10^-8, 10^2]);

%% plot errors in log-log scale
% own color definitions
blue = [0.000,0.447,0.741];
red = [0.850,0.325,0.098];
loglog(axes1, tbl.nPPts, tbl.GL2, 'o-', 'LineWidth', 2, 'Color', blue, 'MarkerFaceColor', blue);
loglog(axes1, tbl.nPPts, tbl.GLInf, 'o:', 'LineWidth', 2, 'Color', blue, 'MarkerFaceColor', blue);
loglog(axes1, tbl.nPPts, tbl.EL2, 'o-', 'LineWidth', 2,  'Color', red, 'MarkerFaceColor', red);
loglog(axes1, tbl.nPPts, tbl.ELInf, 'o:', 'LineWidth', 2,  'Color', red, 'MarkerFaceColor', red);
xlabel(axes1, '$\bar{N}$', 'Interpreter', 'latex')

%% print plot
if exist('outdir', 'var')
    modelName = unique(lower(tbl.Model));
    % painters option ensures no OpenGL and thus true vector graphics
    filename = sprintf('%s_%s_convergence.pdf', modelName{:}, policyName);
    print(figure1, [outdir filesep filename],  '-painters', '-dpdf', '-bestfit');

    % print legend to separate file
    if exist('saveLegend', 'var') && saveLegend == true
        labels = {'$L^2$','$L^{\infty}$', '$\tilde{L}^2$', '$\tilde{L}^{\infty}$'};
        legend1 = legend(axes1, labels, 'Location', 'northoutside', 'Orientation', ...
                         'horizontal', 'Interpreter', 'latex', 'FontSize', fs);
        filename = sprintf('%s_convergence_legend.pdf', modelName{:});
        saveLegendToFile(figure1, legend1, [outdir filesep filename])
    end
    close(figure1);
end

end

function saveLegendToFile(figHandle, legHandle, fullFilename)
% source: https://stackoverflow.com/questions/18117664/how-can-i-show-only-the-legend-in-matlab
%make all contents in figure invisible
allLineHandles = findall(figHandle, 'type', 'line');

%ignore warnings
warning ('off', 'all');
for i = 1:length(allLineHandles); allLineHandles(i).XData = NaN; end

%make axes invisible
axis off

%move legend to lower left corner of figure window
legHandle.Units = 'pixels';
boxLineWidth = legHandle.LineWidth;
%save isn't accurate and would swallow part of the box without factors
legHandle.Position = [6 * boxLineWidth, 6 * boxLineWidth, ...
                      legHandle.Position(3), legHandle.Position(4)];
legLocPixels = legHandle.Position;

%make figure window fit legend
figHandle.Units = 'pixels';
figHandle.InnerPosition = [1, 1, legLocPixels(3) + 12 * boxLineWidth, ...
                           legLocPixels(4) + 12 * boxLineWidth];

%save legend
print(figHandle, fullFilename,  '-painters', '-dpdf', '-bestfit');

warning ('on', 'all');

end
