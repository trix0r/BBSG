function latex = createErrorTable(data)

%% construct header
header = sprintf(['\\begin{table}[t]\n' ...
   '  \\resizebox{\\textwidth}{!}{%%\n' ...
   '  \\begin{tabular}{@{}rrrrrrrr@{}}\n' ...
   '    \\toprule\n' ...
   '    $\\interestvola$& $\\permanentshockvola$& $\\riskaversion$& $\\eis$& & ' ...
   '$\\lone$& $\\ltwo$& $\\linf$\\\\\n' ...
   '    \\midrule\n']);

%% construct tabular data
myParamToStr = @(numbers, digits) arrayfun(@(x) Formatter.formatFloat(1 - x, digits), numbers, ...
                                        'UniformOutput', false);
% construct format strings
formatStringRow = '    %8s& %8s& %5s& %5s& %16s& %5s& %5s& %5s\\\\\n';

% sort data set
primaryKey = {'Sigma_r', 'Sigma_p', 'RRA', 'EIS', 'PurchaseAges'};
columns = {'L1', 'L2', 'LInf'};
% remove potential duplicates
[~, idx] = unique(data(:, primaryKey), 'rows', 'first');
sortedData = sortrows(data(idx, :), primaryKey, repeatString('descend', 5));

% print tabular
tabular = '';
% counter for deltas
for i = 1:height(sortedData)
    if strcmp(sortedData.PurchaseAges{i}, '64-64')
        cellStrData = [formatUnitData(sortedData.Sigma_r(i), 4, '%'), ...
                       formatUnitData(sortedData.Sigma_p(i), 4, '%'), ...
                       myParamToStr(sortedData.RRA(i), 2), ...
                       myParamToStr(sortedData.EIS(i), 2), ...
                       '$\ageset[64]$', ...
                       formatScientificData(sortedData{i, columns}, 1)];
    else
        cellStrData = [formatUnitData(sortedData.Sigma_r(i), 4, '%'), ...
                       formatUnitData(sortedData.Sigma_p(i), 4, '%'), ...
                       myParamToStr(sortedData.RRA(i), 2), ...
                       myParamToStr(sortedData.EIS(i), 2), ...
                       '$\ageset[20-64]$', ...
                       formatScientificData(sortedData{i, columns}, 1)];
    end
        tabular = sprintf('%s%s', tabular, sprintf(formatStringRow, cellStrData{:}));
end


%% construct footer
footer = sprintf(['    \\bottomrule\n' ...
                       '  \\end{tabular}}\n' ...
                       '  \\caption[TODO]{%%\n' ...
                       '    TODO%%\n' ...
                       '  }%%\n' ...
                       '  \\label{tbl:TODO}%%\n'...
                       '\\end{table}']);

%% put it all together
latex = sprintf('%s%s%s', header, tabular);
latex = sprintf('%s%s', latex, footer);

end

function outStr = repeatString(inStr, times)
    outStr = cell(times, 1);
    [outStr{:}] = deal(inStr);
%     outStr = sprintf('%s', outStr{:});
end

function cellstr = formatScientificData(celldata, digits)
    if ~iscell(celldata); celldata = num2cell(celldata); end
    cellstr = cell(1, numel(celldata));
    for i = 1:numel(celldata); cellstr{i} = Formatter.formatScientificNum(celldata{i}, digits); end
end

function cellstr = formatUnitData(celldata, digits, unit)
    if ~iscell(celldata); celldata = num2cell(celldata); end
    cellstr = cell(1, numel(celldata));
    if ~isempty(unit)
        for i = 1:numel(celldata)
            cellstr{i} = Formatter.formatUnitNum(celldata{i}, digits, unit);
        end
    else
        for i = 1:numel(celldata); cellstr{i} = Formatter.formatUnitNum(celldata{i}, digits); end
    end
end
