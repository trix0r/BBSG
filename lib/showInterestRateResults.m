function [data, latex] = showInterestRateResults(ids, mode, suppressOutput, tableChoice)

if ~exist('ids', 'var'); ids = []; end
if ischar(ids); ids = eval(ids); end
if ~exist('mode', 'var'); mode = 'default'; end
if ~exist('suppressOutput', 'var'); printFlag = true; else; printFlag = ~suppressOutput; end
if ~exist('tableChoice', 'var'); tableChoice = ''; end

% set paths
rootPath = pwd;
resultsParentPath = [rootPath filesep 'results'];

% sort sub-directories corresponding to results by ascending ID
resultsDirs = dir(resultsParentPath);
resultsNames = {resultsDirs.name};
[~, I] = sort(resultsNames);
resultsDirs = resultsDirs(I);

switch mode
    case 'default'
        header = {'ID', 'd', 'Type', ...
                'VL', 'VTol', '#VPts', '#VIns', 'VTime', ...
                'PL', 'PTol', '#PPts', '#PIns', 'PTime', ...
                'L2', 'LInf'};
        formatString = ['%4s %1s %4s | %2s %4s %5s %5s %6s |' ...
                        ' %2s %4s %5s %5s %6s | %6s %6s\n';];
        strLine = sprintf(['------------+----------------------------+' ...
                           '----------------------------+--------------\n']);
        latexHeader = sprintf(['\\begin{table}[t]\n' ...
                              '  \\sisetup{retain-zero-exponent=true}%%\n' ...
                              '  \\newcommand*{\\mrvar}[1]{\\multirow{-2}{*}{#1}}%%\n' ...
                              '  \\begin{tabular}{@{}rrrrrrrrcc@{}}\n' ...
                              '    \\toprule\n' ...
                              '    $d$& Interp.& $n$& $\\varepsilon_t$& $|\\gridset[n,d]|$& '...
                              '$N_t$& $\\Delta_{N_t}$& Time& '...
                              '$\\eulererr_t^{\\Ltwo}$& $\\eulererr_t^{\\Linfty}$ \\\\\n' ...
                              '    \\midrule\n']);
        latexFormatStringValue  = ['    & $\\valueintp_t$& %2s& %s& %5s& %5s& %5s& \\hms{%s}& '...
                                   '& \\\\\n'];
        latexFormatStringPolicy = ['    \\mrvar{%1s}& $\\optpolicyintp_t$& %2s& %s& %5s& %5s& '...
                                   ' %5s& \\hms{%s}& \\mrvar{%s}& \\mrvar{%s}\\\\\n' ...
                                   '    \\midrule\n'];

    case 'complexity'
        header = {'ID', 'd', 'Type', 'p', ...
                'VL', 'VTol', '#VPts', 'secSer', 'L2', ...
                '#Opt', 'sec/Op', ...
                '#J', '#grJ', 'It/O', 'sec/It', ...
                '#Ev', '#grEv', 'Ev/It', 'sec/Ev'};
        formatString = ['%4s %1s %4s %1s | %2s %4s %5s %6s %6s | %5s %6s |' ...
                        ' %5s %5s %5s %6s | %5s %5s %5s %6s\n';];
        strLine = sprintf(['--------------+-----------------------------+' ...
                           '--------------+--------------------------+' ...
                           '-------------------------\n']);
       latexHeader = '';
    case 'economic'
        header = {'ID', 'd', 'Grid', 'Model', 'Sigma_r', 'Sigma_p', 'RRA', 'EIS', ...
                'PurchaseAges', 'CE', 'L_avg', 'L_med', 'L_std', 'L1', 'L2', 'LInf'};
        formatString = ['%4s %1s %4s | %17s | %8s | %8s | %5s | %5s | %12s | %8s | ' ...
                        '%8s %8s %8s | %6s %6s %6s\n'];
        strLine = sprintf(['------------+-------------------+----------+----------+' ...
                           '-------+-------+--------------+----------+' ...
                           '----------------------------+---------------------\n']);
       if strcmpi(tableChoice, 'annuitypurchase')
           latexHeader = sprintf(['\\begin{table}[t]\n' ...
               '  \\newcommand*{\\mrvar}[1]{\\multirow{-3}{*}{#1}}%%\n' ...
               '  \\begin{tabular}{@{}rrrrrr@{}}\n' ...
               '    \\toprule\n' ...
               '    $\\interestvola$& Purchase ages& $\\certaintyequivalent$& Avg. $\\claims$& ' ...
               'Med. $\\claims$& Std. $\\claims$\\\\\n' ...
               '    \\midrule\n']);
           latexFormatStringAges  = '                    & %5s& %5s& %5s& %5s& %5s\\\\\n';
           latexFormatStringDiff  = ['    \\mrvar{%8s}& $\\Delta$& %5s& %5s& %5s& %5s\\\\\n' ...
               '    \\midrule\n'];
       elseif strcmpi(tableChoice, 'eis')
            latexHeader = sprintf(['\\begin{table}\n' ...
               '  \\newcommand*{\\mrvar}[1]{\\multirow{-3}{*}{#1}}%%\n' ...
               '  \\begin{tabular}{@{}rrrrrr@{}}\n' ...
               '    \\toprule\n' ...
               '    $\\interestvola$& $\\eis$& $\\certaintyequivalent$& Avg. $\\claims$& ' ...
               'Med. $\\claims$& Std. $\\claims$\\\\\n' ...
               '    \\midrule\n']);
           latexFormatStringLowAndEqualEis  = '                    & %5s& %5s& %5s& %5s& %5s\\\\\n';
           latexFormatStringHighEis  = ['    \\mrvar{%8s}& %5s& %5s& %5s& %5s& %5s\\\\\n' ...
               '    \\midrule\n'];
       else
           latexHeader = '';
       end
    otherwise
        error('Unknown mode.');
end
strHeader = sprintf(formatString, header{:});
tblHeader = strrep(strrep(header, '#', 'n'), '/', 'b');

% initialize latex string
latex = sprintf('%s', latexHeader);

% initialize data table
data = cell2table(cell(0, numel(tblHeader)));
data.Properties.VariableNames = tblHeader;

parsePolicyPoints = @(y) cell2mat(cellfun(@(x) str2double(strsplit(strtrim(x{1}))), ...
                                          y, 'UniformOutput', false)');

if printFlag
  fprintf(strHeader);
  fprintf(strLine);
end
previousID = [];

for i = 1:numel(resultsDirs)
    % parse directory name
    if ~resultsDirs(i).isdir; continue; end
    matches = regexp(resultsDirs(i).name, '^([0-9]{4})($|_)(.*)', 'tokens');
    if isempty(matches); continue; end
    idStr = matches{1}{1};
    id = str2double(idStr);
    if ~isempty(ids)
        if isscalar(ids)
            if id < ids; continue; end
        else
            if isempty(find(ids == id, 1)); continue; end
        end
    end

    % print line if there is a gap of at least two missing IDs
    if ~isempty(previousID) && (id > previousID + 2) && printFlag
        fprintf(strLine);
    end

    resultsPath   = [resultsParentPath filesep resultsDirs(i).name];
    valueLogPath  = [resultsPath filesep 'optimization_log.txt'];
    policyLogPath = [resultsPath filesep 'policy_log.txt'];

    % print comment if available
    commentPath = [resultsPath filesep 'comment.txt'];
    if exist(commentPath, 'file') && printFlag
        comment = fileread(commentPath);
        fprintf(2, '%s\n', strip(comment));
    end

    try
        if strcmp(mode, 'complexity')
            [properties, problem, ~, Info, ~, errors, ~] = loadResult(id, ...
                    {'properties', 'problem', 'Info', 'errors'});
        elseif strcmp(mode, 'economic')
            [properties, problem, ~, Info, ~, errors, simulation] = loadResult(id, ...
                    {'properties', 'problem', 'Info', 'errors', 'simulation'});
        else
            [properties, problem, ~, ~, ~, errors, ~] = loadResult(id, ...
                    {'properties', 'problem', 'errors'});
        end
    catch
        continue;
    end

    parameters = properties.parameters;
    gridType = getField(parameters, 'gridType', 'regular');
    if strcmp(gridType, 'regular'); gridType = 'reg'; end
    p = getField(parameters, 'BsplineDegree', 3);
    refineTolerance = getField(parameters, 'refineTolerance', Inf);
    policyRefineTolerance = getField(parameters, 'policyRefineTolerance', Inf);

    if exist(valueLogPath, 'file')
        timeValue = ...
                searchFile(valueLogPath, 'Calculation time was (.*) seconds.');
        %% quick hack as there are no refinements for the first time step
        numbersOfBasePointsValue = ...
                searchFile(valueLogPath, '#Start pts. *([0-9]+)');
        numbersOfBasePointsValue = numbersOfBasePointsValue(1);
        numbersOfPointsValue = ...
                searchFile(valueLogPath, '#End pts. *([0-9]+)');
        numbersOfInsertedPointsValue = ...
                searchFile(valueLogPath, '#Inserted pts. *([0-9]+)');
        numberOfPointsValue = numbersOfPointsValue(end);
        numberOfInsertedPointsValue = max(numbersOfInsertedPointsValue);

        numberOfOptForInitialTimeStep = ...
                searchFile(valueLogPath, '#End pts. *[0-9]+ +([0-9]+)');
        numberOfOptForInitialTimeStep = numberOfOptForInitialTimeStep(end);
        % 2:end to exclude terminal time step
        % (no optimization runs are performed for terminal grid points)
        numberOfOpt = sum(numbersOfPointsValue(2:end)) + numberOfOptForInitialTimeStep;
    else
        timeValue = NaN;
        numberOfPointsValue = NaN;
        numberOfInsertedPointsValue = NaN;
    end

    if exist(policyLogPath, 'file')
        timesPolicy = ...
                searchFile(policyLogPath, '[0-9]+ + ([0-9]+.[0-9]+)s');
        numbersOfBasePointsPolicy = parsePolicyPoints( ...
                searchFile(policyLogPath, '#Start pts.( +[0-9]+)+', false));
        numbersOfPointsPolicy = parsePolicyPoints( ...
                searchFile(policyLogPath, '#End pts.( +[0-9]+)+', false));
        numbersOfInsertedPointsPolicy = parsePolicyPoints( ...
                searchFile(policyLogPath, '#Inserted pts.( +[0-9]+)+', false));
        timePolicy = sum(timesPolicy);
        numbersOfBasePointsPolicy = mean(max(numbersOfBasePointsPolicy, [], 1));
        numberOfPointsPolicy = mean(max(numbersOfPointsPolicy, [], 1));
        numberOfInsertedPointsPolicy = mean(max(numbersOfInsertedPointsPolicy, [], 1));
    else
        timePolicy = NaN;
        numberOfPointsPolicy = NaN;
        numberOfInsertedPointsPolicy = NaN;
    end

    if ~isempty(errors)
        err = struct2struct(errors);
        errorsL1   = nanmean(err.L1(:,3));
        errorsL2   = nanmean(err.L2(:,3));
        errorsLInf = nanmean(err.Max(:,3));
    else
        errorsL1 = NaN;
        errorsL2 = NaN;
        errorsLInf = NaN;
    end

    if strcmp(mode, 'complexity')
        if isfield(Info, 'Calls')
            if Info.Calls.gradJ > 0
                numberOfIterations = Info.Calls.gradJ;
                numberOfEvaluations = Info.Calls.Evaluate.gradJ;
            else
                numberOfIterations = Info.Calls.J;
                numberOfEvaluations = Info.Calls.Evaluate.J;
            end
            numberOfJCalls        = Info.Calls.J;
            numberOfGradJCalls    = Info.Calls.gradJ;
            numberOfEvalCalls     = Info.Calls.Evaluate.J;
            numberOfGradEvalCalls = Info.Calls.Evaluate.gradJ;
            numberOfItPerOpt  = numberOfIterations / numberOfOpt;
            numberOfEvalPerIt = numberOfEvaluations / numberOfIterations;
            timePerIt   = Info.Time.optimizer / numberOfIterations;
            timePerEval = Info.Time.optimizer / numberOfEvaluations;
        else
            numberOfJCalls        = NaN;
            numberOfGradJCalls    = NaN;
            numberOfEvalCalls     = NaN;
            numberOfGradEvalCalls = NaN;
            numberOfItPerOpt  = NaN;
            numberOfEvalPerIt = NaN;
            timePerIt   = NaN;
            timePerEval = NaN;
        end
    end
    if strcmp(mode, 'economic')
        annuityPurchaseAges = getField(parameters, 'annuityPurchaseAges', 20:64);
        if isempty(annuityPurchaseAges); annuityPurchaseAges = 20:64; end
        annuityPurchaseAges = sprintf('%s-%s', num2str(annuityPurchaseAges(1)), ...
                                              num2str(annuityPurchaseAges(end)));
        interestVola = getField(parameters, 'interestVola', 0.010506) * 100;
        permanentShockVola = problem.Income.Permanent.v * 100;
        if isempty(simulation)
            CE = NaN;
            meanL = NaN;
            stdL = NaN;
            medL = NaN;
        else
            CE = problem.computeCertaintyEquivalent(simulation.state, simulation.policy);
            CE = CE * 10000; % total $values
            t = problem.Time;
            t.age = 65;
            meanL = mean(simulation.state.L(:, t))  * 10000;
            stdL = std(simulation.state.L(:, t))  * 10000;
            medL = median(simulation.state.L(:, t)) * 10000;
        end
    end

    switch mode
        case 'default'
            if printFlag
                fprintf(formatString, ...
                        sprintf('%04u', id), ...
                        Formatter.formatFloat(problem.numberOfStates, 0), ...
                        gridType, ...
                        Formatter.formatFloat(parameters.baseLevel, 0), ...
                        Formatter.formatScientific(refineTolerance, 0), ...
                        Formatter.formatFloat(numberOfPointsValue, 0), ...
                        Formatter.formatFloat(numberOfInsertedPointsValue, 0), ...
                        Formatter.formatTime(timeValue), ...
                        Formatter.formatFloat(parameters.policyBaseLevel, 0), ...
                        Formatter.formatScientific(policyRefineTolerance, 0), ...
                        Formatter.formatFloat(numberOfPointsPolicy, 0), ...
                        Formatter.formatFloat(numberOfInsertedPointsPolicy, 0), ...
                        Formatter.formatTime(timePolicy), ...
                        Formatter.formatScientific(errorsL2, 1), ...
                        Formatter.formatScientific(errorsLInf, 1));
            end
            tblData = {id, problem.numberOfStates, gridType, parameters.baseLevel, ...
                       refineTolerance, numberOfPointsValue, numberOfInsertedPointsValue, ...
                       timeValue, parameters.policyBaseLevel, policyRefineTolerance, ...
                       numberOfPointsPolicy, numberOfInsertedPointsPolicy, timePolicy, ...
                       errorsL2, errorsLInf};
            latex = sprintf('%s%s', latex, ...
                            sprintf(latexFormatStringValue, ...
                                    Formatter.formatFloat(parameters.baseLevel, 0), ...
                                    Formatter.formatScientificNum(refineTolerance, 0), ...
                                    Formatter.formatFloat(numbersOfBasePointsValue, 0), ...
                                    Formatter.formatFloat(numberOfPointsValue, 0), ...
                                    Formatter.formatFloat(numberOfInsertedPointsValue, 0), ...
                                    Formatter.formatTimeHms(timeValue)));
           latex = sprintf('%s%s', latex, ...
                            sprintf(latexFormatStringPolicy, ...
                                    Formatter.formatFloat(problem.numberOfStates, 0), ...
                                    Formatter.formatFloat(parameters.policyBaseLevel, 0), ...
                                    Formatter.formatScientificNum(policyRefineTolerance, 0), ...
                                    Formatter.formatFloat(numbersOfBasePointsPolicy, 0), ...
                                    Formatter.formatFloat(numberOfPointsPolicy, 0), ...
                                    Formatter.formatFloat(numberOfInsertedPointsPolicy, 0), ...
                                    Formatter.formatTimeHms(timePolicy), ...
                                    Formatter.formatScientificNum(errorsL2, 1), ...
                                    Formatter.formatScientificNum(errorsLInf, 1)));
          case 'complexity'
            if printFlag
                fprintf(formatString, ...
                        sprintf('%04u', id), ...
                        Formatter.formatFloat(problem.numberOfStates, 0), ...
                        gridType, ...
                        Formatter.formatFloat(p, 0), ...
                        Formatter.formatFloat(parameters.baseLevel, 0), ...
                        Formatter.formatScientific(refineTolerance, 0), ...
                        Formatter.formatFloat(numberOfPointsValue, 0), ...
                        Formatter.formatScientific(Info.Time.optimizer, 1), ...
                        Formatter.formatScientific(errorsL2, 1), ...
                        Formatter.formatFloat(numberOfOpt, 0), ...
                        Formatter.formatFloat(Info.Time.optimizer / numberOfOpt, 2), ...
                        Formatter.formatScientific(numberOfJCalls, 1, false), ...
                        Formatter.formatScientific(numberOfGradJCalls, 1, false), ...
                        Formatter.formatFloat(numberOfItPerOpt, 0), ...
                        Formatter.formatFloat(timePerIt, 0), ...
                        Formatter.formatScientific(numberOfEvalCalls, 1, false), ...
                        Formatter.formatScientific(numberOfGradEvalCalls, 1, false), ...
                        Formatter.formatScientific(numberOfEvalPerIt, 1), ...
                        Formatter.formatScientific(timePerEval, 1));
            end
            tblData = {id, problem.numberOfStates, gridType, p, parameters.baseLevel, ...
                       refineTolerance, numberOfPointsValue, Info.Time.optimizer, errorsL2, ...
                       numberOfOpt, Info.Time.optimizer / numberOfOpt, numberOfJCalls, ...
                       numberOfGradJCalls, numberOfItPerOpt, timePerIt, numberOfEvalCalls, ...
                       numberOfGradEvalCalls, numberOfEvalPerIt, timePerEval};
        case 'economic'
            if printFlag
                fprintf(formatString, ...
                        sprintf('%04u', id), ...
                        Formatter.formatFloat(problem.numberOfStates, 0), ...
                        gridType, ...
                        parameters.modelVariant, ...
                        Formatter.formatUnit(interestVola, 4 ,'%'), ...
                        Formatter.formatUnit(permanentShockVola, 4 ,'%'), ...
                        Formatter.formatFloat(problem.riskAversion, 2), ...
                        Formatter.formatFloat(problem.elasticityOfIntertemporalSubstitution, 2), ...
                        annuityPurchaseAges, ...
                        Formatter.formatUnit(CE, 0, '$'), ...
                        Formatter.formatUnit(meanL, 0, '$'), ...
                        Formatter.formatUnit(medL, 0, '$'), ...
                        Formatter.formatUnit(stdL, 0, '$'), ...
                        Formatter.formatScientific(errorsL1, 1), ...
                        Formatter.formatScientific(errorsL2, 1), ...
                        Formatter.formatScientific(errorsLInf, 1));
            end
            tblData = {id, problem.numberOfStates, gridType, parameters.modelVariant, ...
                       interestVola, permanentShockVola, problem.riskAversion, ...
                       problem.elasticityOfIntertemporalSubstitution, ...
                       annuityPurchaseAges, CE, meanL, medL, stdL, errorsL1, errorsL2, errorsLInf};
            if strcmpi(tableChoice, 'annuitypurchase')
                if strcmp(annuityPurchaseAges, '64-64')
                    annuityPurchaseAges = '64';
                    latex = sprintf('%s%s', latex, ...
                                    sprintf(latexFormatStringAges, ...
                                            annuityPurchaseAges, ...
                                            Formatter.formatUnitNum(CE, 0),...
                                            Formatter.formatUnitNum(meanL, 0), ...
                                            Formatter.formatUnitNum(medL, 0), ...
                                            Formatter.formatUnitNum(stdL, 0)));
                    prevIdx = data.ID == previousID;
                    latex = sprintf('%s%s', latex, ...
                                    sprintf(latexFormatStringDiff, ...
                                            Formatter.formatUnitNum(interestVola, 4, '%'), ...
                                            Formatter.formatUnitNum(data.CE(prevIdx) - CE, 0),...
                                            Formatter.formatUnitNum(...
                                                            data.L_avg(prevIdx) - meanL, 0), ...
                                            Formatter.formatUnitNum(...
                                                            data.L_med(prevIdx) - medL, 0), ...
                                            Formatter.formatUnitNum(...
                                                            data.L_std(prevIdx) - stdL, 0)));
                else
                    latex = sprintf('%s%s', latex, ...
                                    sprintf(latexFormatStringAges, ...
                                            annuityPurchaseAges, ...
                                            Formatter.formatUnitNum(CE, 0),...
                                            Formatter.formatUnitNum(meanL, 0), ...
                                            Formatter.formatUnitNum(medL, 0), ...
                                            Formatter.formatUnitNum(stdL, 0)));
                end
            elseif strcmpi(tableChoice, 'eis')
                eis = -problem.elasticityOfIntertemporalSubstitution + 1;
                if problem.elasticityOfIntertemporalSubstitution > problem.riskAversion
                    latex = sprintf('%s%s', latex, ...
                                    sprintf(latexFormatStringHighEis, ...
                                            Formatter.formatUnitNum(interestVola, 4, '%'), ...
                                            Formatter.formatFloat(eis, 2), ...
                                            Formatter.formatUnitNum(CE, 0),...
                                            Formatter.formatUnitNum(meanL, 0), ...
                                            Formatter.formatUnitNum(medL, 0), ...
                                            Formatter.formatUnitNum(stdL, 0)));
                else
                    latex = sprintf('%s%s', latex, ...
                                    sprintf(latexFormatStringLowAndEqualEis, ...
                                            Formatter.formatFloat(eis, 2), ...
                                            Formatter.formatUnitNum(CE, 0),...
                                            Formatter.formatUnitNum(meanL, 0), ...
                                            Formatter.formatUnitNum(medL, 0), ...
                                            Formatter.formatUnitNum(stdL, 0)));
                end
            end
    end
    data = [data; tblData]; %#ok<AGROW>
    previousID = id;
end

switch mode
    case 'default'
        latexFooter = sprintf(['    \\bottomrule\n' ...
                               '  \\end{tabular}\n' ...
                               '  \\caption[TODO]{%%\n' ...
                               '    TODO%%\n' ...
                               '  }%%\n' ...
                               '  \\label{tbl:TODO}%%\n'...
                               '\\end{table}']);
    case 'complexity'
        latexFooter = '';
    case 'economic'
        if any(strcmpi(tableChoice, {'annuitypurchase', 'eis'}))
            latexFooter = sprintf(['    \\bottomrule\n' ...
                                   '  \\end{tabular}\n' ...
                                   '  \\caption[TODO]{%%\n' ...
                                   '    TODO%%\n' ...
                                   '  }%%\n' ...
                                   '  \\label{tbl:TODO}%%\n'...
                                   '\\end{table}']);
        else
            latexFooter = '';
        end
end
% 1:end-13 to remove last \midrule before setting bottom rule
latex = sprintf('%s%s', latex(1:end-13), latexFooter);

end

function result = searchFile(path, pattern, convertToNumber)
    if ~exist('convertToNumber', 'var'); convertToNumber = true; end
    text = fileread(path);
    matches = regexp(text, pattern, 'tokens');
    if isempty(matches)
        result = [];
    elseif convertToNumber
        result = cell2mat(cellfun(@(match) str2double(match{1}), matches, ...
                                  'UniformOutput', false));
    else
        result = matches;
    end
end

function field = getField(struct_, name, default)
    if isfield(struct_, name); field = struct_.(name); else; field = default; end
end