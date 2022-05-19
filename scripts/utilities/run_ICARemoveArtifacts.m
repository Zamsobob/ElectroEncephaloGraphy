function EEG = run_ICARemoveArtifacts(EEG, icaChans, deleteTimeSegments)
% EEG = run_ICARemoveArtifacts(EEG, icaChans, deleteTimeSegments)
% High-pass filters continuous EEG data at 1 Hz, removes non-stimulus time segments,
% and downsamples to 128 Hz, before running pop_runICA.
%
%
%  Parameters:
%      EEG                (input/output) EEG structure
%      icaChans            Vector of channel indices ('chanind') for
%                          pop_runICA. Example: 1:EEG.nbchan.
%      highPass            Logical. Whether to high-pass filter at 1 Hz
%                          using EEGLAB default (pop_eegfiltnew) or not.
%      deleteTimeSegments  Logical. Whether to run pop_erplabDeleteTimeSegments
%                          from the ERPLAB toolbox to remove segments of EEG
%                          during the break periods in between trial blocks
%                          (defined as 5 seconds or longer in between successive
%                          stimulus event codes). Based on https://osf.io/n6rtk/.
%

%% Part I. HP filter at 1 Hz and downsample to 128 Hz
% EEG_forICA = filterAndResample(EEG, 1, 128);
% Set parameters
filtType = 'FIR'; % Linear EEGLAB or nonlinear ERPLAB filter
highPassFrequency = 1; % Passband edge for FIR, cutoff frequency (-6dB) for IIR
removeDC = false; % Subtract channel mean
maxSamplingRate = 128; % Resample
EEG_forICA = detrendAndResample(EEG, filtType, highPassFrequency, removeDC, maxSamplingRate);
% For the rationale behind downsampling, see
% https://sccn.ucsd.edu/wiki/Makoto%27s_useful_EEGLAB_code#How_to_avoid_the_effect_of_rank-deficiency_in_applying_ICA_.2803.2F31.2F2021_added.29

%% Part II. Remove segments of EEG during the break periods in between trial blocks
% Defined as 5 seconds or longer in between successive stimulus event
% codes. Based on https://osf.io/n6rtk/ and is implementedt to improve ICA
% decomposition.
if deleteTimeSegments == 1
    EEG_forICA = pop_erplabDeleteTimeSegments(EEG_forICA, ...
        'timeThresholdMS'       , 5000,     ...
        'beforeEventcodeBufferMS', 100,      ...
        'afterEventcodeBufferMS'  , 200,      ...
        'ignoreUseEventcodes'   , [],       ...
        'ignoreUseType'         , 'ignore', ...
        'ignoreBoundary', 0, ...
        'displayEEG', false);
end

%% Part III. Run ICA and apply the results to the initial, unfiltered dataset
EEG.etc.run_ICARemoveArtifacts = []; % initialize EEG.etc for documentation
numDataPoints = numel(EEG.data(icaChans,:)); % 2D data
% Check rank of data
dataRank = sum(eig(cov(double(EEG_forICA.data(icaChans,:)'))) > 1E-7);

% Run ICA. Use PCA option if rank deficient
if dataRank == length(icaChans)
    tic
    EEG_forICA = pop_runica(EEG_forICA, ...
        'extended',1, ...
        'interupt','off', ...
        'chanind', icaChans);
    EEG.etc.run_ICARemoveArtifacts.elapsedTime = toc;
    EEG.etc.run_ICARemoveArtifacts.dataRankEqualToChanRank = true;
elseif dataRank < length(icaChans)
    tic
    EEG_forICA = pop_runica(EEG_forICA, ...
        'extended',1, ...
        'interupt','off', ...
        'pca', dataRank, ...
        'chanind', icaChans);
    EEG.etc.run_ICARemoveArtifacts.elapsedTime = toc;
    EEG.etc.run_ICARemoveArtifacts.dataRankEqualToChanRank = false;
else
    error("Something has gone horribly wrong! Data rank > nr of channels!")
    EEG.etc.run_ICARemoveArtifacts.dataRankEqualToChanRank = false;
end

% Apply the results of ICA to the initial, unfiltered EEG data
EEG.icaact      = EEG_forICA.icaact;
EEG.icawinv     = EEG_forICA.icawinv;
EEG.icasphere   = EEG_forICA.icasphere;
EEG.icaweights  = EEG_forICA.icaweights;
EEG.icachansind = EEG_forICA.icachansind;

% Update EEG.etc for documentation
EEG.etc.run_ICARemoveArtifacts.dataRank = dataRank;
EEG.etc.run_ICARemoveArtifacts.ratioDataPointsToChanSquared = numDataPoints / length(icaChans)^2; % This should ideally be at least 30
