classdef MortalityTable < handle
    
    properties(Access='public')
        mortalities
        extrapolatedMortalities
        survivalProbabilitiesMale
        survivalProbabilitiesFemale
        startAge
        endAge
    end
    
    methods(Access='public')
        
        function loadMortalityTable(this, matFile, startAge, endAge)
            load(matFile, 'age_data', 'fom_data');
            this.mortalities = [age_data fom_data];
            if nargin < 4
                this.endAge = max(age_data);
                if nargin < 3
                    this.startAge = min(age_data) + 1;
                else
                    this.startAge = startAge;
                end
            else
                this.startAge = startAge;
                this.endAge = endAge;
            end
            % constant extrapolation
            e = [(length(this.mortalities) - 1 : 1 : this.endAge - 1)' ...
                repmat(this.mortalities (end - 1, 2 : 3), ...
                this.endAge - length(this.mortalities ) + 1, 1)...
                ];
            this.extrapolatedMortalities = [this.mortalities(1 : end - 1, :); e];
            
            this.survivalProbabilitiesMale            = 1 - this.extrapolatedMortalities(...
                                                        (this.startAge:this.endAge - 1) + 1, 2);
            this.survivalProbabilitiesMale(end + 1)   = 0;
            this.survivalProbabilitiesFemale          = 1 - this.extrapolatedMortalities(...
                                                        (this.startAge:this.endAge - 1) + 1, 3);
            this.survivalProbabilitiesFemale(end + 1) = 0;
        end
        
        function sp = computeSurvivalProbability(this, age, ageStep, sex)
            x = ageStep;
            
            if strcmp(sex, 'male')
                y = log(this.survivalProbabilitiesMale(floor(age) - this.startAge + 1));
            elseif strcmp(sex, 'female')
                y = log(this.survivalProbabilitiesFemale(floor(age) - this.startAge + 1));
            else
                error('Invalid sex! Choose from ''male'' of ''female''');
            end
            
            sp  = exp(y .* x');
        end
        
        function sp = computeCumulatedSurvivalProbability(this, fromAge, toAge, ageStep, sex)
            a   = (fromAge : ageStep : toAge - ageStep);
            sp  = prod(computeSurvivalProbability(this, a, ageStep, sex));
        end
        
    end   
end

