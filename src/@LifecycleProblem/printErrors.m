function printErrors(self, errors, times)

if nargin < 3
    times = self.Time.getRange();
    times = times(1:numel(errors));
end

%% allocate folders for output and output file
if ~exist(self.Env.outdir, 'dir')
    mkdir(self.Env.outdir);
end
fid = fopen([self.Env.outdir filesep inputname(2) '.txt'], 'w');
if isfield(errors, 'Grid1D'); errors = rmfield(errors, 'Grid1D'); end
err = struct2struct(errors);

%% print the errors to console and file
msg = sprintf('age \t l1 \t\t l2 \t\t max\n');
printToConsoleAndFile(fid, msg);
for r = 1:numel(times)
    t = times(r);
    e   = [err.L1(r, :)' err.L2(r, :)' err.Max(r, :)'];
    msg = sprintf('%i \t %.2e \t %.2e \t %.2e \n', t.age, e(1, :));
    printToConsoleAndFile(fid, msg);
    if size(e, 1) > 1
        msg = sprintf('\t %.2e \t %.2e \t %.2e \n', e(2:end, :)');
        printToConsoleAndFile(fid, msg);
    end
end

msg = sprintf('Average errors:\n \t \t l1 \t\t l2 \t\t max\n');
printToConsoleAndFile(fid, msg);
e   = [nanmean(err.L1); nanmean(err.L2); nanmean(err.Max)];
msg = sprintf('\t %.2e \t %.2e \t %.2e \n', e);
printToConsoleAndFile(fid, msg);

fclose(fid);
