function alignFigure(fig, index, fig_reference)
%% Align Current Figure Window in a Grid
% assumes that monitors aren't stacked on top of each other

if nargin < 3; fig_reference = fig; end

grid_dim = [2, 3];
imargins = [10, 10];
omargins = [10, 50];

monitor_positions = sortrows(get(0, 'MonitorPositions'));
pos = fig_reference.OuterPosition;
monitor_index = find(pos(1) >= monitor_positions(:,1), 1, 'last');
monitor_pos = monitor_positions(monitor_index,:);

[index_x, index_y] = ind2sub(grid_dim([2 1]), index);
index_y = mod(index_y - 1, grid_dim(1)) + 1;
pos(3) = (monitor_pos(3) - (grid_dim(2) - 1) * imargins(1) - 2 * omargins(1)) / grid_dim(2);
pos(4) = (monitor_pos(4) - (grid_dim(1) - 1) * imargins(2) - 2 * omargins(2)) / grid_dim(1);
pos(1) = monitor_pos(1) + omargins(1) + (index_x - 1) * (pos(3) + imargins(1));
pos(2) = monitor_pos(2) + omargins(2) + (grid_dim(1) - index_y) * (pos(4) + imargins(2));
fig.OuterPosition = pos;

pause(0.1);
warning_state = warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved');
fig_java = get(handle(fig), 'JavaFrame');
warning(warning_state);
fig_java.setMaximized(false);

fig_prev = gcf();
figure(fig);
pause(0.1);
figure(fig_prev);
