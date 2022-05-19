function EEG = run_cleanRawChanRemoval(EEG, highPass, generateFigures)
% EEG = run_cleanRawChanRemoval(EEG, highPass, generateFigures)
% High-pass filters (detrends) continuous EEG data at 1 Hz, runs
% clean_artifacts to identify bad channels, and then manually removes those
% channels from the initial, unfiltered data.
%
%
%  Parameters:
%      EEG                 (input/output) EEG structure.
%      highPass             Logical. Whether to high-pass filter at 1 Hz
%                           using EEGLAB default (pop_eegfiltnew).
%      generateFigures      Logical. Runs vis_artifacts to produce a figure
%                           displaying the rejected channels.
%
%
% Adapted from
% https://github.com/sccn/clean_rawdata/blob/master/clean_artifacts.m.


%% Apply 1 Hz high-pass filter to adress data nonstationarity
originalChanlocs = EEG.chanlocs; % Save for interpolation
if highPass
    highPassFrequency = 1;
    EEGfilt = pop_eegfiltnew(EEG, 'locutoff', highPassFrequency, 'plotfreqz', 0);
else
    EEGfilt = EEG;
end

%% Run clean_artifacts to remove bad channels (slightly tuned from default)
EEGclean = clean_artifacts(EEGfilt, 'FlatlineCriterion', 5, ...
    'ChannelCriterion', 0.80, ... % default is 0.85
    'LineNoiseCriterion', 5, ... % default is 4
    'Highpass', 'off', ...
    'BurstCriterion', 'off', ...
    'WindowCriterion', 'off', ...
    'BurstRejection', 'off', ...
    'Distance', 'Euclidian', ...
    'WindowCriterionTolerances','off');
%% Generate figure
if generateFigures
    figure;
    vis_artifacts(EEGclean, EEG);
end

% Find removed channels
rmChanIdx  = find(~ismember({EEG.chanlocs.labels},{EEGclean.chanlocs.labels}));
chansToRem = {EEG.chanlocs(rmChanIdx).labels};

% Update EEG.etc for documentation
EEG.etc.clean_channel_mask = EEGclean.etc.clean_channel_mask;
EEG.etc.run_cleanRawChanRemoval.originalChanlocs = originalChanlocs;
EEG.etc.run_cleanRawChanRemoval.removedChannels = chansToRem;

% Remove the bad channels from unfiltered data
if ~isempty(rmChanIdx)
    EEG = pop_select(EEG, 'nochannel', chansToRem);
end

% If mastoids have too much noise we should probably exclude that subject
% alltogether, since we will use LM as reference? Mark for rejection in
% that case?