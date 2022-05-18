%% Produce text files of the total number of ICs obtained from ICA decomposition and a breakdown with the number of components
% identified as pertaining to a given class of non-brain signal.
%
% The components were automatically removed using ICLabel (see
% run_preprocessing.m for more information)
%
%% setup
projectPath = pwd; % Main branch
utilitiesPath = dir(fullfile(projectPath,'**','utilities'));
addpath(utilitiesPath(1).folder)

% Create subject folders (if they do not exist)
% and save the paths to those folders
lists.subjFolderPaths = setupSubjectFolders(projectPath);

% Create a list of subjects to loop through. Also returns the path to the raw
% data and the file extension
[lists.subjectList, fileExt, rawDataPath] = createSubjectList(projectPath);

% Initialize EEGLAB structure
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
close all;
% EEGLAB options: use double precision, keep at most one dataset in memory
pop_editoptions('option_single', 0, ...
    'option_storedisk', 1);

%% Extract epochs and remove noisy epochs
% Loop over all subjects
for sub = 1:length(lists.subjectList)
    %% Load current subject
    subject    = lists.subjectList{sub};
    subject    = extractBefore(subject, fileExt);
    fileName    = '5_removeDC_hpfilt_resamp_rerefMastoid_remLineNoise_badChansRem_ICA_weights_labeled';
    subjFolder = [lists.subjFolderPaths(sub).subjFolderPaths filesep fileName];

    % Load current dataset
    EEG = pop_loadset('filename',[fileName fileExt], ...
        'filepath', subjFolder);

% Save number of components from ICA decomposition (before removal etc, for reporting)
hi(sub).sub = subject;
hi(sub).numcomps = size(EEG.etc.ic_classification.ICLabel.classifications,1);

% write to userpath, move manually later
writeto = [userpath filesep subject '_nrComponentsObtainedICA'];
% writematrix(hi(sub).numcomps, writeto)

% save which components were classified as eye and which were classified as
% muscle (by ICLabel). Columns are the 7 classes, rows component number. Values percentage
% classifications. Find those above 80% for col 2: muscle and col 3: eye
a_eye = EEG.etc.ic_classification.ICLabel.classifications(:,3);
a_musc = EEG.etc.ic_classification.ICLabel.classifications(:,2);
hi(sub).rem_eye    = find(a_eye >= 0.8);
hi(sub).rem_muscle = find(a_musc >= 0.8);
numrejected = length(hi(sub).rem_eye) + length(hi(sub).rem_muscle);

% write to userpath, move manually later
hello = ['For subject ' num2str(sub) ', our ICA decomposition yielded ' num2str(hi(sub).numcomps)  ... 
    ' components. From those, we rejected a total of ' num2str(numrejected) ' components, with ' ...
    num2str(length(hi(sub).rem_eye)) ' being eye artifacts and ' num2str(length(hi(sub).rem_muscle)) ' being muscle artifacts.'];
writeto2 = [userpath filesep subject '_classificationRemovedICs'];
writematrix(hello, writeto2)

end
