function latex = createEZTable(data, key)

if ~iscell(key); key = num2cell(key); end

noOfPanels = numel(key);

if strcmpi(inputname(2), 'eis'); keyStr = 'eis'; keyName = 'EIS'; end
if strcmpi(inputname(2), 'rra'); keyStr = 'riskaversion'; keyName = 'RRA'; end

%% construct header
% construct rows
rows = repeatString('rrrrc', noOfPanels - 1);
rows = sprintf('%srrrr', rows);

% construct panels
keyToFloat = @(numbers, digits) cellfun(@(x) Formatter.formatFloat(1 - x, digits), numbers, ...
                                        'UniformOutput', false);
keyValueStr = keyToFloat(key, 2);
panels = '';
divider = '\cmidrule{3-6} ';
for i = 1:noOfPanels - 1
    panels = sprintf('%s \\multicolumn{4}{c}{$\\%s = %s$}& \\phantom{abc}&', panels, keyStr, ...
                     keyValueStr{i});
    divider = sprintf('%s\\cmidrule{%d-%d} ', divider, 3 + i * 5, 6 + i * 5);
end
panels = sprintf('%s \\multicolumn{4}{c}{$\\%s = %s$} ', panels, keyStr, keyValueStr{end});
columns = repeatString(['$\certaintyequivalent_{20}$& Avg. $\optimal{\claims}_{65}$& Med. ' ...
                        '$\optimal{\claims}_{65}$& Std. $\optimal{\claims}_{65}$& &'], ...
                        noOfPanels - 1);
columns = sprintf(['%s $\\certaintyequivalent_{20}$& Avg. $\\optimal{\\claims}_{65}$& Med. ' ...
                   '$\\optimal{\\claims}_{65}$& Std. $\\optimal{\\claims}_{65}$'], columns);
% print panels etc. to header
header = sprintf(['\\begin{table}[t]\n' ...
   '  \\newcommand*{\\mrvar}[1]{\\multirow{-4}{*}{#1}}%%\n' ...
   '  \\resizebox{\\textwidth}{!}{%%\n' ...
   '  \\begin{tabular}{@{}rr%s@{}}\n' ...
   '    \\toprule\n' ...
   '     & &%s\\\\\n' ...
   '    %s\n' ...
   '    $\\interestvola$& & %s\\\\\n' ...
   '    \\midrule\n'], rows, panels, divider, columns);

%% construct tabular data
% construct format strings
placeholders = repeatString('%5s& %5s& %5s& %5s& &', noOfPanels - 1);
formatStringAges = sprintf('                    & %%5s& %s %%5s& %%5s& %%5s& %%5s\\\\\\\\\\n', ...
                           placeholders);
formatStringAbsDiff = sprintf(['                    & $\\\\Delta_{\\\\mathrm{abs}}$& %s ' ...
                               '%%5s& %%5s& %%5s& %%5s\\\\\\\\\\n'], placeholders);
formatStringRelDiff = sprintf(['    \\\\mrvar{%%8s}& $\\\\Delta_{\\\\mathrm{rel}}$& %s ' ...
                               '%%5s& %%5s& %%5s& %%5s\\\\\\\\\\n' ...
                               '    \\\\midrule\\n'], placeholders);

% choose data set for each key and flatten table
primaryKey = {'Sigma_r', 'PurchaseAges'};
columns = {'CE', 'L_avg', 'L_med', 'L_std'};
flattenedData = data(data.(keyName) == key{1}, [primaryKey, columns]);
flattenedData.Properties.VariableNames = [primaryKey strcat(columns, '_1')];
for i = 2:noOfPanels
    tmpTbl = data(data.(keyName) == key{i}, [primaryKey, columns]);
    tmpTbl.Properties.VariableNames = [primaryKey strcat(columns, ['_' num2str(i)])];
    flattenedData = innerjoin(flattenedData, tmpTbl, 'Keys', primaryKey);
end
flattenedData = sortrows(flattenedData, {'Sigma_r', 'PurchaseAges'}, {'descend', 'descend'});
% compute row-wise differences
absDeltas = flattenedData{1:2:end, 3:end} - flattenedData{2:2:end, 3:end};
relDeltas = 100 * (flattenedData{1:2:end, 3:end} - flattenedData{2:2:end, 3:end}) ./ ...
            flattenedData{2:2:end, 3:end};


% print tabular
tabular = '';
flattenedColumns = flattenedData.Properties.VariableNames(3:end);
% counter for deltas
j = 1;
for i = 1:2:height(flattenedData)
    % since the flattened data is sorted, we know that it is 64 first
    cellStrData = formatUnitData(flattenedData{i, flattenedColumns}, 0, '');
    tabular = sprintf('%s%s', tabular, sprintf(formatStringAges, '$\ageset[64]$', cellStrData{:}));
    cellStrData = formatUnitData(flattenedData{i + 1, flattenedColumns}, 0, '');
    tabular = sprintf('%s%s', tabular, sprintf(formatStringAges, '$\ageset[20-64]$', ...
                      cellStrData{:}));
    cellStrData = formatUnitData(absDeltas(j, :), 0, '');
    tabular = sprintf('%s%s', tabular, sprintf(formatStringAbsDiff, cellStrData{:}));
    cellStrData = [formatUnitData(flattenedData.Sigma_r(i), 4, '%') ...
                   formatUnitData(relDeltas(j, :), 2, '%')];
    tabular = sprintf('%s%s', tabular, sprintf(formatStringRelDiff, cellStrData{:}));
    j = j + 1;
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
% 1:end-13 to remove last \midrule before setting bottom rule
latex = sprintf('%s%s', latex(1:end-13), footer);

end

function outStr = repeatString(inStr, times)
    outStr = cell(times, 1);
    [outStr{:}] = deal(inStr);
    outStr = sprintf('%s', outStr{:});
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
