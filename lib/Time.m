classdef Time < handle
    properties (SetAccess = private)
        index
    end
    
    properties (Dependent)
        age
    end
    
    properties (SetAccess = private)
        ageStart
        ageStop
        ageStep
    end
    
    properties (Access = private)
        prevPrev
        prev
        next
        nextNext
    end
    
    methods
        function self = Time(index, ageStart, ageStop, ageStep)
            if nargin > 0
                self.index = index;
                self.ageStart = ageStart;
                self.ageStop = ageStop;
                self.ageStep = ageStep;
                self.prevPrev = [];
                self.prev = [];
                self.next = [];
                self.nextNext = [];
            end
        end
        
        function index = subsindex(times)
            % 1. subsindex's return value has to be zero-based (seriously MATLAB, wtf?!)
            % 2. times could be a Time object or a Time array, therefore "[times.index]"
            %    (renaming times to "self" doesn't work in this case...)
            index = [times.index] - 1;
        end
        
        function t = colon(a, b, c)
            if nargin < 3
                step = 1;
            else
                step = b;
                b = c;
            end
            
            I = a.index:step:b.index;
            t = repmat(Time(), 1, numel(I));
            
            for k = 1:numel(I)
                t(k) = Time(I(k), a.ageStart, a.ageStop, a.ageStep);
            end
        end
        
        function t = getRange(self)
            t = self.getStart():self.ageStep:self.getStop();
        end
        
        function obj = plus(self, other)
            if (other == 1) && ~isempty(self.next)
                obj = self.next;
            elseif (other == 2) && ~isempty(self.nextNext)
                obj = self.nextNext;
            else
                obj = Time(self.index + other, self.ageStart, self.ageStop, self.ageStep);
                
                if     other == 1; self.next = obj;
                elseif other == 2; self.nextNext = obj; end
            end
        end
        
        function obj = getNext(self)
            obj = self + 1;
        end
        
        function obj = minus(self, other)
            if (other == 1) && ~isempty(self.prev)
                obj = self.prev;
            elseif (other == 2) && ~isempty(self.prevPrev)
                obj = self.prevPrev;
            else
                obj = Time(self.index - other, self.ageStart, self.ageStop, self.ageStep);
                
                if     other == 1; self.prev = obj;
                elseif other == 2; self.prevPrev = obj; end
            end
        end
        
        function obj = getPrev(self)
            obj = self - 1;
        end
        
        function obj = copy(self, index)
            if nargin < 2; index = self.index; end
            obj = Time(index, self.ageStart, self.ageStop, self.ageStep);
        end
        
        function b = isStart(self)
            b = (self.index == 1);
        end
        
        function b = isStop(self)
            b = (self.age == self.ageStop);
        end
        
        function b = isValid(self)
            b = ((self.index >= 1) && (self.age <= self.ageStop));
        end
        
        function obj = getStart(self)
            obj = Time(1, self.ageStart, self.ageStop, self.ageStep);
        end
        
        function obj = getStop(self)
            obj = Time(1, self.ageStart, self.ageStop, self.ageStep);
            obj.age = self.ageStop;
        end
        
        function age = get.age(self)
            age = self.ageStart + (self.index - 1) * self.ageStep;
        end
        
        function set.age(self, age)
            self.index = (age - self.ageStart) / self.ageStep + 1;
        end
    end
end
