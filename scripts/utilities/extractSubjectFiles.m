function lists = extractSubjectFiles(projectPath, fileExt)
% subjectList = createSubjectList(projectPath)
% Extracts a list of all subjects, file names, and paths to raw data.
% Useful for iteration. Works if the data files are in individual folders
% or all in the same folder.
%
% INPUTS:
% projectPath: a string vector of the project folder, for example the
%              github main branch (e.g. pwd). The folder should contain the raw data somewhere inside.
% fileExt:     File extension to the raw data files. For example: '.set',
%               '.vhdr', etc.
%
% OUTPUTS:
% subjectList: a cell array containing all subjects. Useful for iterating
%              through each subject.
% fileNames    a cell array containing the names of each raw data file,
%              i.e. subjectList with file extension.
% dataPath     a cell array containing the paths to each subject's raw data
%              folder.
%

%% Check the input data
% check that first input is a character array
if ~isa(projectPath, 'char')
    help extractSubjectFiles
    error('Error: Data must be a character array.');
end
% check that first input is an existing folder
if ~isfolder(projectPath)
    help extractSubjectFiles
    error('Error: The following folder does not exist:\n%s\nPlease specify a new folder.', projectPath);
end
%% Create subject list
% fileExt  = '.set'; % input argument
filelist = dir(fullfile(projectPath,'**',['*' fileExt])); % Find data files

% Initialize
% subjectList = cell(length(filelist),1);
% fileName    = cell(length(filelist),1);
% dataPath    = cell(length(filelist),1);
lists = struct('subjectList', [],'fileName', [], 'dataPath',[]);
% Loop over subject files and extract info
for i=1:length(filelist)
    lists(i).subjectList = extractBefore(filelist(i).name,fileExt);
    lists(i).fileName    = char(filelist(i).name);
    lists(i).dataPath    = char(filelist(i).folder);
end