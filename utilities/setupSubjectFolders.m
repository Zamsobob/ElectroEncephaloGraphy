function subjFolderPaths = setupSubjectFolders(projectPath) % ppDir
% subjFolderPaths = setupSubjectFolders(projectPath, ppDir)
% Sets up individual subject folders inside the specified folder. Also
% returns a cell array containing the paths of the created subject folders.
%
% INPUTS:
% projectPath:      a string vector of the project folder, for example the
%                   github main branch (e.g. pwd). The folder should contain the raw data in
%                   EEGLAB .set format and the utilities folder somewhere inside.
%
% [inactive] ppDir  a string vector specifying the path to the preprocessing folder.
%
% OUTPUTS:
% subjFolderPaths:  a cell array containing the paths of the created subject folders.
%

%% Create a list of subjects to loop through
[subjectList, fileExt, ~] = createSubjectList(projectPath);
subjFolderPaths = cell(1, length(subjectList));

% cd(ppDir)
%% Create subject folders (if they do not already exist)
for subj = 1:length(subjectList)
    currentSubj           = extractBefore(subjectList(subj), fileExt);
    currentSubj           = char(currentSubj);
    subjFolderPaths{subj} = strcat(projectPath,filesep,currentSubj); %strcat(ppDir,filesep,currentSubj);
    if ~exist(currentSubj, 'dir')
        mkdir(currentSubj)
    end
end
subjFolderPaths = cellfun(@char,subjFolderPaths,'UniformOutput',false);
subjFolderPaths = cell2struct(subjFolderPaths ,'subjFolderPaths');
%cd(projectPath)