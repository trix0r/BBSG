classdef SgppInterpolant < handle
    properties(SetAccess = 'protected', GetAccess = 'public')
        gridString % serialized string representation of grid
        gridType
        generationType
        dimension
        level       % max refinements for any dimension
        anisotropicWeights
        lowerBounds % integral boundaries
        upperBounds
        degree
        values % if fitted, the values the interpolant is fitted to
        surpluses % if fitted, the coefficients
        DomainTrafo
        ValueTrafo
    end
    
    properties(SetAccess = 'public', GetAccess = 'public')
        extrapolationType
        extrapolationAccuracy
    end
    
    properties(SetAccess = 'protected', GetAccess = 'public', Transient = true)
        % grid handle and points will not be saved and will be recreated when loaded
        gridHandle
        gridPoints
    end
    
    properties(Access = 'protected')
        lbt
        ubt
    end
    
    methods(Static = true)
        function obj = loadobj(savedObj)
            obj = SgppInterpolant();
            [obj.gridHandle, ~] = sgppInterface('loadgrid', savedObj.gridString);
            obj.copyProperties(savedObj);
            obj = SgppInterpolant.copyProperties(savedObj, obj);
            
            if ~isempty(savedObj.values) && isempty(savedObj.surpluses)
                obj.fit(savedObj.values);
            end
        end
        
        function destObj = copyProperties(srcObj, destObj)
            destObj.gridType           = srcObj.gridType;
            destObj.generationType     = srcObj.generationType;
            destObj.dimension          = srcObj.dimension;
            destObj.level              = srcObj.level;
            destObj.anisotropicWeights = srcObj.anisotropicWeights;
            destObj.lowerBounds        = srcObj.lowerBounds;
            destObj.upperBounds        = srcObj.upperBounds;
            destObj.degree             = srcObj.degree;
            destObj.values             = srcObj.values;
            destObj.surpluses          = srcObj.surpluses;
            destObj.extrapolationType      = srcObj.extrapolationType;
            destObj.extrapolationAccuracy  = srcObj.extrapolationAccuracy;
            destObj.DomainTrafo        = srcObj.DomainTrafo;
            destObj.ValueTrafo         = srcObj.ValueTrafo;
            destObj.lbt                = srcObj.lbt;
            destObj.ubt                = srcObj.ubt;
            destObj.gridPoints         = srcObj.gridPoints;
        end
    end
    
    methods
        function obj = SgppInterpolant(varargin)
            if nargin == 0
                return;
            else
                obj.gridType        = varargin{1};
                obj.generationType  = varargin{2};
                obj.dimension       = uint32(varargin{3});
                obj.level           = uint32(varargin{4});
                obj.anisotropicWeights      = uint32(varargin{5});
                obj.lowerBounds     = varargin{6};
                obj.upperBounds     = varargin{7};
                obj.degree          = uint32(varargin{8});
                obj.extrapolationType       = varargin{9};
                obj.extrapolationAccuracy   = varargin{10};
                obj.DomainTrafo     = varargin{11};
                obj.ValueTrafo      = varargin{12};
                
                [obj.gridHandle, p] = sgppInterface(...
                    'creategrid', ...
                    obj.gridType, ...
                    obj.generationType, ...
                    obj.dimension, ...
                    obj.level, ...
                    obj.anisotropicWeights, ...
                    obj.degree ...
                    );
            end
            
            if isempty(obj.DomainTrafo)
                obj.lbt = obj.lowerBounds;
                obj.ubt = obj.upperBounds;
            else
                obj.lbt = obj.DomainTrafo.map(obj.lowerBounds);
                obj.ubt = obj.DomainTrafo.map(obj.upperBounds);
            end
            obj.gridPoints = obj.mapUnitCubeToDomain(p);
        end
        
        function delete(obj)
            if ~isempty(obj.gridHandle)
                sgppInterface('destroygrid', obj.gridHandle);
            end
        end
        
        function savedObj = saveobj(obj)
            savedObj = SgppInterpolant.copyProperties(obj, struct());
            savedObj.gridString = sgppInterface('storegrid', obj.gridHandle)';
        end
        
        function newObj = copy(obj, gridType_, degree_)
            if nargin < 2; gridType_ = obj.gridType; end
            if nargin < 3; degree_ = obj.degree; end
            
            typeChanged = ((~strcmp(gridType_, obj.gridType)) || ...
                           (isempty(degree_) ~= isempty(obj.degree)) || ...
                           (~isempty(degree_) && (degree_ ~= obj.degree)));
            
            newObj = SgppInterpolant();
            newObj = SgppInterpolant.copyProperties(obj, newObj);
            newObj.degree     = uint32(degree_);
            newObj.gridType   = gridType_;
            
            newObj.gridHandle = sgppInterface(...
                'copygrid', ...
                obj.gridHandle, ...
                newObj.gridType, ...
                newObj.degree ...
                );
            
            if typeChanged
                if~isempty(newObj.values) && ~isempty(newObj.surpluses)
                    newObj.fit(newObj.values);
                else
                    newObj.surpluses = [];
                end
            end
        end
        
        function joinGrids(obj, otherObj_)
            p = sgppInterface('joingrids', obj.gridHandle, otherObj_.gridHandle);
            obj.gridPoints = obj.mapUnitCubeToDomain(p);
            % refitting must be done
            obj.surpluses = [];
        end
        
        function fit(obj, values_)
            obj.values    = values_;
            if ~isempty(obj.ValueTrafo)
                values_ = obj.ValueTrafo.inv(values_);
            end
            obj.surpluses = sgppInterface('fit', obj.gridHandle, values_);
        end
        
        function newGridPoints = insertChains(obj, degree_)
            p = sgppInterface('insertchains', obj.gridHandle, uint32(degree_));
            newGridPoints  = obj.mapUnitCubeToDomain(p(size(obj.gridPoints, 1) + 1 : end, :));
            obj.gridPoints = obj.mapUnitCubeToDomain(p);
            if ~isempty(newGridPoints)
                % refitting must be done
                obj.surpluses = [];
            end
        end

        function newGridPoints = refine(obj, type_, criterion_, refinements_, threshold_, ...
                                        enableUP_, degree_)
            if isempty(obj.surpluses)
                error('Perform ''fit'' operation first!');
            end
            if nargin < 5
                t = 0.0;
                if nargin < 4
                    r = uint32(1);
                else
                    r = uint32(refinements_);
                end
            else
                t = threshold_;
                r = uint32(refinements_);
            end
            if nargin < 6
                enableUP_ = false;
                degree_ = [];
            end
            p = sgppInterface('refine', obj.gridHandle, type_, criterion_, obj.surpluses, ...
                              r, t, enableUP_, uint32(degree_));
            newGridPoints  = obj.mapUnitCubeToDomain(p(size(obj.gridPoints, 1) + 1 : end, :));
            obj.gridPoints = obj.mapUnitCubeToDomain(p);
            if ~isempty(newGridPoints)
                % refitting must be done
                obj.surpluses = [];
            end
        end
        
        function removedGridPoints = coarsen(obj, criterion_, coarsening_, threshold_)
            if isempty(obj.surpluses)
                error('Perform ''fit'' operation first!');
            end
            if nargin < 4
                t = 0.0;
                if nargin < 3
                    r = uint32(1);
                else
                    r = uint32(coarsening_);
                end
            else
                t = threshold_;
                r = uint32(coarsening_);
            end
            p   = sgppInterface('coarse', obj.gridHandle, criterion_, obj.surpluses, r, t);
            tmp = obj.gridPoints;
            obj.gridPoints             = obj.mapUnitCubeToDomain(p);
            [removedGridPoints, idx]   = setdiff(tmp, obj.gridPoints, 'rows');
            % remove values and surpluses of removed grid points
            obj.values    = obj.values(setdiff(1 : end, idx));
            if ~isempty(removedGridPoints) && ~isempty(strfind(obj.gridType,'spline'))
                % for splines, refitting must be done
                obj.surpluses = [];
            else
                obj.surpluses = obj.surpluses(setdiff(1 : end, idx));
            end
        end
        
        function [values, gradient] = evaluate(obj, points_)
            if isempty(obj.DomainTrafo)
                points = points_;
            else
                points = obj.DomainTrafo.map(points_);
            end
            
            if nargout == 1
                values = sgppInterface('evaluate', obj.gridHandle, obj.surpluses, ...
                    points, obj.extrapolationType, obj.extrapolationAccuracy, obj.lbt, obj.ubt);
            else
                [values, gradient] = sgppInterface('evaluate', obj.gridHandle, obj.surpluses, ...
                    points, obj.extrapolationType, obj.extrapolationAccuracy, obj.lbt, obj.ubt);
                if ~isempty(obj.ValueTrafo)
                    gradient = bsxfun(@times, obj.ValueTrafo.deriv(values), gradient);
                end
                if ~isempty(obj.DomainTrafo)
                    % trafoDeriv(k,t,:) = d/dxt trafo(points_(k,:))
                    trafoDeriv = obj.DomainTrafo.deriv(points_);
                    for k = 1:size(points_, 1)
                        gradient(k,:) = squeeze(trafoDeriv(k,:,:)) * gradient(k,:)';
                    end
                end
            end
            
            if ~isempty(obj.ValueTrafo)
                values = obj.ValueTrafo.map(values);
            end
        end
        
        function points = mapUnitCubeToDomain(obj, points_)
            points = bsxfun(@plus, obj.lbt, bsxfun(@times, obj.ubt - obj.lbt, points_));
            if ~isempty(obj.DomainTrafo)
                points = obj.DomainTrafo.inv(points);
            end
        end
        
        function points = mapDomainToUnitCube(obj, points_)
            if isempty(obj.DomainTrafo)
                points = points_;
            else
                points = obj.DomainTrafo.map(points_);
            end
            points = bsxfun(@rdivide, bsxfun(@minus, points, obj.lbt), obj.ubt - obj.lbt);
        end
        
        function setDomain(obj, lowerBounds_, upperBounds_, DomainTrafo_)
            p = obj.mapDomainToUnitCube(obj.gridPoints);
            obj.DomainTrafo = DomainTrafo_;
            obj.lowerBounds = lowerBounds_;
            obj.upperBounds = upperBounds_;
            if isempty(DomainTrafo_)
                obj.lbt = obj.lowerBounds;
                obj.ubt = obj.upperBounds;
            else
                obj.lbt = DomainTrafo_.map(obj.lowerBounds);
                obj.ubt = DomainTrafo_.map(obj.upperBounds);
            end
            obj.gridPoints = obj.mapUnitCubeToDomain(p);
        end
        
        function setValueTrafo(obj, ValueTrafo_)
            obj.ValueTrafo = ValueTrafo_;
            obj.surpluses = [];
        end
    end
end
