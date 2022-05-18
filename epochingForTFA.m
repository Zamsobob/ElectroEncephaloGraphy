%% Epoching prior to time-frequency analysis (for hypotheses 2b,2c,3b,4b)

% Data were segmented into data epochs from -1000 ms to 1500 ms relative to all event markers, and automatic
% epoch rejection was applied in two stages. First, epochs with amplitudes exceeding a two-sided threshold of
% +- 400 microvolts were rejected. Next, a probability test (Delorme et al., 2007) was subsequently applied
% (6 SD for single channels; 3 SD for all channels) and, again, selected epochs were removed. Participants with
% above 20% rejected trials were removed from further analysis (n = 0). Epochs corresponding to the conditions of
% interest (i.e. subsequently remembered and subsequently forgotten images) were subsequently extracted and
% subjected to time-frequency analysis.

% This script was used after run_preprocessing.m and before TFA.m.
%% Set up
% Setup project path (github main branch) and add the utilities folder to path
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
    fileName    = [subject '_preprocessed.set'];
    subjFolder = lists.subjFolderPaths(sub).subjFolderPaths;

    % Load current dataset
    EEG = pop_loadset('filename',fileName, ...
        'filepath', subjFolder);

    % Create epochs around all events
    EEG = pop_epoch( EEG, ...
        {  '1030'  '1031'  '1039'  '1040'  '1041'  '1049'  '1110'  '1111'  '1119'  '1120'  '1121'  '1129'  '2030'  '2031'  '2039'  '2040'  '2041'  '2049'  '2091'  '2110'  '2111'  '2119'  '2120'  '2121'  '2129'  }, ...
        [-1 1.5], 'newname', EEG.setname, 'epochinfo', 'yes');

    % Remove noisy epochs
    threshold     = [-400 400]; % microvolts
    localSd       = 6;
    globalSd      = 3;
    [EEG,nReject] = run_removeNoisyEpochs(EEG, threshold, localSd, globalSd); 

    % Save text file of rejected trial indices (1 logical array combining
    % both steps)
    rejectedTrials = EEG.etc.run_removeNoisyEpochs.rejectedIdx;
    writematrix(rejectedTrials, [subjFolder filesep subject '_rejectedTrials.txt'])

    % save text files of indices for removed trials. One file for both
    % steps individually and one step for both steps combined
    firstRejString = sprintf('%.0f,' , EEG.etc.run_removeNoisyEpochs.firstRejIdx); % comma-separated string
    firstRejString = firstRejString(1:end-1); % drop last comma
    secondRejString = sprintf('%.0f,' , EEG.etc.run_removeNoisyEpochs.secondRejIdx); % comma-separated string
    secondRejString = secondRejString(1:end-1); % drop last comma
    asTwoSteps = ['Trial indices rejected at step 1 (pop_eegtresh): ' firstRejString newline ...
        'Trial indices rejected at step 2 (pop_jointprob): ' secondRejString];

    rejIdx = find(EEG.etc.run_removeNoisyEpochs.rejectedIdx);
    totalRejString = sprintf('%.0f,' , rejIdx); % comma-separated string
    totalRejString = totalRejString(1:end-1); % drop last comma
    asOneStep = ['Epochs rejected (pop_eegtresh followed by pop_jointprob): ' totalRejString];


    writematrix(asOneStep, [subjFolder filesep subject '_rejectedTrials_OneStep.txt'])
    writematrix(asTwoSteps, [subjFolder filesep subject '_rejectedTrials_TwoSteps.txt'])

    % Save epoched data - to be uploaded
    pop_saveset(EEG, ...
        'filename', [EEG.setname '_timeDomain'], ...
        'filepath', subjFolder);

    % obtain event indices - relevant for all hypotheses
    allEventTypes = {EEG.event.type}'; % place event types in separate cell array
    allEventTypes = cellfun(@num2str,allEventTypes,'UniformOutput',false); % convert elements to strings (for indexing)
    %% Hypothesis 1, scene category
    EEGoriginal = EEG;
    % Condition 1 is man-made, condition 2 is natural

    % Event indices
    cond1Hyp1Idx = startsWith(allEventTypes, '1');
    cond2Hyp1Idx = startsWith(allEventTypes, '2');

    disp(['subject ' subject])
    % Save new dataset with only the trials belonging to the two conditions
    cond1Hyp1 = EEG.data(:,:,cond1Hyp1Idx);
    cond2Hyp1 = EEG.data(:,:,cond2Hyp1Idx);
    EEG.data = cat(3,cond1Hyp1, cond2Hyp1);

    % Update EEG structure
    EEG.trials = size(EEG.data,3);
    t1 = EEG.event(cond1Hyp1Idx); % extract condition 1 events
    t2 = EEG.event(cond2Hyp1Idx); % extract condition 2 events
    EEG.event = t1; % Replace old event struct with condition 1 events
    EEG.event(length(EEG.event)+1:length(EEG.event)+length(t2)) = t2; % concatenate condition 2 to condition 1 events
    t3 = EEG.epoch(cond1Hyp1Idx); % extract condition 1 epochs
    t4 = EEG.epoch(cond2Hyp1Idx); % extract condition 2 epochs
    EEG.epoch = t3; % Replace old epoch struct with condition 1 epochs
    EEG.epoch(length(EEG.epoch)+1:length(EEG.epoch)+length(t4)) = t4; % concatenate condition 2 to condition 1 epochs

    % Save some documentation
    EEG.etc.epochingForTFA.hypothesis1.cond1NrOfEvents = size(cond1Hyp1,3);
    EEG.etc.epochingForTFA.hypothesis1.cond2NrOfEvents = size(cond2Hyp1,3);

    % Save epoched data
    EEG.setname = [EEG.setname '_hypothesis1'];
    EEG = pop_saveset(EEG, ...
        'filename', EEG.setname, ...
        'filepath', subjFolder);

    %% Hypothesis 2, image novelty
    % Condition 1 new (image shown for first time), condition 2 is old (shown before)
    EEG = EEGoriginal;
    % Event indices
    cond1Hyp2Idx = false(length(allEventTypes),1);
    cond2Hyp2Idx = false(length(allEventTypes),1);
    for i=1:length(cond1Hyp2Idx)
        if allEventTypes{i}(2) == '0'
            cond1Hyp2Idx(i) = true;
        elseif allEventTypes{i}(2) == '1'
            cond2Hyp2Idx(i) = true;
        else
            error('Something wrong with the events!')
        end
    end

    % Save new dataset with only the trials belonging to the two conditions
    cond1Hyp2 = EEG.data(:,:,cond1Hyp2Idx);
    cond2Hyp2 = EEG.data(:,:,cond2Hyp2Idx);
    EEG.data = cat(3,cond1Hyp2, cond2Hyp2);

    % Update EEG structure
    EEG.trials = size(EEG.data,3);
    t1 = EEG.event(cond1Hyp2Idx); % extract condition 1 events
    t2 = EEG.event(cond2Hyp2Idx); % extract condition 2 events
    EEG.event = t1; % Replace old event struct with condition 1 events
    EEG.event(length(EEG.event)+1:length(EEG.event)+length(t2)) = t2; % concatenate condition 2 to condition 1 events
    t3 = EEG.epoch(cond1Hyp2Idx); % extract condition 1 epochs
    t4 = EEG.epoch(cond2Hyp2Idx); % extract condition 2 epochs
    EEG.epoch = t3; % Replace old epoch struct with condition 1 epochs
    EEG.epoch(length(EEG.epoch)+1:length(EEG.epoch)+length(t4)) = t4; % concatenate condition 2 to condition 1 epochs

    % Save some documentation
    EEG.etc.epochingForTFA.hypothesis2.cond1NrOfEvents = size(cond1Hyp2,3); % 613
    EEG.etc.epochingForTFA.hypothesis2.cond2NrOfEvents = size(cond2Hyp2,3); % 587

    % Save epoched data
    EEG.setname = [EEG.setname '_hypothesis2'];
    EEG = pop_saveset(EEG, ...
        'filename', EEG.setname, ...
        'filepath', subjFolder);

    %% Hypothesis 3, successful recognition of old images
    % Condition 1 is hit (old image that was recognized as old), condition 2 is
    % miss (old image incorrectly judged as new)
    EEG = EEGoriginal;

    % Event indices
    cond1Hyp3Idx = false(length(allEventTypes),1);
    cond2Hyp3Idx = false(length(allEventTypes),1);
    for i=1:length(cond1Hyp3Idx)
        if allEventTypes{i}(3) == '1'
            cond1Hyp3Idx(i) = true;
        elseif allEventTypes{i}(3) == '2'
            cond2Hyp3Idx(i) = true;
        end
    end

    % Save new dataset with only the trials belonging to the two conditions
    cond1Hyp3 = EEG.data(:,:,cond1Hyp3Idx);
    cond2Hyp3 = EEG.data(:,:,cond2Hyp3Idx);
    EEG.data = cat(3,cond1Hyp3, cond2Hyp3);

    % Update EEG structure
    EEG.trials = size(EEG.data,3);
    t1 = EEG.event(cond1Hyp3Idx); % extract condition 1 events
    t2 = EEG.event(cond2Hyp3Idx); % extract condition 2 events
    EEG.event = t1; % Replace old event struct with condition 1 events
    EEG.event(length(EEG.event)+1:length(EEG.event)+length(t2)) = t2; % concatenate condition 2 to condition 1 events
    t3 = EEG.epoch(cond1Hyp3Idx); % extract condition 1 epochs
    t4 = EEG.epoch(cond2Hyp3Idx); % extract condition 2 epochs
    EEG.epoch = t3; % Replace old epoch struct with condition 1 epochs
    EEG.epoch(length(EEG.epoch)+1:length(EEG.epoch)+length(t4)) = t4; % concatenate condition 2 to condition 1 epochs

    % Save some documentation
    EEG.etc.epochingForTFA.hypothesis3.cond1NrOfEvents = size(cond1Hyp3,3); % uneven
    EEG.etc.epochingForTFA.hypothesis3.cond2NrOfEvents = size(cond2Hyp3,3);

    % Save epoched data
    EEG.setname = [EEG.setname '_hypothesis3'];
    EEG = pop_saveset(EEG, ...
        'filename', EEG.setname, ...
        'filepath', subjFolder);

    %% Hypothesis 4, subsequent memory
    % "Note that subsequent memory is not defined for trials with images that were not shown
    % another time, i.e. for images that had already been repeated or for trials at the very end of the
    % experiment."
    
    % condition 1 is subsequently remembered (repeated image was correctly
    % recognized as old), condition 2 (coded as 0, not 2 as documentation suggests) is subsequently forgotten (repeated image was incorrectly judged as new).
    EEG = EEGoriginal;
    % Event indices
    cond1Hyp4Idx = false(length(allEventTypes),1);
    cond2Hyp4Idx = false(length(allEventTypes),1);
    for i=1:length(cond1Hyp4Idx)
        if allEventTypes{i}(4) == '1'
            cond1Hyp4Idx(i) = true;
        elseif allEventTypes{i}(4) == '0'
            cond2Hyp4Idx(i) = true;
        end
    end

    % Save new dataset with only the trials belonging to the two conditions
    cond1Hyp4 = EEG.data(:,:,cond1Hyp4Idx);
    cond2Hyp4 = EEG.data(:,:,cond2Hyp4Idx);
    EEG.data = cat(3,cond1Hyp4, cond2Hyp4);

    % Update EEG structure
    EEG.trials = size(EEG.data,3);
    t1 = EEG.event(cond1Hyp4Idx); % extract condition 1 events
    t2 = EEG.event(cond2Hyp4Idx); % extract condition 2 events
    EEG.event = t1; % Replace old event struct with condition 1 events
    EEG.event(length(EEG.event)+1:length(EEG.event)+length(t2)) = t2; % concatenate condition 2 to condition 1 events
    t3 = EEG.epoch(cond1Hyp4Idx); % extract condition 1 epochs
    t4 = EEG.epoch(cond2Hyp4Idx); % extract condition 2 epochs
    EEG.epoch = t3; % Replace old epoch struct with condition 1 epochs
    EEG.epoch(length(EEG.epoch)+1:length(EEG.epoch)+length(t4)) = t4; % concatenate condition 2 to condition 1 epochs

    % Save some documentation
    EEG.etc.epochingForTFA.hypothesis4.cond1NrOfEvents = size(cond1Hyp4,3); % uneven
    EEG.etc.epochingForTFA.hypothesis4.cond2NrOfEvents = size(cond2Hyp4,3); 
    % Exactly the same number of events as for hypothesis 3, but they are not
    % the same. I checked.

    % Save epoched data
    EEG.setname = [EEG.setname '_hypothesis4'];
    EEG = pop_saveset(EEG, ...
        'filename', EEG.setname, ...
        'filepath', subjFolder);

end % end subject loop
fprintf('\n\n\n**** epochingForTFA finished ****\n\n\n');
