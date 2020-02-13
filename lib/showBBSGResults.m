function [data, latex] = showBBSGResults(ids, mode, suppressOutput)

if ~exist('ids', 'var'); ids = []; end
if ischar(ids); ids = eval(ids); end
if ~exist('mode', 'var'); mode = 'default'; end
if ~exist('suppressOutput', 'var'); printFlag = true; else; printFlag = ~suppressOutput; end

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
        latexHeader = sprintf(['\\begin{table}\n' ...
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
            [properties, ~, ~, Info, ~, errors, ~] = loadResult(id, ...
                    {'properties', 'Info', 'errors'});
        else
            [properties, ~, ~, ~, ~, errors, ~] = loadResult(id, ...
                    {'properties', 'errors'});
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
        numberOfInsertedPointsValue = numbersOfInsertedPointsValue(end);

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
        numbersOfBasePointsPolicy = mean(numbersOfBasePointsPolicy(1,:));
        numberOfPointsPolicy = mean(numbersOfPointsPolicy(end,:));
        numberOfInsertedPointsPolicy = mean(numbersOfInsertedPointsPolicy(end,:));
    else
        timePolicy = NaN;
        numberOfPointsPolicy = NaN;
        numberOfInsertedPointsPolicy = NaN;
    end

    if ~isempty(errors)
        err = struct2struct(errors);
        errorsL2   = nanmean(err.L2(:,2));
        errorsLInf = nanmean(err.Max(:,2));
    else
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

    switch mode
        case 'default'
            if printFlag
                fprintf(formatString, ...
                        sprintf('%04u', id), ...
                        formatFloat(parameters.numberOfStocks, 0), ...
                        gridType, ...
                        formatFloat(parameters.baseLevel, 0), ...
                        formatScientific(refineTolerance, 0), ...
                        formatFloat(numberOfPointsValue, 0), ...
                        formatFloat(numberOfInsertedPointsValue, 0), ...
                        formatTime(timeValue), ...
                        formatFloat(parameters.policyBaseLevel, 0), ...
                        formatScientific(policyRefineTolerance, 0), ...
                        formatFloat(numberOfPointsPolicy, 0), ...
                        formatFloat(numberOfInsertedPointsPolicy, 0), ...
                        formatTime(timePolicy), ...
                        formatScientific(errorsL2, 1), ...
                        formatScientific(errorsLInf, 1));
            end
            tblData = {id, parameters.numberOfStocks, gridType, parameters.baseLevel, ...
                       refineTolerance, numberOfPointsValue, numberOfInsertedPointsValue, ...
                       timeValue, parameters.policyBaseLevel, policyRefineTolerance, ...
                       numberOfPointsPolicy, numberOfInsertedPointsPolicy, timePolicy, ...
                       errorsL2, errorsLInf};
            latex = sprintf('%s%s', latex, ...
                            sprintf(latexFormatStringValue, ...
                                    formatFloat(parameters.baseLevel, 0), ...
                                    formatScientificNum(refineTolerance, 0), ...
                                    formatFloat(numbersOfBasePointsValue, 0), ...
                                    formatFloat(numberOfPointsValue, 0), ...
                                    formatFloat(numberOfInsertedPointsValue, 0), ...
                                    formatTimeHms(timeValue)));
           latex = sprintf('%s%s', latex, ...
                            sprintf(latexFormatStringPolicy, ...
                                    formatFloat(parameters.numberOfStocks, 0), ...
                                    formatFloat(parameters.policyBaseLevel, 0), ...
                                    formatScientificNum(policyRefineTolerance, 0), ...
                                    formatFloat(numbersOfBasePointsPolicy, 0), ...
                                    formatFloat(numberOfPointsPolicy, 0), ...
                                    formatFloat(numberOfInsertedPointsPolicy, 0), ...
                                    formatTimeHms(timePolicy), ...
                                    formatScientificNum(errorsL2, 1), ...
                                    formatScientificNum(errorsLInf, 1)));
          case 'complexity'
            if printFlag
                fprintf(formatString, ...
                        sprintf('%04u', id), ...
                        formatFloat(parameters.numberOfStocks, 0), ...
                        gridType, ...
                        formatFloat(p, 0), ...
                        formatFloat(parameters.baseLevel, 0), ...
                        formatScientific(refineTolerance, 0), ...
                        formatFloat(numberOfPointsValue, 0), ...
                        formatScientific(Info.Time.optimizer, 1), ...
                        formatScientific(errorsL2, 1), ...
                        formatFloat(numberOfOpt, 0), ...
                        formatFloat(Info.Time.optimizer / numberOfOpt, 2), ...
                        formatScientific(numberOfJCalls, 1, false), ...
                        formatScientific(numberOfGradJCalls, 1, false), ...
                        formatFloat(numberOfItPerOpt, 0), ...
                        formatFloat(timePerIt, 0), ...
                        formatScientific(numberOfEvalCalls, 1, false), ...
                        formatScientific(numberOfGradEvalCalls, 1, false), ...
                        formatScientific(numberOfEvalPerIt, 1), ...
                        formatScientific(timePerEval, 1));
            end
            tblData = {id, parameters.numberOfStocks, gridType, p, parameters.baseLevel, ...
                       refineTolerance, numberOfPointsValue, Info.Time.optimizer, errorsL2, ...
                       numberOfOpt, Info.Time.optimizer / numberOfOpt, numberOfJCalls, ...
                       numberOfGradJCalls, numberOfItPerOpt, timePerIt, numberOfEvalCalls, ...
                       numberOfGradEvalCalls, numberOfEvalPerIt, timePerEval};
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

function str = formatFloat(number, digits)
    if ischar(number)
        str = number;
    elseif isnan(number)
        str = '?';
    else
        str = sprintf(sprintf('%%.%uf', digits), number);
    end
end

function str = formatScientific(number, digits, withPlusSign)
    if ~exist('withPlusSign', 'var'); withPlusSign = true; end

    if ischar(number)
        str = number;
    elseif isinf(number)
        if number > 0; str = ' Inf'; else; str = '-Inf'; end
    elseif number == 0
        str = '0';
    elseif isnan(number)
        str = '?';
    else
        str = sprintf(sprintf('%%.%ue', digits), number);
        matches = regexp(str, '(.*)e([+\-])(.*)', 'tokens');
        mantissa = matches{1}{1};
        sign = matches{1}{2};
        exponent = dec2hex(str2double(matches{1}{3}));
        if withPlusSign || (number < 1)
            str = [mantissa 'e' sign exponent];
        else
            str = [mantissa 'e' exponent];
        end
    end
end

function str = formatScientificNum(number, digits, withPlusSign)
    if ~exist('withPlusSign', 'var'); withPlusSign = true; end

    if ischar(number)
        str = sprintf('\\num{%s}', number);
    elseif isinf(number)
        if number > 0; str = '$\infty$'; else; str = '$-\infty$'; end
    elseif number == 0
        str = '\num{0}';
    elseif isnan(number)
        str = '?';
    else
        str = sprintf(sprintf('%%.%ue', digits), number);
        matches = regexp(str, '(.*)e([+\-])(.*)', 'tokens');
        mantissa = matches{1}{1};
        sign = matches{1}{2};
        exponent = matches{1}{3};
        if withPlusSign || (number < 1)
            str = [mantissa 'e' sign exponent];
        else
            str = [mantissa 'e' exponent];
        end
        str = sprintf('\\num{%s}', str);
    end
end

function str = formatTime(time)
    if ischar(time)
        str = time;
    elseif isnan(time)
        str = '?';
    elseif time >= 3600
        str = sprintf('%2uh%02um', floor(time / 3600), round(mod(time, 3600) / 60));
    else
        str = sprintf('   %2um', round(time / 60));
    end
end

function str = formatTimeHms(time)
    if ischar(time)
        str = time;
    elseif isnan(time)
        str = '?';
    elseif time >= 3600
        str = sprintf('%u;%u', floor(time / 3600), round(mod(time, 3600) / 60));
    else
        str = sprintf(';%u', round(time / 60));
    end
end
