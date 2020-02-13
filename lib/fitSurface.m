function surfaces = fitSurface(data, type, printPlot)

if nargin < 3
    printPlot = 0;
end


switch type
    case 'value'
        bl = 'VL';
        tol = 'VTol';
        nIns = 'nVIns';
    case 'policy'
        bl = 'PL';
        tol = 'PTol';
        nIns = 'nPIns';
end

dims = unique(data.d)';
surfaces = cell(length(dims), 1);
if printPlot
    xlimits = [-25, -5];
    ylimits = [1, 6];
    n = 100;
    [XX, YY] = meshgrid(linspace(xlimits(1), xlimits(end), n), ...
                        linspace(ylimits(1), ylimits(end), n));
end

i = 1;
for d = dims
    rows = data.d == d;
    xdata = log(data.(tol)(rows));
    ydata = data.(bl)(rows);
    zdata = data.(nIns)(rows);

    surfaces{i} = scatteredInterpolant(xdata, ydata, zdata, 'linear', 'linear');
    
    if printPlot
        figure;
        scatter3(xdata, ydata, zdata);
        hold on;
        surf(XX, YY, surfaces{i}(XX, YY))
        hold off;
        title(sprintf('d=%u', d));
        xlim(xlimits)
        ylim(ylimits)
        xlabel('log(\epsilon)')
        ylabel('level')
        zlabel(nIns)
    end
    
    i = i + 1;
end

end
