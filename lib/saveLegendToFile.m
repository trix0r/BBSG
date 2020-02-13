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
print(figHandle, fullFilename,  '-painters', '-dpdf');

warning ('on', 'all');

end
