function EEG = filterAndResample(EEG, highPassFrequency, maxSamplingRate)
% Removes channel mean, high-pass filters, and resamples continuous EEG
% data.
%
%  Parameters:
%      EEG    (input/output) continuous EEG to be filtered (only has EEG channels)
%      highPassFrequency   high pass filter at this frequency if non empty
%      maxSamplingRate     resample if non-empty and lower than EEG.srate
% 
%
% Adapted from https://github.com/VisLab/EEG-Pipelines/blob/master/utilities/filterAndResample.m
%% Remove channel mean  
EEG.data = double(EEG.data);
EEG.data = bsxfun(@minus, EEG.data, mean(EEG.data, 2));

%% High pass filter
if ~isempty(highPassFrequency)
    EEG = pop_eegfiltnew(EEG, 'locutoff', highPassFrequency, 'plotfreqz', 0);
end
%% Resample if necessary
if ~isempty(maxSamplingRate) && EEG.srate > maxSamplingRate
    EEG = pop_resample(EEG, maxSamplingRate);
end

% save documentation in EEG.etc
EEG.etc.filterAndResample.maxSamplingRate = maxSamplingRate;
EEG.etc.filterAndResample.filterType = 'highpass';
EEG.etc.filterAndResample.highPassFrequency = highPassFrequency;