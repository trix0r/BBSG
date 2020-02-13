function plotJ(self, varargin)

if numel(varargin) == 1
    if exist(varargin{1}, 'file')
        filename = varargin{1};
    else
        id = varargin{1};
        filename = sprintf('%s%splotJ_%s.mat', ...
                           self.Env.logdir, filesep, id);
    end
    loadVariables(filename, 'previousSolution', 'state', 'discreteState', 't');
else
    previousSolution = varargin{1};
    state = varargin{2};
    discreteState = varargin{3};
    t = varargin{4};
    if numel(varargin) >= 5; initialPolicy = varargin{5}; end
end

% determine bounding box of all linear inequality constraints
policyBounds = getPolicyBoundingBox(self, state, discreteState, t);

if ~exist('initialPolicy', 'var') || isempty(initialPolicy)
    fprintf(sprintf('ID                 Code   State  %s\n', ...
                    strtrim(repmat('%8s ', 1, self.numberOfStates))), self.stateNames{:});
    [~, optPolicy] = self.computeOptimalPolicy( ...
                            previousSolution, state, discreteState, t, false);
    fprintf('\n');

    initialPolicy = nan(1, self.numberOfPolicies);

    for p = 1:self.numberOfPolicies
        policyName = self.policyNames{p};
        initialPolicy(p) = optPolicy.(policyName);
    end
end

[Info, initialJ, initialGradJ] = self.getJ(previousSolution, initialPolicy, ...
                                           state, discreteState, t);
shocks = self.computeShockDistribution(state, discreteState, t);
initialNoOfExtrap = Info.numberOfExtrapolations / size(shocks, 1);

assert(numel(state) == self.numberOfStates, ...
       'state must be a vector with numberOfStates entries.');
assert(all(size(policyBounds) == [2, self.numberOfPolicies]), ...
       'policyBounds must be a matrix of size 2 x.numberOfPolicies');
assert(numel(initialPolicy) == self.numberOfPolicies, ...
       'initialPolicy must be a vector with numberOfPolicies entries.');
% unique ID
guidPrefix = sprintf('guid%u_', floor(1000 * posixtime(datetime())));



%% Creation of GUI
h = 1/(self.numberOfPolicies+4);
h2 = 0.8 * h;
hf = figure('Name', 'Controls', 'NumberTitle', 'off', ...
            'UserData', {guidPrefix}, 'Tag', [guidPrefix 'fig_gui'], ...
            'CloseRequestFcn', @guiControlsClose);
alignFigure(hf, 1);
pause(0.2);
pos = hf.Position;
pos(4) = 300;
hf.Position = pos;

% cell array which contains the strings of policy variables
convertPolicyVar_str = cell(1, self.numberOfPolicies);
for i = 1:self.numberOfPolicies
    convertPolicyVar_str{i} = convertPolicyVar(self, i);
end

% popup menus for selecting the current "variable variables"
if self.numberOfPolicies == 1
    hui = uicontrol('Style', 'text', 'String', 'Variable:', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', 'Position', [0 1-h 0.2 h2]);
    set(findjobj(hui), 'VerticalAlignment', 0);

    cur_var_str = convertPolicyVar_str;
    uicontrol('Style', 'popupmenu', 'String', cur_var_str, 'Value', 1, ...
            'Callback', @guiListVarChange, 'UserData', {guidPrefix, self, 1}, ...
            'Tag', [guidPrefix 'list_var1'], ...
            'Units', 'normalized', 'Position', [0.2 1-h 0.25 h2]);
else
    for i = 0:1
        hui = uicontrol('Style', 'text', 'String', ['Variable ' num2str(i+1) ':'], ...
                'HorizontalAlignment', 'left', ...
                'Units', 'normalized', 'Position', [i*0.5 1-h 0.2 h2]);
        set(findjobj(hui), 'VerticalAlignment', 0);

        cur_var_str = convertPolicyVar_str;
        cur_var_str(2-i) = [];
        uicontrol('Style', 'popupmenu', 'String', cur_var_str, 'Value', 1, ...
                'Callback', @guiListVarChange, 'UserData', {guidPrefix, self, i + 1}, ...
                'Tag', [guidPrefix 'list_var' num2str(i+1)], ...
                'Units', 'normalized', 'Position', [i*0.5+0.2 1-h 0.25 h2]);
    end
end

% values of state variables
hui = uicontrol('Style', 'text', 'String', '', 'HorizontalAlignment', 'left', ...
        'Tag', [guidPrefix 'label_state_var'], ...
        'Units', 'normalized', 'Position', [0 1-2*h 1 h2]);
set(findjobj(hui), 'VerticalAlignment', 0);
s = 'States: ';
for i = 1:self.numberOfStates
    if i > 1; s = [s ', ']; end %#ok<AGROW>
    s = [s self.stateNames{i} ' = ' num2str(state(i))]; %#ok<AGROW>
end
set(hui, 'String', textwrap(hui, {s}));

% policy sliders
for i = 1:self.numberOfPolicies
    if (i == 1) || (i == 2)
        enabled = 'off';
    else
        enabled = 'on';
    end
    
    y = 1 - (i + 2) * h;
    hui = uicontrol('Style', 'text', 'String', [convertPolicyVar_str{i} ' = '], ...
            'HorizontalAlignment', 'left', 'Enable', enabled, ...
            'Tag', [guidPrefix 'label_slider_var' num2str(i)], ...
            'Units', 'normalized', 'Position', [0 y 0.35 h2]);
    set(findjobj(hui), 'VerticalAlignment', 0);
    
    value = initialPolicy(i);
    sliderStep = [1/64, 1/8];
    
    hui = uicontrol('Style', 'slider', 'Enable', enabled, ...
            'Units', 'normalized', 'Position', [0.35 y 0.5 h2], ...
            'Callback', @guiSliderVarChange, ...
            'UserData', {guidPrefix, self, i}, ...
            'Tag', [guidPrefix 'slider_var' num2str(i)], ...
            'Min', policyBounds(1,i), ...
            'Max', policyBounds(2,i), ...
            'Value', value, ...
            'SliderStep', sliderStep);
    
    uicontrol('Style', 'pushbutton', 'Enable', enabled, 'String', 'Reset', ...
        'Tag', [guidPrefix 'reset_var' num2str(i)], ...
        'Callback', @guiReset, ...
        'UserData', {guidPrefix, initialPolicy, i}, ...
        'Units', 'normalized', 'Position', [0.86 y 0.1 h2]);
    
    uicontrol('Style', 'checkbox', 'String', '', ...
        'Tag', [guidPrefix 'deriv_var' num2str(i)], ...
        'UserData', {guidPrefix, i}, ...
        'Units', 'normalized', 'Position', [0.97 y 0.03 h2]);
    
    guiSliderVarChange(hui);
end

% checkboxes at the bottom
uicontrol('Style', 'checkbox', 'String', 'Show derivatives', 'Value', 0, ...
    'Tag', [guidPrefix 'checkbox_deriv'], ...
    'Units', 'normalized', 'Position', [0 h 0.33 h2]);
uicontrol('Style', 'checkbox', 'String', 'Show finite differences', 'Value', 0, ...
    'Tag', [guidPrefix 'checkbox_finite_diff'], ...
    'Units', 'normalized', 'Position', [0.33 h 0.34 h2]);
uicontrol('Style', 'checkbox', 'String', 'Show derivative error', 'Value', 0, ...
    'Tag', [guidPrefix 'checkbox_deriv_error'], ...
    'Units', 'normalized', 'Position', [0.67 h 0.33 h2]);

% buttons at the bottom
hui = uicontrol('Style', 'pushbutton', 'String', 'Recompute', ...
    'Callback', @guiRecompute, ...
    'UserData', {guidPrefix, self, previousSolution, state, discreteState, t, ...
                 initialPolicy, initialJ, initialNoOfExtrap, initialGradJ}, ...
    'Units', 'normalized', 'Position', [0 0 0.7 h2]);
uicontrol('Style', 'pushbutton', 'String', 'Save', ...
    'Callback', @guiSave, 'UserData', {guidPrefix, self}, ...
    'Units', 'normalized', 'Position', [0.72 0 0.13 h2]);
uicontrol('Style', 'pushbutton', 'String', 'Realign', ...
    'Callback', @guiRealign, 'UserData', {guidPrefix}, ...
    'Units', 'normalized', 'Position', [0.87 0 0.13 h2]);

% recompute now
guiRecompute(hui);



function guiRecompute(h, ~)
%% recompute button pressed

userData = get(h, 'UserData');
[guidPrefix, self, previousSolution, state, discreteState, t, ...
    initialPolicy, initialJ, initialNoOfExtrap, initialGradJ] = userData{:};

set(h, 'String', 'Computing...');
pause(0.01);

i1 = getSelectedVariable(self, findobj('Tag', [guidPrefix 'list_var1']));
if self.numberOfPolicies == 1
    i2 = -1;
else
    i2 = getSelectedVariable(self, findobj('Tag', [guidPrefix 'list_var2']));
end

policyFixed = nan(1, self.numberOfPolicies);
derivCheckboxes = false(1, self.numberOfPolicies);

showDeriv      = get(findobj('Tag', [guidPrefix 'checkbox_deriv']),       'Value');
showFiniteDiff = get(findobj('Tag', [guidPrefix 'checkbox_finite_diff']), 'Value');
showDerivError = get(findobj('Tag', [guidPrefix 'checkbox_deriv_error']), 'Value');

for i = 1:self.numberOfPolicies
    if (i ~= i1) && (i ~= i2)
        tag = [guidPrefix 'slider_var' num2str(i)];
        policyFixed(i) = get(findobj('Tag', tag), 'Value');
    end
    
    derivCheckboxes(i) = get(findobj('Tag', [guidPrefix 'deriv_var' num2str(i)]), 'Value');
end

calculateGradJ = (showDeriv || showDerivError) && any(derivCheckboxes);

if showDeriv || showFiniteDiff || showDerivError
    derivDims = find(derivCheckboxes);
else
    derivDims = [];
end

% determine bounding box of all linear inequality constraints
policyBounds = getPolicyBoundingBox(self, state, discreteState, t, policyFixed);

nxx = 100; nyy = 100;
xx = linspace(policyBounds(1,1), policyBounds(2,1), nxx);
if self.numberOfPolicies == 1
    XX = xx;
    XXYY = XX(:);
    NN = numel(XX);
else
    yy = linspace(policyBounds(1,2), policyBounds(2,2), nyy);
    [XX, YY] = meshgrid(xx, yy);
    NN = numel(XX);

    % extend mesh to all policy dimensions (fill with values of "fixed variables")
    XXYY = repmat(policyFixed, NN, 1);
    XXYY(:,i1) = XX(:);
    XXYY(:,i2) = YY(:);
end

if calculateGradJ
    [J, noOfExtrap, gradJ] = calculateJ(self, previousSolution, state, discreteState, t, XXYY);
else
    [J, noOfExtrap] = calculateJ(self, previousSolution, state, discreteState, t, XXYY);
end

[realOptJ, k] = max(J);
realOptPolicy = XXYY(k,:);

dx = ones(1, self.numberOfPolicies) * 1e3 * self.Optimizer.tolCon;

for i = 1:3
    if calculateGradJ
        [realOptPolicy, realOptJ, realOptNoOfExtrap, realOptGradJ] = ...
                fullGridOptimizer(self, previousSolution, state, ...
                                  discreteState, t, realOptPolicy, dx, i1, i2);
    else
        [realOptPolicy, realOptJ, realOptNoOfExtrap] = ...
                fullGridOptimizer(self, previousSolution, state, ...
                                  discreteState, t, realOptPolicy, dx, i1, i2);
    end
    
    dx = 0.1 * dx;
end

numberOfPlotsPerDerivDim = showDeriv + showFiniteDiff + showDerivError;
numberOfPlots = 2 + numberOfPlotsPerDerivDim * numel(derivDims);
plots(numberOfPlots) = struct('type', [], 'policyIndex', []);
plots(1).type = 'J';
plots(2).type = 'extrap';

finiteDiffJ        = nan(NN, self.numberOfPolicies);
initialFiniteDiffJ = nan(1, self.numberOfPolicies);
realOptFiniteDiffJ = nan(1, self.numberOfPolicies);
K = ~isnan(J);
j = 3;

for q = 1:numel(derivDims)
    i = derivDims(q);

    if showDeriv
        plots(j).type = 'deriv';
        plots(j).policyIndex = i;
        j = j + 1;
    end

    if showFiniteDiff
        plots(j).type = 'finiteDiff';
        plots(j).policyIndex = i;
        j = j + 1;
    end

    if showDerivError
        plots(j).type = 'derivError';
        plots(j).policyIndex = i;
        j = j + 1;
    end

    if showFiniteDiff || showDerivError
        finiteDiffJ(K,i) = calculateFiniteDifference( ...
            self, previousSolution, state, discreteState, t, XXYY(K,:), J(K), i);
        initialFiniteDiffJ(i) = calculateFiniteDifference( ...
            self, previousSolution, state, discreteState, t, initialPolicy, initialJ, i);
        realOptFiniteDiffJ(i) = calculateFiniteDifference( ...
            self, previousSolution, state, discreteState, t, realOptPolicy, realOptJ, i);
    end
end

for j = 1:numel(plots)
    % select figure/select if already exists
    tag = [guidPrefix 'fig_fcn' num2str(j)];
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
    
    switch plots(j).type
        case 'J'
            ZZ = J;
            initialY = initialJ;
            realOptY = realOptJ;
            titleStr = 'J';

            printOptimum(self, state, discreteState, t, 'newOpt', initialPolicy, initialJ);
            printOptimum(self, state, discreteState, t, 'realOpt', realOptPolicy, realOptJ);
            fprintf('\n');
        case 'extrap'
            ZZ = noOfExtrap;
            initialY = initialNoOfExtrap;
            realOptY = realOptNoOfExtrap;
            titleStr = '(#Extrap.)/(#quadr. points)';
        case 'deriv'
            i = plots(j).policyIndex;
            ZZ = gradJ(:,i);
            initialY = initialGradJ(i);
            realOptY = realOptGradJ(i);
            titleStr = sprintf('dJ/d%s', self.policyNames{i});
        case 'finiteDiff'
            i = plots(j).policyIndex;
            ZZ = finiteDiffJ(:,i);
            initialY = initialFiniteDiffJ(i);
            realOptY = realOptFiniteDiffJ(i);
            titleStr = sprintf('Finite diff. appr. of dJ/d%s', self.policyNames{i});
        case 'derivError'
            i = plots(j).policyIndex;
            ZZ = abs(gradJ(:,i) - finiteDiffJ(:,i));
            initialY = abs(initialGradJ(i) - initialFiniteDiffJ(i));
            realOptY = abs(realOptGradJ(i) - realOptFiniteDiffJ(i));
            titleStr = sprintf('Error dJ/d%s and finite diff.', self.policyNames{i});
        otherwise
            error('Unknown plot type.');
    end
    
    % plot
    if self.numberOfPolicies == 1
        plot(ha, XX, ZZ);
    else
        surf(ha, XX, YY, reshape(ZZ, size(XX)));
    end
    
    if all(policyFixed(~isnan(policyFixed)) == initialPolicy(~isnan(policyFixed)))
        if self.numberOfPolicies == 1
            plot(ha, initialPolicy(i1), initialY, 'g.', 'MarkerSize', 15);
        else
            plot3(ha, initialPolicy(i1), initialPolicy(i2), initialY, ...
                  'g.', 'MarkerSize', 15);
        end
    end

    if self.numberOfPolicies == 1
        plot(ha, realOptPolicy(i1), realOptY, 'r.', 'MarkerSize', 15);
    else
        plot3(ha, realOptPolicy(i1), realOptPolicy(i2), realOptY, ...
              'r.', 'MarkerSize', 15);
    end
    
    %if self.numberOfPolicies > 2
    %    titleStr = [titleStr ' (']; %#ok<AGROW>
    %    first = true;
    %    for i = 1:self.numberOfPolicies
    %        if (i ~= i1) && (i ~= i2)
    %            if ~first
    %                titleStr = [titleStr ', ']; %#ok<AGROW>
    %            end
    %            titleStr = sprintf('%s%s = %g', titleStr, ...
    %                               convertPolicyVar(self, i), policyFixed(i));
    %            first = false;
    %        end
    %    end
    %    titleStr = [titleStr ')']; %#ok<AGROW>
    %end
    
    title(ha, titleStr, 'Interpreter', 'tex');
    
    % plot settings
    axis(ha, 'square');
    axis(ha, 'tight');
    xlabel(ha, convertPolicyVar(self, i1), 'Interpreter', 'tex');
    if self.numberOfPolicies > 1; ylabel(ha, convertPolicyVar(self, i2), 'Interpreter', 'tex'); end
    colorbar('peer', ha);
    grid(ha, 'on');
    
    if self.numberOfPolicies > 1
        if isempty(hf)
            rotate3d(ha, 'on');
            view(ha, 3);
        else
            view(ha, [az, el]);
        end
    end
end

set(h, 'String', 'Recompute');



function guiControlsClose(h, ~)
%% controls window close requested

user_data = get(h, 'UserData');
guidPrefix = user_data{:};
numberOfFigures = getNumberOfFigures(guidPrefix);

% close controls window
delete(h);

% close figure windows
for j = 1:numberOfFigures
    tag = [guidPrefix 'fig_fcn' num2str(j)];
    hf = findobj('Tag', tag);
    close(hf);
end



function guiSliderVarChange(h, ~)
%% policy variable slider value changed

% refresh value in label
userData = get(h, 'UserData');
[guidPrefix, self, i] = userData{:};
value = get(h, 'Value');
str = [convertPolicyVar(self, i) ' = ' num2str(value)];
tag = [guidPrefix 'label_slider_var' num2str(i)];
set(findobj('Tag', tag), 'String', str);



function guiReset(h, ~)
%% reset button pressed

userData = get(h, 'UserData');
[guidPrefix, initialPolicy, i] = userData{:};
tag = [guidPrefix 'slider_var' num2str(i)];
value = initialPolicy(i);
hui = findobj('Tag', tag);
set(hui, 'Value', value);
guiSliderVarChange(hui);



function guiSave(h, ~)
%% save button pressed

% display save dialog
[filename, directory] = uiputfile({ ...
    '*.fig', 'MATLAB Figure (*.fig)'; ...
    '*.png', 'Portable Network Graphics file (*.png)'});

if filename == 0
    return;
end

path = [directory filename];
userData = get(h, 'UserData');
[guidPrefix, self] = userData{:};
hfs = cell(1, getNumberOfFigures(guidPrefix));

% get handle of figures to be saved
for j = 1:numel(hfs)
    tag = [guidPrefix 'fig_fcn' num2str(j)];
    hfs{j} = findobj('Tag', tag);
end

format = filename(end-2:end);

switch format
    case 'fig'
        % save as *.fig in one file
        hfs = horzcat(hfs{:});
        savefig(hfs, path);
    case 'png'
        % save as *.png in separate files
        for j = 1:numel(hfs)
            if isempty(hfs{j}); continue; end
            current_path = sprintf([...
                '%s_entry%0' num2str(floor(log10(self.numberOfPolicies+2)) + 1) 'd%s'], ...
                path(1:end-4), j, path(end-3:end));
            print(hfs{j}, current_path, ['-d' format]);
        end
    otherwise
        error('Unknown format.');
end



function guiRealign(h, ~)
%% realign button pressed

userData = get(h, 'UserData');
guidPrefix = userData{:};

hf = findobj('Tag', [guidPrefix 'fig_gui']);
alignFigure(hf, 1);
pos = hf.Position;
pos(4) = 200;
hf.Position = pos;
hf_gui = hf;

for j = 1:getNumberOfFigures(guidPrefix)
    tag = [guidPrefix 'fig_fcn' num2str(j)];
    hf = findobj('Tag', tag);
    alignFigure(hf, j+1, hf_gui);
end



function guiListVarChange(h, ~)
%% popup menu selection changed

userData = get(h, 'UserData');
[guidPrefix, self, oldVar] = userData{:};

% remove newly selected variable in other popup menu,
% add previously selected variable to other popup menu
if strcmp(get(h, 'Tag'), [guidPrefix 'list_var1'])
    otherH = findobj('Tag', [guidPrefix 'list_var2']);
else
    otherH = findobj('Tag', [guidPrefix 'list_var1']);
end

oldOtherValue = get(otherH, 'Value');

newVar = getSelectedVariable(self, h);
otherVar = getSelectedVariable(self, otherH);

otherVarStr = cell(1, self.numberOfPolicies);
for i = 1:self.numberOfPolicies
    otherVarStr{i} = convertPolicyVar(self, i);
end
otherVarStr(newVar) = [];
set(otherH, 'String', otherVarStr);

newOtherValue = oldOtherValue;
if oldVar < otherVar; newOtherValue = newOtherValue + 1; end
if newVar < otherVar; newOtherValue = newOtherValue - 1; end
set(otherH, 'Value', newOtherValue);

% enable/disable labels and sliders
set(findobj('Tag', [guidPrefix 'label_slider_var' num2str(oldVar)]), 'Enable', 'on');
set(findobj('Tag', [guidPrefix 'label_slider_var' num2str(newVar)]), 'Enable', 'off');
set(findobj('Tag', [guidPrefix 'slider_var' num2str(oldVar)]), 'Enable', 'on');
set(findobj('Tag', [guidPrefix 'slider_var' num2str(newVar)]), 'Enable', 'off');
set(findobj('Tag', [guidPrefix 'reset_var' num2str(oldVar)]), 'Enable', 'on');
set(findobj('Tag', [guidPrefix 'reset_var' num2str(newVar)]), 'Enable', 'off');

% save new variable so that next time, the previously selected variable
% can be obtained
set(h, 'UserData', {guidPrefix, self, newVar});



function j = getNumberOfFigures(guidPrefix)
%% get number of open figures

j = 0;

while true
    tag = [guidPrefix 'fig_fcn' num2str(j+1)];
    hf = findobj('Tag', tag);
    if isempty(hf); break; end
    j = j + 1;
end



function [J, noOfExtrap, gradJ] = calculateJ( ...
    self, previousSolution, state, discreteState, t, XXYY)
%% calculate J for policy points, taking constraints into account

NN = size(XXYY, 1);
J          = nan(NN, 1);
noOfExtrap = nan(NN, 1);
gradJ      = nan(NN, self.numberOfPolicies);

[A, b, ~, ~, lb, ub, ~] = self.getConstraints(state, discreteState, t);
K = all(bsxfun(@le, A*XXYY', b(:))', 2) & ...
    all(bsxfun(@le, lb(:)', XXYY), 2) & ...
    all(bsxfun(@le, XXYY, ub(:)'), 2);
NNmissing = sum(K);
missingXXYY       = XXYY(K,:);
missingJ          = nan(NNmissing, 1);
missingNoOfExtrap = nan(NNmissing, 1);
missingGradJ      = nan(NNmissing, self.numberOfPolicies);

shocks = self.computeShockDistribution(state, discreteState, t);
if nargout > 2
    parfor k = 1:NNmissing
        [Info, missingJ(k), missingGradJ(k,:)] = self.getJ(previousSolution, missingXXYY(k,:), ...
                                                           state, discreteState, t); %#ok<PFBNS>
        missingNoOfExtrap(k) = Info.numberOfExtrapolations / size(shocks, 1);
    end
else
    parfor k = 1:NNmissing
        [Info, missingJ(k)] = self.getJ(previousSolution, missingXXYY(k,:), ...
                                        state, discreteState, t); %#ok<PFBNS>
        missingNoOfExtrap(k) = Info.numberOfExtrapolations / size(shocks, 1);
    end
end

J(K)          = missingJ;
noOfExtrap(K) = missingNoOfExtrap;
gradJ(K,:)    = missingGradJ;

K = K & (imag(J) == 0);
J(~K)          = nan;
noOfExtrap(~K) = nan;
gradJ(~K,:)    = nan;



function [xOpt, JOpt, noOfExtrapOpt, gradJOpt] = fullGridOptimizer( ...
    self, previousSolution, state, discreteState, t, x0, dx, i1, i2)
%% optimization on a full grid in [x0 - dx, x0 + dx]

n1 = 10; n2 = 10;
xx = linspace(x0(i1) - dx(i1), x0(i1) + dx(i1), n1);
if self.numberOfPolicies == 1
    XX = xx;
    XXYY = XX(:);
else
    yy = linspace(x0(i2) - dx(i2), x0(i2) + dx(i2), n2);
    [XX, YY] = meshgrid(xx, yy);
    NN = numel(XX);

    XXYY = repmat(x0, NN, 1);
    XXYY(:,i1) = XX(:);
    XXYY(:,i2) = YY(:);
end

if nargout > 3
    [J, noOfExtrap, gradJ] = calculateJ(self, previousSolution, state, discreteState, t, XXYY);
else
    [J, noOfExtrap] = calculateJ(self, previousSolution, state, discreteState, t, XXYY);
end

[JOpt, k] = max(J(:));
xOpt = XXYY(k,:);
noOfExtrapOpt = noOfExtrap(k);
if nargout > 3; gradJOpt = gradJ(k,:); end


function finiteDiffJ = calculateFiniteDifference( ...
    self, previousSolution, state, discreteState, t, XXYY, J, i)
%% calculate i-th partial derivative of J with finite differences

h = 1e-8;
e = zeros(1, self.numberOfPolicies); e(i) = 1;
NN = size(XXYY, 1);

XXYYl = bsxfun(@minus, XXYY, h * e);
XXYYr = bsxfun(@plus, XXYY, h * e);
tmp = calculateJ(self, previousSolution, state, discreteState, t, [XXYYl; XXYYr]);
Jl = tmp(1:NN);
Jr = tmp(NN+1:end);

finiteDiffJ = nan(NN, 1);
isValid = @(y) ~isnan(y) & (imag(y) == 0);
isValidJl = isValid(Jl);
isValidJ  = isValid(J);
isValidJr = isValid(Jr);

Kl =  isValidJl & isValidJ & ~isValidJr;
K  =  isValidJl & isValidJ &  isValidJr;
Kr = ~isValidJl & isValidJ &  isValidJr;

finiteDiffJ(Kl) = (J(Kl) - Jl(Kl)) / h;
finiteDiffJ(K)  = (Jr(K) - Jl(K)) / (2 * h);
finiteDiffJ(Kr) = (Jr(Kr) - J(Kr)) / h;



function printOptimum(self, state, discreteState, t, name, policy, J)
%% helper function for printing

s = sprintf('%s:\n', name);

for i = 1:self.numberOfPolicies
    s = sprintf('%s  %17s = %.10f\n', s, convertPolicyVar(self, i), policy(i));
end

[A, b, ~, ~, lb, ub, ~] = self.getConstraints(state, discreteState, t);
x = policy';
numberOfBindingConstraints = sum(abs([b - A * x; ub' - x; x - lb']) < ...
                                     1e1 * self.Optimizer.tolCon);

s = sprintf('%s  %17s = %u\n', s, '#Binding constr.', numberOfBindingConstraints);
s = sprintf('%s  %17s = %.12f\n', s, 'J', J);
fprintf(s);



function var = getSelectedVariable(self, h)
%% index of the selected policy variable in the popup menu h

vars = get(h, 'String');
var = convertPolicyVar(self, vars{get(h, 'Value')});



function s = convertPolicyVar(self, i)
%% convert policy variable index to string and vice-versa

S = self.policyNames;
if isnumeric(i); s = S{i}; else; s = find(strcmp(S, i)); end



function policyBounds = getPolicyBoundingBox(self, state, discreteState, t, policy)
%% get bounding box of feasible policy region

if ~exist('policy', 'var') || isempty(policy)
    policy = nan(1, self.numberOfPolicies);
end

% dimensions in which policy bounds are to be determined
PTBD = isnan(policy);

% only takes into account A*x <= b, lb <= x <= ub,
% does not incorporate equality constraints,
% does not incorporate non-linear constraints
[A, b, ~, ~, lb, ub, ~] = self.getConstraints(state, discreteState, t);

% if some values of the policies are already given, then substitute them into
% the constraints, eliminating the variables in the process
if ~all(PTBD)
    b  = b - sum(bsxfun(@times, A(:,~PTBD), policy(~PTBD)), 2);
    A  = A(:,PTBD);
    lb = lb(:,PTBD);
    ub = ub(:,PTBD);
end

% policyBounds will be contained in the box constraints
policyBounds = [lb; ub];

% precalculate values for policies which "give the most slack" in the constraints
% (depends on the sign of the matrix entries)
Min = A;
Lb = repmat(lb, size(A, 1), 1);
Ub = repmat(ub, size(A, 1), 1);
Min(A > 0) = Min(A > 0) .* Lb(A > 0);
Min(A < 0) = Min(A < 0) .* Ub(A < 0);

for p = 1:size(A, 2)
    % all policies but the p-th
    NoP = 1:size(A, 2);
    NoP(p) = [];
    
    for i = 1:size(A, 1)
        if A(i,p) > 0
            % contraints/policies for which A(i,p) is positive bound the feasible
            % values for the policy from above
            policyBounds(2,p) = min((b - sum(Min(i,NoP))) / A(i,p), policyBounds(2,p));
        elseif A(i,p) < 0
            % contraints/policies for which A(i,p) is negative bound the feasible
            % values for the policy from below
            policyBounds(1,p) = max((b - sum(Min(i,NoP))) / A(i,p), policyBounds(1,p));
        end
    end
end
