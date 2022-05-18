function EEG = run_removeLineNoise(EEG, lineNoiseFreq, generateFigures, lineNoiseChans)
% EEG = run_removeLineNoise(EEG, lineNoiseFreq, generateFigures, lineNoiseChans)
% High-pass filters (detrends) continuous EEG data at 1 Hz, runs cleanLineNoise, and subtracts
% the line noise estimate from the initial, unfiltered EEG data. 
%
%
%  Parameters:
%      EEG                 (input/output) EEG structure
%      lineNoiseFreq        Scalar. The line noise frequency (e.g. 50 Hz)
%      generateFigures      Logical. Produce topoplots of data before and
%                           after line noise removal.
%      lineNoiseChans       1D vector of channels for line noise removal. E.g. 1:70
%
%
% Adapted from https://github.com/VisLab/EEG-Clean-Tools
% See also https://doi.org/10.3389/fninf.2015.00016.

EEG.data = double(EEG.data);   % double precision
EEGold = EEG;
% Apply 1 Hz high-pass filter
highPassFrequency = 1;
EEGfilt = pop_eegfiltnew(EEG, 'locutoff', highPassFrequency, 'plotfreqz', 0);

% Run CleanLineNoise (from the PREP pipeline) to remove line noise
%lineNoiseFreq = 50; % 50 Hz linenoise (EU)
% set parameters
lineNoiseIn = struct('lineNoiseMethod', 'clean', ...
    'lineNoiseChannels', lineNoiseChans,...
    'Fs', EEG.srate, ...
    'lineFrequencies', lineNoiseFreq:lineNoiseFreq:EEG.srate/2,...
    'p', 0.01, ... % p-value threshold for the Thompson F-test
    'fScanBandWidth', 2, ...
    'taperBandWidth', 2, ... % bandwidth of the tapers (in Hz)
    'taperWindowSize', 4, ... % size of windows where tapers are applied (in sec)
    'taperWindowStep', 1, ... % sec window-step size
    'tau', 100, ... % Smoothing parameter for sigmoidal weighted average
    'pad', 2, ...
    'fPassBand', [0 EEG.srate/2], ...
    'maximumIterations', 10);
[EEGclean, lineNoiseOut] = cleanLineNoise(EEGfilt, lineNoiseIn);

% save documentation in EEG.etc
EEG.etc.noiseDetection.lineNoise = lineNoiseOut;

% The high-pass FIR filter and CleanLineNoise are both linear, see
% https://sccn.ucsd.edu/pipermail/eeglablist/2016/011631.html
% old - HP filtered + (HP filtered + clean) = old + clean
lineChannels = lineNoiseIn.lineNoiseChannels;
EEG.data(lineChannels, :) = EEGold.data(lineChannels, :) ...
    - EEGfilt.data(lineChannels, :) + EEGclean.data(lineChannels, :);


%% Generate figures
if generateFigures
    figure;
    subplot(2,1,1)
    pop_spectopo(EEGold, 1, [EEGold.xmin EEGold.xmax], 'EEG', ...
        'percent', 100, ...
        'freqrange', [0.5 80], ...
        'title', 'Before line noise removal');
    subplot(2,1,2)
    pop_spectopo(EEG, 1, [EEG.xmin EEG.xmax], 'EEG', ...
        'percent', 100, ...
        'freqrange', [0.5 80], ...
        'title', 'After line noise removal');
end

% publishPrepReport(EEG, 'vepSummary.html', '.\s1\vep01.pdf', 1, true);