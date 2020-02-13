function loadParameter(self)

%% paths
self.Env.path   = pwd;
self.Env.outdir = [self.Env.path filesep 'out'];
self.Env.logdir = [self.Env.path filesep 'log'];

%% make sure mex interface is in path
assert(exist('sgppInterface', 'file') == 3, 'Please compile SGpp mex interface first.');

self.Env.print = 0;

self.Env.resume = 0;

end
