function copyResultFiles(sourcePath, targetPath, filenames)
% copy one or multiple files from previous ID to new ID
if ~iscell(filenames); filenames = {filenames}; end
for filename = filenames
    copyfile([sourcePath filesep filename{:}], [targetPath filesep filename{:}]);
end
end
