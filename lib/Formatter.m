classdef Formatter < handle
    methods (Static)
        function str = formatFloat(number, digits)
            if ischar(number)
                str = number;
            elseif isnan(number)
                str = '-';
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
                str = '-';
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
                str = '-';
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
                str = '-';
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
                str = '-';
            elseif time >= 3600
                str = sprintf('%u;%u', floor(time / 3600), round(mod(time, 3600) / 60));
            else
                str = sprintf(';%u', round(time / 60));
            end
        end

        function str = formatUnit(number, digits, unit)
            if ischar(number)
                str = sprintf('%s%s', number, unit);
            elseif isnan(number)
                str = sprintf('%s%s', '-', unit);
            else
                str = '';
                i = 0;
                while number > 0
                    if (number < 1000)
                        if i > 0
                            str = sprintf("%3.f%s", number, str);
                        else
                            str = sprintf (sprintf("%%3.%uf%%s", digits), number, str);
                        end
                        break;
                    end
                    str = sprintf(sprintf(",%%03.%uf%%s", digits), mod(number, 1000), str);
                    number = floor(number / 1000);
                    i = i + 1;
                end
                str = sprintf('%s%s', str, unit);
            end
        end

        function str = formatUnitNum(number, digits, unit)

        if ~exist('unit', 'var')
            if ischar(number)
                str = sprintf('\\num{%s}', number);
            elseif isnan(number)
                str = '-';
            else
                str = sprintf(sprintf("\\\\num{%%.%uf}", digits), number);
            end
        else
            if ischar(number)
                str = sprintf('\\SI{%s}{\\%s}', number, unit);
            elseif isnan(number)
                str = '-';
            else
                str = sprintf(sprintf("\\\\SI{%%.%uf}{\\\\%%s}", digits), number, unit);
            end
        end
        end
    end
end

