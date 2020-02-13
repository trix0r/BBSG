function plotJ(self, varargin)

if numel(varargin) > 1
    varargin{2} = self.cropToEligibleState(varargin{2});
end

self.plotJ@LifecycleProblem(varargin{:});

end
