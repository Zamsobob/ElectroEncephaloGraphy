function [subjectList, fileExt, rawDataPath] = createSubjectList(projectPath)
% subjectList = createSubjectList(projectPath)
% Sets up prerequisite folder structure
%
% INPUTS:
% projectPath: a string vector of the project folder, for example the
%              github main branch (e.g. pwd). The folder should contain the raw data in EEGLAB .set
%              format and the utilities folder somewhere inside.
%
% OUTPUTS:
% subjectList: a cell array containing all subjects. Useful for iterating
%              through each subject.
%

%% Check the input data
% check that data is a character array (string)
if ~isa(projectPath, 'char')
    help setupDirAndSubjectList
    error('Data must be a character array (string)!');
end

%% Create subject list

filelist=dir(fullfile(projectPath,'**','EMP01.set')); % Find raw data
rawDataPath = filelist.folder; % Path to raw data (EEGLAB format)
% % Add analysis to path
% analysisPath = dir(fullfile(projectPath,'**','analysis'));
% addpath(analysisPath(1).folder)

% Save the file extension (.set) as a variable
[~,~,fileExt] = fileparts(filelist.name);
% Create cell array containing all subjects for iteration
cd (rawDataPath);
subjectList=dir(['**/*' fileExt]);
subjectList={subjectList.name};
% subjectList = extractBefore(subjectList, fileExt);
cd (projectPath);
