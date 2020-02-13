classdef JobHandler < handle
    
    properties
        cluster
        Path = conStruct({'local', 'remote'});
    end
    
    methods (Access = public)
        function obj = JobHandler(cluster, localPath, remotePath)
            obj.cluster = cluster;
            obj.Path.local = localPath;
            obj.Path.remote = remotePath;
        end
        
        function job = submit(obj, fct, nargout, input, nodes, properties)
            % define local source code dependencies to copy to cluster
            attachedFiles = {[obj.Path.local filesep 'src'], ...
                             [obj.Path.local filesep 'lib'], ...
                             [obj.Path.local filesep 'resource']};

            % define remote dependencies that are already on the cluster
            additionalPaths =  {};
            
            % environment variables to be copied from client to worker
            environmentVariables = {};

            if ~iscell(input); input = {input}; end

            % extract job specific settings on cluster from properties struct
            tmp = obj.cluster.AdditionalProperties;
            fields = fieldnames(properties);
            for i = 1:numel(fields)
                obj.cluster.AdditionalProperties.(fields{i}) = properties.(fields{i});
            end

            % create and submit batch job
            job = obj.cluster.batch(...
                                    eval(fct), ...
                                    nargout, ...
                                    input, ...
                                    'pool', nodes - 1, ...
                                    'CaptureDiary', true, ...
                                    'CurrentFolder', obj.Path.remote, ...
                                    'AutoAttachFiles', false, ...
                                    'AttachedFiles', attachedFiles, ...
                                    'AutoAddClientPath', false, ...
                                    'AdditionalPaths', additionalPaths, ...
                                    'EnvironmentVariables', environmentVariables);
            % reset cluster settings state
            obj.cluster.AdditionalProperties = tmp;

            % this is also stored as a function handle in job.Tasks(1).Function and can be used,
            % e.g., via fct2str(job.Tasks(1).Function), but it is better to save the function call
            % explicitly
            job.JobData.fct = fct;

            % store job specific settings on cluster (walltime, queue name, ...)
            for i = 1:numel(fields)
                job.JobData.(fields{i}) = properties.(fields{i});
            end

            fprintf('Job %i submitted to %s at %s.\n', ...
                   job.ID, obj.cluster.Profile, datestr(now));
        end
        
        function fetch(obj, job, filenames, path)

            assert(strcmpi(job.State, 'finished'), ...
                   'Results cannot be fetched. Job %d has state %s.', job.ID, job.State);
            % Usually, the following line would fetch the outputs from fct(). However, there
            % persists a problem calling saveobj in SgppInterpolant at the parallel job (class is
            % not in path any more when the job is done, oh MATLAB...). So I create the output by
            % loading the mat files in the loadResults method
            % varargout = job.fetchOutputs();
            
            % copy results from cluster
            if ~exist('path', 'var')
                localOutPath = [obj.Path.local filesep 'out'];
                remoteOutPath = [obj.Path.remote filesep 'out'];
            else
                localOutPath = [obj.Path.local filesep path];
                remoteOutPath = [obj.Path.remote filesep path];
            end
            JobHandler.copyFilesFromCluster(obj.cluster, localOutPath, remoteOutPath, filenames);
        end

        function varargout = loadResults(obj, matFile, varnames)
            % load results and correct paths for local
            loadVariables(matFile, varnames{:});
            self.Env = obj.switchPaths(self.Env); %#ok<NODEF>

            % store modified object
            save(matFile, 'self', '-append');

            % return results
            k = numel(varnames) - 1;
            varargout = cell(1, k);
            for i = 1:k; varargout{i} = eval(varnames{i + 1}); end
        end

        function localStruct = switchPaths(obj, remoteStruct)
            warningState = warning('off', 'MATLAB:strrep:InvalidInputType');
            f = fieldnames(remoteStruct);
            for i = 1 : numel(f)
                localStruct.(f{i}) = ...
                    strrep(remoteStruct.(f{i}), obj.Path.remote, obj.Path.local);
            end
            warning(warningState);
        end
        
        function [log, location] = getDebugLog(obj, job)
            log = obj.cluster.getDebugLog(job);
            location = obj.cluster.getLogLocation(job);
        end

        function job = findJob(obj, id)
            if ischar(id); id = str2double(id); end
            job = obj.cluster.findJob('ID', id);
        end
    end

    methods (Static)
        function copyFilesFromCluster(cluster, localPath, remotePath, filenames)
            user = cluster.AdditionalProperties.UserNameOnCluster;
            host = cluster.AdditionalProperties.ClusterHost;
            if ~iscell(filenames); filenames = {filenames}; end
            for filename = filenames
                runCommand(sprintf('scp %s@%s:%s %s', user, host, ...
                                   [remotePath filesep filename{:}], ...
                                   [localPath filesep filename{:}]));
            end
        end
    end
end

