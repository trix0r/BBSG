function latex = createAssetAllocationTable()

%% construct header

% construct rows
rows = 'rrrcrrr';

% construct panels
panels = ['\multicolumn{3}{c}{Pre-retirement}& \phantom{abc}& ' ...
          '\multicolumn{3}{c}{Post-retirement}'];
columns = ['Stocks& \thead{Money \\ market}& \thead{Annuities \\ (PV)}& & ' ...
           'Stocks& \thead{Money \\ market}& \thead{Annuities \\ (PV)}'];
divider = '\cmidrule{3-5} \cmidrule{7-9}';
% print panels etc. to header
header = sprintf(['\\begin{table}[t]\n' ...
   '  \\newcommand*{\\mrvar}[1]{\\multirow{-3}{*}{#1}}%%\n' ...
   '  \\resizebox{\\textwidth}{!}{%%\n' ...
   '  \\begin{tabular}{@{}rr%s@{}}\n' ...
   '    \\toprule\n' ...
   '     & &%s\\\\\n' ...
   '    %s\n' ...
   '    $\\interestvola$& $\\permanentshockvola$& %s\\\\\n' ...
   '    \\midrule\n' ...
   '    \\multicolumn{9}{c}{Gradual annuitization from ages 20 to 64}\\\\[2mm]\n'], ...
   rows, panels, divider, columns);

%% construct tabular data
% construct format strings
formatStringRow = '                    & %8s& %5s& %5s& %5s& & %5s& %5s& %5s\\\\\n';
formatStringEndRow = ['    \\mrvar{%8s}& %8s& %5s& %5s& %5s& & %5s& %5s& %5s\\\\\n' ...
                      '    \\midrule\n'];
tabular = '';
ids = [3231,3230,3232,3234,3233,3235,3237,3236,3238,3240,3239,3241,3243,3242,3244,3246,3245,3247];
startIdx = [1, 4, 7, 10, 13, 16];
for i = 1:numel(startIdx)
    for j = 0:2
        % compute asset allocations
        [assetAlloc, permShockVola, interestVola] = getAllocationForResultId(ids(startIdx(i) + j));
        dataBefore = formatUnitData(assetAlloc.before, 1, '');
        dataAfter = formatUnitData(assetAlloc.after, 1, '');
        if j < 2
            data = sprintf(formatStringRow, ...
                           Formatter.formatUnitNum(permShockVola, 4, '%'), ...
                           dataBefore{:}, ...
                           dataAfter{:});
        else
            data = sprintf(formatStringEndRow, ...
                           Formatter.formatUnitNum(interestVola, 4, '%'), ...
                           Formatter.formatUnitNum(permShockVola, 4, '%'), ...
                           dataBefore{:}, ...
                           dataAfter{:});
        end
        % print tabular
        tabular = sprintf('%s%s', tabular, data);
    end
    % divider for one time vs. gradual annuitization
    if i == 3
        div = '    \multicolumn{9}{c}{One-time annuitization at age 64}\\[2mm]';
        tabular = sprintf('%s%s\n', tabular, div);
    end
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

function [assetAlloc, permShockVola, interestVola] = getAllocationForResultId(id)
    [~, problem, ~, ~, ~, ~, simulation] = loadResult(id, {'problem', 'simulation'});
    [~, fractions] = problem.computeAssetAllocation(simulation.state, simulation.policy);
    tRet = problem.Time.copy;
    tRet.age = problem.Income.retirementAge;

    assetAlloc.before = squeeze(nanmean(nanmean(fractions(:, 1:tRet.index - 1, :), 2), 1)) * 100;
    assetAlloc.after = squeeze(nanmean(nanmean(fractions(:, tRet.index:end, :), 2), 1)) * 100;
        permShockVola = problem.Income.Permanent.v * 100;
    interestVola = problem.Interest.sigma * 100;
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
