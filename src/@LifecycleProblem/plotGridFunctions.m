function plotGridFunctions(self, functions, discreteState, labels, statuses)

if nargin < 4
    labels = cellfun(@(i) sprintf('Function %u', i), num2cell(1:numel(functions)), ...
                     'UniformOutput', false);
end

if nargin < 5
    statuses = cell(size(functions));
end



%% Parameters
% bounds for age and state variables
bounds = [self.Time.ageStart self.Grid.lowerBounds; ...
          self.Time.ageStop  self.Grid.upperBounds];
% number of time steps
times = self.Time.getRange();
% unique ID
guid_prefix = sprintf('guid%u_', floor(1000 * posixtime(datetime())));



%% Creation of GUI
h = 1/(self.numberOfStates+4);
h2 = 0.8 * h;
hf = figure('Name', 'Controls', 'NumberTitle', 'off', ...
            'UserData', {guid_prefix, functions}, 'Tag', [guid_prefix 'fig_gui'], ...
            'CloseRequestFcn', @gui_controls_close);
alignFigure(hf, 1);
pause(0.2);
pos = hf.Position;
pos(4) = 200;
hf.Position = pos;

% cell array which contains the strings of time and state variables
var_str = cell(1, self.numberOfStates + 1);
for i = 0:self.numberOfStates
    var_str{i+1} = state_var(self, i);
end

% popup menus for selecting the current "variable variables"
for i = 0:1
    hui = uicontrol('Style', 'text', 'String', ['Variable ' num2str(i+1) ':'], ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', 'Position', [i*0.5 1-h 0.2 h2]);
    set(findjobj(hui), 'VerticalAlignment', 0);

    cur_var_str = var_str;
    if self.numberOfStates > 1
        cur_var_str(3-i) = []; 
    elseif i == 1
        cur_var_str = fliplr(var_str);
    end
    uicontrol('Style', 'popupmenu', 'String', cur_var_str, 'Value', 2, ...
            'Callback', @gui_list_var_change, 'UserData', {guid_prefix, self, i + 1}, ...
            'Tag', [guid_prefix 'list_var' num2str(i+1)], ...
            'Units', 'normalized', 'Position', [i*0.5+0.2 1-h 0.25 h2]);
end

% sliders for setting the value of the "fixed variables"
for i = 0:self.numberOfStates
    if (i == 1) || (i == 2) || (self.numberOfStates == 1)
        enabled = 'off';
    else
        enabled = 'on';
    end
    
    hui = uicontrol('Style', 'text', 'String', [var_str{i+1} ' = '], ...
            'HorizontalAlignment', 'left', 'Enable', enabled, ...
            'Tag', [guid_prefix 'label_slider_var' num2str(i)], ...
            'Units', 'normalized', 'Position', [0 1-(i+2)*h 0.2 h2]);
    set(findjobj(hui), 'VerticalAlignment', 0);
    
    if i == 0
        value = bounds(2,1);
        slider_step = [1/(numel(times)-1), 10/(numel(times)-1)];
    else
        value = sum(bounds(:,i+1)) / 2;
        slider_step = [1/64, 1/8];
    end
    
    hui = uicontrol('Style', 'slider', 'Enable', enabled, ...
            'Units', 'normalized', 'Position', [0.2 1-(i+2)*h 0.8 h2], ...
            'Callback', @gui_slider_var_change, ...
            'UserData', {guid_prefix, self}, ...
            'Tag', [guid_prefix 'slider_var' num2str(i)], ...
            'Min', bounds(1,i+1), ...
            'Max', bounds(2,i+1), ...
            'Value', value, ...
            'SliderStep', slider_step);
    gui_slider_var_change(hui);
end

% checkboxes at the bottom
uicontrol('Style', 'checkbox', 'String', 'Extrapolate', 'Value', 0, ...
    'Tag', [guid_prefix 'checkbox_extrapolate'], ...
    'Units', 'normalized', 'Position', [0 h 0.25 h2]);
uicontrol('Style', 'checkbox', 'String', 'Domain trafo.', 'Value', 1, ...
    'Tag', [guid_prefix 'checkbox_domain_trafo'], ...
    'Units', 'normalized', 'Position', [0.25 h 0.25 h2]);
uicontrol('Style', 'checkbox', 'String', 'Value trafo.', 'Value', 1, ...
    'Tag', [guid_prefix 'checkbox_value_trafo'], ...
    'Units', 'normalized', 'Position', [0.5 h 0.25 h2]);
uicontrol('Style', 'checkbox', 'String', 'Use B-splines', 'Value', 0, ...
    'Tag', [guid_prefix 'checkbox_bsplines'], ...
    'Units', 'normalized', 'Position', [0.75 h 0.25 h2]);

% buttons at the bottom
hui = uicontrol('Style', 'pushbutton', 'String', 'Recompute', ...
    'Callback', @gui_recompute, ...
    'UserData', {guid_prefix, self, functions, discreteState, labels, statuses, ...
                 times, bounds}, ...
    'Units', 'normalized', 'Position', [0 0 0.54 h2]);
uicontrol('Style', 'pushbutton', 'String', 'Save', ...
    'Callback', @gui_save, 'UserData', {guid_prefix, functions}, ...
    'Units', 'normalized', 'Position', [0.56 0 0.13 h2]);
uicontrol('Style', 'pushbutton', 'String', 'Realign', ...
    'Callback', @gui_realign, 'UserData', {guid_prefix, functions}, ...
    'Units', 'normalized', 'Position', [0.71 0 0.13 h2]);
uicontrol('Style', 'pushbutton', 'String', 'plotJ', ...
    'Callback', @gui_plotJ, 'UserData', {guid_prefix, self, functions, discreteState}, ...
    'Units', 'normalized', 'Position', [0.86 0 0.13 h2]);

% recompute now
gui_recompute(hui);



function gui_recompute(h, ~)
%% Recompute Button Pressed

%% Variables
user_data = get(h, 'UserData');
[guid_prefix, self, functions, discreteState, labels, statuses, times, bounds] = ...
    user_data{:};

set(h, 'String', 'Computing...');
pause(0.01);

% x_fixed(i) = NaN for both of the "variable variables";
% x_fixed(i) = some_value for the "fixed variables",
% where some_value is the value the variable is fixed to
i1 = get_selected_variable(self, findobj('Tag', [guid_prefix 'list_var1']));
i2 = get_selected_variable(self, findobj('Tag', [guid_prefix 'list_var2']));
x_fixed = nan(1, self.numberOfStates+1);
for i = 0:self.numberOfStates
    if (i == 0) || ((i ~= i1) && (i ~= i2))
        tag = [guid_prefix 'slider_var' num2str(i)];
        x_fixed(i+1) = get(findobj('Tag', tag), 'Value');
    end
end

% round time to full time steps
x_fixed(1) = round(x_fixed(1));
% calculate time index, only makes sense if time is "fixed variable"
t = self.Time.copy();
t.age = x_fixed(1);

identityTrafo = [];

extrapolate      =  get(findobj('Tag', [guid_prefix 'checkbox_extrapolate']),  'Value');
resetDomainTrafo = ~get(findobj('Tag', [guid_prefix 'checkbox_domain_trafo']), 'Value');
resetValueTrafo  = ~get(findobj('Tag', [guid_prefix 'checkbox_value_trafo']),  'Value');
useLinearBasis   = ~get(findobj('Tag', [guid_prefix 'checkbox_bsplines']),     'Value');

% indices of "fixed" states, excluding time (which would be state 0)
fs_I = [i1 i2];
fs_I(fs_I == 0) = [];

if resetDomainTrafo
    bounds(:,fs_I+1) = repmat([0; 1], 1, numel(fs_I));
end

plotBounds = bounds;

if extrapolate
    extrapolateFactor = 0.2;
    additionalRange = extrapolateFactor * diff(plotBounds(:,fs_I+1));
    plotBounds(1,fs_I+1) = plotBounds(1,fs_I+1) - additionalRange;
    plotBounds(2,fs_I+1) = plotBounds(2,fs_I+1) + additionalRange;
end

%% Evaluation Points
% make surface plot have as many rows/columns as there are time steps,
% if one of the "variable variables" is time
if i1 ~= 0; nxx = 100; else; nxx = numel(times); end
if i2 ~= 0; nyy = 100; else; nyy = numel(times); end
% generate mesh grid over "variable variables"
xx = linspace(plotBounds(1,i1+1), plotBounds(2,i1+1), nxx);
yy = linspace(plotBounds(1,i2+1), plotBounds(2,i2+1), nyy);
[XX, YY] = meshgrid(xx, yy);
NN = numel(XX);
% extend mesh to all state dimensions (fill with values of "fixed variables")
XXYY = repmat(x_fixed, NN, 1);
XXYY(:,i1+1) = XX(:);
XXYY(:,i2+1) = YY(:);

%% Determine success status by optimizer type
switch self.Optimizer.routine
    case {'snopt', 'npsol'}
        successStatus = 0;
    case 'fmincon'
        successStatus = 1;
    case 'patternsearch'
        successStatus = 1 : 4;
    otherwise
        error('Unsupported optimizer chosen!')
end

%% Plot of Functions
% for each function value entry
for j = 1:numel(functions)
    clear('opt');
    
    if (i1 == 0) || (i2 == 0)
        opt = cell(1, self.Time.getStop().index);

        for t = times
            if isempty(functions{j}{t})
                opt{t} = [];
            else
                opt{t} = functions{j}{t}.(discreteState);
            end

            if isa(opt{t}, 'SgppInterpolant')
                if useLinearBasis
                    opt{t} = opt{t}.copy(self.Basis.linearType);
                else
                    opt{t} = opt{t}.copy(self.Basis.BsplineType, ...
                                         self.Basis.BsplineDegree);
                end

                if resetDomainTrafo
                    OldDomainTrafo = opt{t}.DomainTrafo;
                    if isempty(OldDomainTrafo)
                        NewDomainTrafo = [];
                    else
                        NewDomainTrafo.map   = ...
                            @(X) modified_trafo(X, OldDomainTrafo.map(X),   fs_I);
                        NewDomainTrafo.inv   = ...
                            @(X) modified_trafo(X, OldDomainTrafo.inv(X),   fs_I);
                        NewDomainTrafo.deriv = ...
                            @(X) modified_trafo(X, OldDomainTrafo.deriv(X), fs_I);
                    end
                    opt{t}.setDomain(bounds(1,2:end), bounds(2,2:end), NewDomainTrafo);
                end

                if resetValueTrafo
                    opt{t}.setValueTrafo(identityTrafo);
                end
            end
        end
    else
        if isempty(functions{j}{t})
            opt = [];
        else
            opt = functions{j}{t}.(discreteState);
        end

        if isa(opt, 'SgppInterpolant')
            if useLinearBasis
                opt = opt.copy(self.Basis.linearType);
            else
                opt = opt.copy(self.Basis.BsplineType, self.Basis.BsplineDegree);
            end

            if resetDomainTrafo
                OldDomainTrafo = opt.DomainTrafo;
                if isempty(OldDomainTrafo)
                    NewDomainTrafo = [];
                else
                    NewDomainTrafo.map   = ...
                        @(X) modified_trafo(X, OldDomainTrafo.map(X),   fs_I);
                    NewDomainTrafo.inv   = ...
                        @(X) modified_trafo(X, OldDomainTrafo.inv(X),   fs_I);
                    NewDomainTrafo.deriv = ...
                        @(X) modified_trafo(X, OldDomainTrafo.deriv(X), fs_I);
                end
                opt.setDomain(bounds(1,2:end), bounds(2,2:end), NewDomainTrafo);
            end

            if resetValueTrafo
                opt.setValueTrafo(identityTrafo);
            end
        end
    end
    
    % select figure/select if already exists
    tag = [guid_prefix 'fig_fcn' num2str(j)];
    hf = findobj('Tag', tag);
    
    if isempty(hf)
        figure('Tag', tag);
        alignFigure(gcf(), j+1);
        ha = axes();
    else
        ha = findall(hf, 'Type', 'axes');
        [az, el] = view(ha);
    end
    
    cla(ha);
    hold(ha, 'on');

    % evaluate interpolant
    if (i1 == 0) || (i2 == 0)
        % time is a "variable variable"
        % ==> evaluate interpolants for each time step
        if isa(opt{end-1}, 'SgppInterpolant')
            ZZ = nan(size(XX));

            for t = times
                if isa(opt{t}, 'SgppInterpolant')
                    % fit
                    opt{t}.fit(opt{t}.values);
                    % select mesh grid points of time t
                    K = (XXYY(:,1) == t.age);
                    % evaluate, assuming time is first "variable variable"
                    if i2 == 0; ZZ = ZZ'; end
                    ZZ(:,t) = opt{t}.evaluate(XXYY(K,2:end));
                    if i2 == 0; ZZ = ZZ'; end
                end
            end

            % surface plot
            surf(ha, XX, YY, reshape(ZZ, size(XX)));
        elseif isstruct(opt{end-1})
            xx2 = cell(1, numel(times));
            yy2 = xx2;
            zz2 = xx2;

            for t = times
                if isstruct(opt{t})
                    nn2 = size(opt{t}.points, 1);

                    if i1 == 0
                        xx2{t} = t.age * ones(1, nn2);
                        yy2{t} = opt{t}.points(:,i2)';
                    else
                        xx2{t} = opt{t}.points(:,i1)';
                        yy2{t} = t.age * ones(1, nn2);
                    end

                    zz2{t} = opt{t}.data;
                end
            end

            xx2 = horzcat(xx2{:});
            yy2 = horzcat(yy2{:});
            zz2 = horzcat(zz2{:});
            %scatter3(ha, xx2, yy2, zz2, 30, zz2, 'filled');
            tri = delaunay(xx2, yy2);
            axes(ha); %#ok<*LAXES>
            trisurf(tri, xx2, yy2, zz2);
        end

        % I contains all the indices of the fixed state variables
        % (but not 0, even if the time is fixed)
        I = 0:self.numberOfStates;
        I([1 i1+1 i2+1]) = [];

        tmp_x_fixed = nan(1, length(I));

        % plot grid points for each time
        for t = times
            if isa(opt{t}, 'SgppInterpolant')
                X = [t.age * ones(size(opt{t}.gridPoints, 1), 1), ...
                     opt{t}.gridPoints];
                fX = opt{t}.values;
            else
                continue;
            end

            % select all grid points where the values corresponding to the
            % "fixed variables" are equal to the values set by the user
            if ~isempty(I)
                for i = 1:length(I)
                    tmp_x_fixed(i) = x_fixed(I(i)+1);
                end
            else
                tmp_x_fixed = x_fixed(I+1);
            end

            K = all(abs(bsxfun(@minus, X(:,I), tmp_x_fixed)) < 1e-6, 2);

            % plot grid points
            plot3(ha, X(K,i1+1), X(K,i2+1), fX(K), ...
                  'k.', 'MarkerSize', 10);

            if ~isempty(statuses{j}) && ~isempty(statuses{j}{t})
                K = K & (all(statuses{j}{t} ~= successStatus)) & ~isnan(statuses{j}{t});
                plot3(ha, X(K,i1+1), X(K,i2+1), fX(K), ...
                      'ro', 'MarkerSize', 10);

                [~, d] = version;
                if datetime(d) > datetime('01-Jan-2016')
                    for k = find(K)'
                        text(ha, X(K,i1+1), X(k,i2+1), fX(k), ...
                             sprintf('  %u', statuses{j}{t}(k)), ...
                             'Color', 'r');
                    end
                end
            end
        end
    else
        % time is a "fixed variable"
        % ==> select interpolant of that time
        if isa(opt, 'SgppInterpolant')
            % fit
            opt.fit(opt.values);
            % evaluate
            ZZ = opt.evaluate(XXYY(:,2:end));

            % surface plot
            surf(ha, XX, YY, reshape(ZZ, size(XX)));

            % I contains all the indices of the fixed state variables
            % (but not 0, even if the time is fixed)
            I = 0:self.numberOfStates;
            I([1 i1+1 i2+1]) = [];

            % plot grid points of selected time
            X = opt.gridPoints;

            % select all grid points where the values corresponding to the
            % "fixed variables" are equal to the values set by the user
            tmp_x_fixed = x_fixed(I+1);
            K = all(abs(bsxfun(@minus, X(:,I), tmp_x_fixed)) < 1e-6, 2);

            % plot grid points
            plot3(ha, X(K,i1), X(K,i2), opt.values(K), 'k.', 'MarkerSize', 10);

            if ~isempty(statuses{j}) && ~isempty(statuses{j}{t})
                K = K & (all(statuses{j}{t} ~= successStatus)) & ~isnan(statuses{j}{t});
                plot3(ha, X(K,i1), X(K,i2), opt.values(K), 'ro', 'MarkerSize', 10);

                [~, d] = version;
                if datetime(d) > datetime('01-Jan-2016')
                    for k = find(K)'
                        text(ha, X(k,i1), X(k,i2), opt.values(k), ...
                             sprintf('  %u', statuses{j}{t}(k)), 'Color', 'r');
                    end
                end
            end
        elseif isstruct(opt)
            xx2 = opt.points(:,i1);
            yy2 = opt.points(:,i2);
            zz2 = opt.data;
            %scatter3(ha, xx2, yy2, zz2, 30, zz2, 'filled');
            tri = delaunay(xx2, yy2);
            axes(ha);
            trisurf(tri, xx2, yy2, zz2);
        end
    end
    
    % make title
    title_str = labels{j};
    
    if self.numberOfStates > 2
        title_str = [title_str ' (']; %#ok<AGROW>
        first = true;
        for i = 0:self.numberOfStates
            if (i ~= i1) && (i ~= i2)
                if ~first
                    title_str = [title_str ', ']; %#ok<AGROW>
                end
                title_str = sprintf('%s%s = %g', title_str, ...
                                    state_var(self, i), x_fixed(i+1));
                first = false;
            end
        end
        title_str = [title_str ')']; %#ok<AGROW>
    end
    
    title(ha, title_str, 'Interpreter', 'tex');
    
    % plot settings
    axis(ha, 'square');
    axis(ha, 'tight');
    xlabel(ha, state_var(self, i1), 'Interpreter', 'tex');
    ylabel(ha, state_var(self, i2), 'Interpreter', 'tex');
    colorbar('peer', ha);
    grid(ha, 'on');
    
    if isempty(hf)
        rotate3d(ha, 'on');
        view(ha, 3);
    else
        view(ha, [az, el]);
    end
end

set(h, 'String', 'Recompute');



function gui_controls_close(h, ~)
%% Controls Window Close Requested

user_data = get(h, 'UserData');
[guid_prefix, functions] = user_data{:};

% close controls window
delete(h);

% close figure windows
for j = 1:numel(functions)
    tag = [guid_prefix 'fig_fcn' num2str(j)];
    hf = findobj('Tag', tag);
    close(hf);
end



function gui_save(h, ~)
%% Save Button Pressed

% display save dialog
[filename, directory] = uiputfile({ ...
    '*.fig', 'MATLAB Figure (*.fig)'; ...
    '*.png', 'Portable Network Graphics file (*.png)'; ...
    '*.pdf', 'Portable Document Format (*.pdf)'; ...
    '*.eps', 'EPS file (*.eps)'});

if filename == 0
    return;
end

path = [directory filename];
user_data = get(h, 'UserData');
[guid_prefix, functions] = user_data{:};
hfs = cell(1, numel(functions));

% get handle of figures to be saved
for j = 1:numel(functions)
    tag = [guid_prefix 'fig_fcn' num2str(j)];
    hfs{j} = findobj('Tag', tag);
end

if strcmp(filename(end-3:end), '.fig')
    % save as *.fig in one file
    hfs = horzcat(hfs{:});
    savefig(hfs, path);
else
    % save as *.png/*.pdf/*.eps/ in separate files
    format = filename(end-2:end);
    for j = 1:numel(functions)
        if isempty(hfs{j}); continue; end
        current_path = sprintf([...
            '%s_entry%0' num2str(floor(log10(numel(functions))) + 1) 'd%s'], ...
            path(1:end-4), j, path(end-3:end));
        % use '-painters' renderer to ensure true vector graphics
        if strcmp(format, 'pdf')
            % use '-bestfit' to preserve aspect ratios
            print(hfs{j}, current_path, ['-d' format], '-painters', '-bestfit');
        elseif strcmp(format, 'eps')
            print(hfs{j}, current_path, ['-d' format], '-painters');
        else
            print(hfs{j}, current_path, ['-d' format]);
        end
    end
end



function gui_realign(h, ~)
%% Realign Button Pressed

user_data = get(h, 'UserData');
[guid_prefix, functions] = user_data{:};

hf = findobj('Tag', [guid_prefix 'fig_gui']);
alignFigure(hf, 1);
pos = hf.Position;
pos(4) = 200;
hf.Position = pos;
hf_gui = hf;

for j = 1:numel(functions)
    tag = [guid_prefix 'fig_fcn' num2str(j)];
    hf = findobj('Tag', tag);
    alignFigure(hf, j+1, hf_gui);
end



function gui_plotJ(h, ~)
%% plotJ Button Pressed

user_data = get(h, 'UserData');
[guid_prefix, self, functions, discreteState] = user_data{:};

i1 = get_selected_variable(self, findobj('Tag', [guid_prefix 'list_var1']));
i2 = get_selected_variable(self, findobj('Tag', [guid_prefix 'list_var2']));
x_fixed = nan(1, self.numberOfStates+1);
for i = 0:self.numberOfStates
    if (i == 0) || ((i ~= i1) && (i ~= i2))
        tag = [guid_prefix 'slider_var' num2str(i)];
        x_fixed(i+1) = get(findobj('Tag', tag), 'Value');
    end
end

% round time to full time steps
x_fixed(1) = round(x_fixed(1));
pos = [];

for j = 1
    tag = [guid_prefix 'fig_fcn' num2str(j)];
    hf = findobj('Tag', tag);
    hdcm = datacursormode(hf);
    
    if strcmp(hdcm.Enable, 'on')
        ci = getCursorInfo(hdcm);
        pos = ci.Position;
        break;
    end
end

if isempty(pos); return; end

display(pos);

% calculate time index and selected state
x_fixed([i1+1 i2+1]) = pos([1 2]);
t = self.Time.copy();
t.age = x_fixed(1);

opt = functions{j}{t}.(discreteState);

if i1 == 0;     i_not_time = i2;
elseif i2 == 0; i_not_time = i1;
else;           i_not_time = [i1+1 i2+1];
end

if ~get(findobj('Tag', [guid_prefix 'checkbox_domain_trafo']), 'Value')
    x_fixed(i_not_time) = opt.mapUnitCubeToDomain(x_fixed(i_not_time));
end

display(x_fixed);

gridPoints = opt.gridPoints;
[~, gridIdx] = min(sum(bsxfun(@minus, gridPoints, x_fixed(2:end)).^2, 2));
state = gridPoints(gridIdx,:);

display(state);

previousSolution.interpOptJ.(discreteState) = functions{j}{t+1}.(discreteState).copy( ...
    self.Basis.BsplineType, self.Basis.BsplineDegree);

self.plotJ(previousSolution, state, discreteState, t);



function gui_slider_var_change(h, ~)
%% State Variable Slider Value Changed

% refresh value in label
user_data = get(h, 'UserData');
[guid_prefix, self] = user_data{:};
var = get(h, 'Tag');
var = str2double(var(11+numel(guid_prefix):end));
value = get(h, 'Value');
if var == 0; value = round(value); end
str = [state_var(self, var) ' = ' num2str(value)];
set(findobj('Tag', [guid_prefix 'label_slider_var' num2str(var)]), 'String', str);



function gui_list_var_change(h, ~)
%% Popup Menu Selection Changed

user_data = get(h, 'UserData');
[guid_prefix, self, old_var] = user_data{:};

% remove newly selected variable in other popup menu,
% add previously selected variable to other popup menu
if strcmp(get(h, 'Tag'), [guid_prefix 'list_var1'])
    other_h = findobj('Tag', [guid_prefix 'list_var2']);
else
    other_h = findobj('Tag', [guid_prefix 'list_var1']);
end

old_other_value = get(other_h, 'Value');

new_var = get_selected_variable(self, h);
other_var = get_selected_variable(self, other_h);

other_var_str = cell(1, self.numberOfStates + 1);
for i = 0:self.numberOfStates
    other_var_str{i+1} = state_var(self, i);
end
other_var_str(new_var+1) = [];
set(other_h, 'String', other_var_str);

new_other_value = old_other_value;
if old_var < other_var; new_other_value = new_other_value + 1; end
if new_var < other_var; new_other_value = new_other_value - 1; end
set(other_h, 'Value', new_other_value);

% enable/disable labels and sliders
set(findobj('Tag', [guid_prefix 'label_slider_var' num2str(old_var)]), 'Enable', 'on');
set(findobj('Tag', [guid_prefix 'label_slider_var' num2str(new_var)]), 'Enable', 'off');
set(findobj('Tag', [guid_prefix 'slider_var' num2str(old_var)]), 'Enable', 'on');
set(findobj('Tag', [guid_prefix 'slider_var' num2str(new_var)]), 'Enable', 'off');

% save new variable so that next time, the previously selected variable
% can be obtained
set(h, 'UserData', {guid_prefix, self, new_var});



function var = get_selected_variable(self, h)
%% Index of the Selected State Variable in the Popup Menu h

vars = get(h, 'String');
var = state_var(self, vars{get(h, 'Value')});



function s = state_var(self, i)
%% Convert State Variable Index to String and Vice-Versa

S = horzcat({'t'}, self.stateNames);
if isnumeric(i); s = S{i+1}; else; s = find(strcmp(S, i)) - 1; end



function X_new = modified_trafo(X, trafo, T)
%% Replace Transformation by Identity for Selected State Dimensions

X_new = trafo;
X_new(:,T) = X(:,T);
