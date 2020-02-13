function output = runCommand(command)
% run command, check for successful status, and return output
[status, output] = system(command);
assert((status == 0), sprintf('Command "%s" failed with code %u.', command, status));
end
