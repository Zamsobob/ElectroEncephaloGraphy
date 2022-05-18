function [EEG, nReject] = run_removeNoisyEpochs(varargin)
% EEG = run_epochRemoval(EEG, threshold, localSd, globalSd)
% Performs two-stage rejection of noisy event-related data epochs by
% first using pop_eegthresh to reject epochs with amplitude values exceeding a two-sided
% threshold [default: +-400 \muV]. Then, applies an improbability test with
% local (single channels, default 6SD) and global (all channels, default 3SD) thresholds using
% EEGLAB's pop_jointprob function.
%
% INPUTS:
%
% EEG               EEG structure
% threshold         amplitude tresholds in microvolts (\muV), specified as
%                   [min max]. Example: [-400 400]
% localSd           Single-channel (local) standard deviation threshold for
%                   improbability test. Default: 6
% globalSd          All-channels (global) standard deviation threshold for
%                   improbability test. Default: 3
% 
%
% OUTPUTS:
% EEG:              Data with noisy epochs removed and documentation saved
%                   in EEG.etc.run_removeNoisyEpochs. Also produces a csv
%                   file containing indices of the removed epochs.
% nReject           Number of rejected epochs (in total)
%

% Get input arguments
if nargin < 1
    error('Need at least EEG struct as input!')
elseif nargin < 2
    % Defaults
    threshold = [-400 400];
    localSd   = 6;
    globalSd  = 3;
elseif nargin < 3
    threshold = varargin{2};
    localSd   = 6;
    globalSd  = 3;
elseif nargin < 4
    threshold = varargin{2};
    localSd   = varargin{3};
    globalSd  = 3;
elseif nargin < 5
    threshold = varargin{2};
    localSd   = varargin{3};
    globalSd  = varargin{4};
else
    threshold = varargin{2};
    localSd   = varargin{3};
    globalSd  = varargin{4};
end
EEG = varargin{1};
EEG.etc.run_removeNoisyEpochs.nr_trials_before = EEG.trials;

% Reject bad epochs based on amplitude threshold
[EEG, rejidx] = pop_eegthresh(EEG, 1, 1:EEG.nbchan, threshold(1), threshold(2), EEG.xmin, EEG.xmax, 0, 1); % final 1 rejects instead of store
[rej_trials,firstRej] = deal(EEG.reject.rejthresh); % indices reject epochs

% Apply improbability test and reject again
[EEG, ~, ~, nrej] = pop_jointprob(EEG, 1, 1:EEG.nbchan, localSd, globalSd, 1, 1);

% Create logical matrix, representing the indices of all removed trials
% (from both methods)
count = 0;
for i = 1:length(rej_trials)
    if rej_trials(i) == 0
        rej_trials(i) = EEG.reject.rejjp(i-count);
    else
        count = count + 1;
    end
end
nReject = sum(rej_trials);

% Subtract the trials that were removed in the first step from the
% "combined step" to get the removed trials during step 2.
secondRej = rej_trials;
secondRej(rej_trials & firstRej) = 0;
secidx = find(secondRej); % indices of the second removal, now with the same length as before first removal (i.e. if trial 1 was removed during step 1,
% and trial 2 then becomes the new trial 1, and trial 1 is again removed in
% step 2 (original trial 2), then it now shows as step 2 removing trial 2).

% "Please report the trial indices relative to all trials (i.e., not separated by conditions) and 
% retain  consistent  trial  indices  across  preprocessing  steps.  For  example,  if  you  reject 
% trial 1 at an early step, the index of trial 2 should remain 2 (and not get updated to 1)."

% So, if step 1 removes trial 1 and step 2 also removes trial 1 (which was
% the original trial 2), it will now say trial 2 was removed during step 2.

% Save documentation
EEG.etc.run_removeNoisyEpochs.nr_removed_trials_eegtresh = length(rejidx); % nr of trials removed with threshold
EEG.etc.run_removeNoisyEpochs.nr_removed_trials_jointprob = nrej; % nr of trials removed with improbability test
EEG.etc.run_removeNoisyEpochs.nr_removed_trials_total = nReject; % nr of trials removed total
EEG.etc.run_removeNoisyEpochs.percentage_removed_trials = (nReject / EEG.etc.run_removeNoisyEpochs.nr_trials_before)*100; % percentage removed
EEG.etc.run_removeNoisyEpochs.rejectedIdx = rej_trials;
EEG.etc.run_removeNoisyEpochs.firstRejIdx = rejidx;
EEG.etc.run_removeNoisyEpochs.secondRejIdx = secidx;
