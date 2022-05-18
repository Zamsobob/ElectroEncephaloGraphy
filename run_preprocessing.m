%% Preprocessing
%
% See the end of the script for a rough outline of what was done
%
% Note: Many individual functions can be found in the folder called 'utilities'
%% Initial setup

% Set saveEverything variable to 1 to save intermediate steps. Set to 0 to
% save only the necessary files. 
saveEverything = 0;

% Setup project path (github main branch) and add the utilities folder to path
projectPath = pwd; % Main branch
utilitiesPath = dir(fullfile(projectPath,'**','utilities'));
addpath(utilitiesPath(1).folder)

% Create subject folders (if they do not exist) and save the paths to those folders
lists.subjFolderPaths = setupSubjectFolders(projectPath);

% If saveEverything was set to 1, creates additional preprocessing folder
% structure inside the subject folders, and saves the paths to those
% folders
if saveEverything
    for i = 1:length(lists.subjFolderPaths)
    lists.pathList = createAdditionalFolders(lists.subjFolderPaths(i).subjFolderPaths);
    end
cd(projectPath);
end

% Create a list of subjects to loop through. Also returns the path to the raw
% data and the file extension (raw data needs to be inside projectPath)
[lists.subjectList, fileExt, rawDataPath] = createSubjectList(projectPath);

% Initialize quality metrics struct
QualityMetrics = struct('subject','', ...
    'numICsRemoved',[], ...
    'idxICsRemoved',[], ...
    'numRemovedChans', [], ...
    'removedChansLabels',{});

% Initialize EEGLAB structure
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
close all;
% EEGLAB options: use double precision, keep at most one dataset in memory
pop_editoptions('option_single', 0, ...
    'option_storedisk', 1);
%% Perform preprocessing iteratively
for sub = 1:length(lists.subjectList)
    %% Load current subject
    subject    = lists.subjectList{sub};
    subject    = extractBefore(subject, fileExt);
    subjFolder = lists.subjFolderPaths(sub).subjFolderPaths;

    fprintf('Processing subject %d: %s\n', sub, subject);

    % Load current dataset
    EEG = pop_loadset('filename',lists.subjectList{sub}, ...
        'filepath', rawDataPath);

    % Remove VEOG and HEOG channels
    EEG = pop_select(EEG, 'nochannel',{'VEOG','HEOG'});

    %% Step I. Remove channel mean, high-pass filter, and resample to 256 Hz
    % Set parameters
    filtType = 'FIR'; % Linear EEGLAB or nonlinear ERPLAB filter
    highPassFrequency = 0.2; % Passband edge for FIR (cutoff = 0.1 Hz), cutoff frequency (-6dB) for IIR
    removeDC = true; % Subtract channel mean
    maxSamplingRate = 256; % Resample
    EEG = detrendAndResample(EEG, filtType, highPassFrequency, removeDC, maxSamplingRate);

    % Save intermediate step
    if saveEverything
        EEG.setname = lists.pathList(1).preprocessingStep;
        EEG = pop_saveset(EEG, 'filename',EEG.setname, ...
            'filepath', [subjFolder filesep EEG.setname]);
    end

    %% Step II. Rereference to average of left and right mastoids (LM RM)
    rerefTo = [69 70];
    EEG = pop_reref(EEG, rerefTo);

    % Save intermediate step
    if saveEverything
        EEG.setname = lists.pathList(2).preprocessingStep;
        EEG = pop_saveset(EEG, 'filename',EEG.setname, ...
            'filepath', [subjFolder filesep EEG.setname]);
    end


    %% Step III. Remove line noise with CleanLineNoise (from PREP pipeline)
    % Set parameters
    lineNoiseFreq = 50; % Hz
    generateFigures = false;
    lineNoiseChans = 1:EEG.nbchan; % channels with coordinates
    EEG = run_removeLineNoise(EEG, lineNoiseFreq, generateFigures, lineNoiseChans);

    % Save intermediate step
    if saveEverything
        EEG.setname = lists.pathList(3).preprocessingStep;
        EEG = pop_saveset(EEG, 'filename',EEG.setname, ...
            'filepath', [subjFolder filesep EEG.setname]);
    end

    %% Step IV. Detect and remove bad channels with the clean_rawdata EEGLAB plugin
    % set parameters
    highPass = true;
    generateFigures = false;
    EEG = run_cleanRawChanRemoval(EEG, highPass, generateFigures);
    
    % Save intermediate step
    if saveEverything
        EEG.setname = lists.pathList(4).preprocessingStep;
        EEG = pop_saveset(EEG, 'filename',EEG.setname, ...
            'filepath', [subjFolder filesep EEG.setname]);
    end

    removedChans = EEG.etc.run_cleanRawChanRemoval.removedChannels; % labels removed chans
    writecell(removedChans, [subjFolder filesep subject '_removedChannels.txt'])

    %% Step V. Run ICA for artifact removal
    % The function below high-pass filters the data at 1 Hz, downsamples to
    % 128 Hz (to increase speed), removes time segments between trial
    % blocks, and runs ICA. The ICA weights are then transfered to the
    % initial dataset (EEG).

    icaChans = 1:EEG.nbchan;
    deleteTimeSegments = true;
    EEG = run_ICARemoveArtifacts(EEG, icaChans, deleteTimeSegments);
    EEG = eeg_checkset(EEG, 'ica');


    % Extract mixing and unmixing matrices (project specific)
    % Unmixing matrix (A) * Data (X) = Source activity (S)
    % Mixing matrix (W) * Source activity (S) = Data (X)
    % https://benediktehinger.de/blog/science/ica-weights-and-invweights/
    X = EEG.data; % data matrix
    A = EEG.icaweights * EEG.icasphere; % unmixing matrix A (whitened, aka weight matrix)
    W = pinv(A); % mixing matrix (aka inverse weight matrix). W = A^(-1). Equal to EEG.icawinv
    S = A * X; % source activity - activation matrix. Equal to EEG.icaact)
    writematrix(A,[subjFolder filesep subject '_ICAunmixing.txt']) % save in subject folder
    writematrix(W,[subjFolder filesep subject '_ICAmixing.txt']) % save in subject folder


    % Run ICLabel to label and flag independent components
    % classified as eye and muscle artifacts (with >= 80% probability)
    EEG = pop_iclabel(EEG, 'default'); % Label
    EEG = pop_icflag(EEG, [NaN NaN;0.8 1;0.8 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]); % Flag

    % Save intermediate step
    if saveEverything
        EEG.setname = lists.pathList(5).preprocessingStep;
        EEG = pop_saveset(EEG, 'filename',EEG.setname, ...
            'filepath', [subjFolder filesep EEG.setname]);
    end

    %%  Step VI. Remove independent components classified as artifacts
    flaggedComponents = find(EEG.reject.gcompreject == 1); % Flagged components
    EEG = pop_subcomp(EEG, flaggedComponents, 0); % Remove flagged components

    % Save intermediate step
    if saveEverything
        EEG.setname = lists.pathList(6).preprocessingStep;
        EEG = pop_saveset(EEG, 'filename',EEG.setname, ...
            'filepath', [subjFolder filesep EEG.setname]);
    end

    %% Final step. Interpolation

    % Interpolate channels (spherical splines) using original channel locations
    originalChanlocs = EEG.etc.run_cleanRawChanRemoval.originalChanlocs;
    EEG = pop_interp(EEG, originalChanlocs, 'spherical');
    
    % Save preprocessed data
    EEG.setname = [subject '_preprocessed'];
    EEG = pop_saveset(EEG, ...
        'filename',EEG.setname, ...
        'filepath', subjFolder);

    %% Store some basic quality metrics information for manual review
    QualityMetrics(sub).subject = subject;
    QualityMetrics(sub).numICsRemoved = length(flaggedComponents);
    QualityMetrics(sub).idxICsRemoved = flaggedComponents';
    QualityMetrics(sub).numRemovedChans = length(EEG.etc.run_cleanRawChanRemoval.removedChannels);
    QualityMetrics(sub).removedChansLabels = EEG.etc.run_cleanRawChanRemoval.removedChannels;

end

save('QualityMetrics.mat', 'QualityMetrics', '-v7.3');
fprintf('\n\n\n**** Preprocessing finished ****\n\n\n');

% Save rejected independent components to file
for j = 1:length(lists.subjectList)
    icIdx = QualityMetrics(j).idxICsRemoved;
    writematrix(icIdx, [lists.subjFolderPaths(j).subjFolderPaths filesep extractBefore(lists.subjectList{j}, fileExt) '_rejectedICs.txt'])
end


%% Methods description (rough outline)
%% Preprocessing

% Offline processing of the EEG data was conducted using functions from the EEGLAB toolbox
% (version 2021.1; Delorme & Makeig, 2004), as implemented in MATLAB R2022a (MATLAB, 2022).
%
% To suppress slow voltage drifts and DC offsets caused by, for example, the EEG electrodes, skin hydration, and
% skin potentials, the mean amplitude was subtracted from each channel, and data were high-pass filtered using
% EEGLAB's eegfiltnew function (passband edge: 0.2 Hz, frequency cutoff (-6 dB): 0.1 Hz, transition bandwidth:
% 0.2 Hz, filter order: 8448). The relatively low cutoff frequency was chosen to minimize filter distortions while
% simultaneously increasing the signal-to-noise ratio (Luck, 2014). Data were subsequently downsampled to 256 Hz
% to increase processing speed and re-referenced to the average of the left and right mastoid channels (M1 and M2).
%
% To remove 50 Hz line noise (with harmonics that are multiples of 50 up to the Nyquist frequency), we used the
% CleaLlineNoise function from the early-stage EEG processing pipeline (PREP; Bigdely-Shamlo et al., 2015), which is
% based on the EEGLAB plugin cleanline (Mullen, 2012) using default parameters. To improve the performance of the
% algorithm, a temporary high-pass filter (1 Hz passband edge, default settings) was additionally applied prior to
% cleanLineNoise (Bigdely-Shamlo et al., 2015). In addition, a temporary high-pass filter (1 Hz passband edge,
% default settings) was applied prior to cleanLineNoise to improve performance (Bigdely-Shamlo et al., 2015).
%
% Next, electrodes that were either flat, exhibited high noise, or were poorly correlated with neighbouring channels
% were removed using the EEGLAB plugin clean_rawdata. The parameters were slightly tuned from the default settings to
% avoid excessive removal of electrodes (see run_cleanRawChanRemoval.m for exact parameters used).
%
% Next, the extended version of the Infomax Independent Component Analysis (ICA; Jung et al., 2000; Makeig et al.,
% 1996) algorithm implemented in EEGLAB (Delorme & Makeig, 2004) was utilized to correct for muscular and ocular
% artefacts. To improve ICA decomposition, time segments between trials blocks (defined as 5 seconds or longer in
% between successive events) were removed, and a high-pass filter (1 Hz passband edge, default settings) was applied
% to the data (Klug & Gramann, 2020; Winkler et al., 2015). Independent components exceeding an 80 percent probability of
% being muscular or ocular artefacts were marked and removed from the original data (prior to segmentation and
% filtering) using the automatic independent component classifier IClabel (Pion-Tonachini et al., 2019). After ICA,
% previously removed channels were interpolated (default EEGLAB spherical spline interpolation).
