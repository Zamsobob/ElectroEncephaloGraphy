function EEG = detrendAndResample(EEG, filtType, highPassFrequency, removeDC, maxSamplingRate)
% Removes channel mean, high-pass filters, and resamples continuous EEG data.
%
%
%  Parameters:
%      EEG                 (input/output) continuous EEG to be filtered (only has EEG channels)
%      filtType            String specifying the type of high-pass filter. Either 'FIR' for
%                          EEGLAB's FIR filter (pop_eegfiltnew) or 'IIR'
%                          for ERPLAB's IIR Butterworth filter (pop_basicfilter)
%      highPassFrequency   High pass filter at this frequency if non empty.
%                          For 'FIR', specify the passband edge (as in EEGLAB). For 'IIR',
%                          specify the half-amplitude (-6 dB) cutoff frequency (as in ERPLAB).
%      removeDC            Logical. Whether or not to remove remove mean
%                          value (DC offset) before filtering. Recommended for this dataset
%      maxSamplingRate     Resample if non-empty and lower than EEG.srate
%
%
% Adapted from https://github.com/VisLab/EEG-Pipelines/blob/master/utilities/filterAndResample.m
%% Remove channel mean
EEG.data = double(EEG.data);
chanMean = mean(EEG.data, 2);
if removeDC
    EEG.data = bsxfun(@minus, EEG.data, chanMean);
end

%% High pass filter
if ~isempty(highPassFrequency) && ~isempty(filtType)
    if strcmpi(filtType, 'FIR')
        EEG = pop_eegfiltnew(EEG, 'locutoff', highPassFrequency, 'plotfreqz', 0);
    elseif strcmpi(filtType, 'IIR')
        EEG  = pop_basicfilter(EEG,  1:EEG.nbchan , ...
            'Boundary', 'boundary', ...
            'Cutoff',  highPassFrequency, ...
            'Design', 'butter', ...
            'Filter', 'highpass', ...
            'Order',  2, ...
            'RemoveDC', 'off');
    end
end
%% Resample if necessary
if ~isempty(maxSamplingRate) && EEG.srate > maxSamplingRate
    EEG = pop_resample(EEG, maxSamplingRate);
end

% save documentation in EEG.etc
EEG.etc.detrendAndResample.maxSamplingRate   = maxSamplingRate;
EEG.etc.detrendAndResample.filterType        = [filtType '_highpass'];
EEG.etc.detrendAndResample.highPassFrequency = highPassFrequency;
EEG.etc.detrendAndResample.removeDC          = removeDC;
EEG.etc.detrendAndResample.chanMeanBefore    = chanMean;
EEG.etc.detrendAndResample.chanMeanAfter     = mean(EEG.data, 2);