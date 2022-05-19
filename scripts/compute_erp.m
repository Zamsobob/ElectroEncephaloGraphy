% ERP manually

% Hyp 3 and 4 notes





%% Different time-domain plots

% Setup project path (github main branch) and add the utilities folder to path
projectPath = pwd; % Main branch
utilitiesPath = dir(fullfile(projectPath,'**','utilities'));
addpath(utilitiesPath(1).folder)

% Create subject folders in the preprocessing folder (if they do not exist)
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

allData(length(lists.subjectList)).subject = [];
allData(length(lists.subjectList)).cond1   = [];
allData(length(lists.subjectList)).cond2   = [];
%% Load all subjects
% loop over hypotheses 3, and 4
% loop over subjects
for sub = 1:length(lists.subjectList)

    % Find files to load
    subject    = lists.subjectList{sub};
    subject    = extractBefore(subject, fileExt);
    fileName   = [subject '_preprocessed_hypothesis3.set'];
    subjFolder = lists.subjFolderPaths(sub).subjFolderPaths;

    % Load current dataset
    EEG = pop_loadset('filename',fileName, ...
        'filepath', subjFolder);

    % Condition indices - generated from epoching script
    nCond1   = EEG.etc.epochingForTFA.hypothesis3.cond1NrOfEvents; % hit
    nCond2   = EEG.etc.epochingForTFA.hypothesis3.cond2NrOfEvents; % miss
    cond1Idx = 1:nCond1;
    cond2Idx = length(cond1Idx)+1:EEG.trials;

    % Remove baseline (-200 to 0 ms)
    EEG = pop_rmbase(EEG, [-200 0]);

    % store subject data
    allData(sub).subject = subject;
    allData(sub).cond1   = EEG.data(:,:,cond1Idx);
    allData(sub).cond2   = EEG.data(:,:,cond2Idx);

end

%% Hypothesis 3, successful recognition of old images
% Condition 1 is hit (old image that was recognized as old), condition 2 is
% miss (old image incorrectly judged as new)


% ERP stuffs

chan2plot = 9;
subj2plot = 33;
hypothesis = 3;

%% Plot 1 channel ERP - expand to multiple subjects
figure(1)
subplot(211)
plot(EEG.times,squeeze(mean(allData(subj2plot).cond1(chan2plot,:,:),3)),'k','linew',2)
set(gca,'xlim',[-200 1200])
title('ERP hit')

subplot(212)
plot(EEG.times,squeeze(mean(allData(subj2plot).cond2(chan2plot,:,:),3)),'k','linew',2)
set(gca,'xlim',[-200 1200])
title('ERP miss')
sgtitle(['ERP for channel ' num2str(chan2plot) ' subject ' num2str(subj2plot)])


%% Plot single trials (ERP image) + average (ERP)
figure(2), clf
subplot(6,1,1:2)
imagesc(EEG.times, [], squeeze(EEG.data(chan2plot,:,cond1Idx))') % trial x time points (indices, 1 chan)
set(gca,'clim',[-1 1]*10,'xlim',[-200 800])
ylabel('Trial')
hold on
plot([0 0],get(gca,'ylim'),'k--','linew',3)
title('Hits all trials: ERP image')
colorbar;
colormap jet

subplot(6,1,3)
plot(EEG.times,squeeze(mean(EEG.data(chan2plot,:,cond1Idx),3)),'k','linew',3)
xlabel('Time (s)')
ylabel('Voltage (\muV)')
set(gca,'ylim',[-10 10],'xlim',[-200 800])
hold on
plot([0 0],get(gca,'ylim'),'k--','linew',3)
title('Average over trials')
grid on

subplot(6,1,4:5)
imagesc(EEG.times, [], squeeze(EEG.data(chan2plot,:,cond2Idx))') % trial x time points (indices, 1 chan)
set(gca,'clim',[-1 1]*10,'xlim',[-200 800])
ylabel('Trial')
hold on
plot([0 0],get(gca,'ylim'),'k--','linew',3)
title('Miss all trials: ERP image')
colorbar;
colormap jet

subplot(6,1,6)
plot(EEG.times,squeeze(mean(EEG.data(chan2plot,:,cond2Idx),3)),'k','linew',3)
xlabel('Time (s)')
ylabel('Voltage (\muV)')
set(gca,'ylim',[-10 10],'xlim',[-200 800])
hold on
plot([0 0],get(gca,'ylim'),'k--','linew',3)
title('Average over trials')
grid on

sgtitle(['Hypothesis ' num2str(hypothesis) ': ERP for subject ' num2str(subj2plot)])

%% Plot individual trials and ERP overlaid on top (1 subject, 1 channel)
% Change xlim and ylim accordingly
figure(3), clf, hold on
h = plot(EEG.times,squeeze(EEG.data(chan2plot,:,:)));
plot(EEG.times,mean(EEG.data(chan2plot,:,:),3),'k','linew',2);
set(gca,'xlim',[-200 800],'ylim',[-100 100])
xlabel('Time (s)'), ylabel('Activity (\muV)')

% Buttefly plot (all channels overlaid - same as earlier)
figure(4),clf
subplot(3,1,1:2)
plot(EEG.times,squeeze(mean(EEG.data(:,:,:),3)),'linew',2)
set(gca,'xlim',[-500 1300])
title('Butterfly plot')
xlabel('Time (s)'), ylabel('Voltage (\muV)')
grid on

% Variance time-series (related to RMS time-series)
subplot(313)
var_ts = var( mean(EEG.data,3) );
plot(EEG.times,var_ts,'k-','linew',2)
set(gca,'xlim',[-500 1300])
xlabel('Time (s)'), ylabel('Voltage (\muV)')
grid on
title('Topographical variance time series')

%% topoplot time series at average around time point

% individual time points might be noisy (or contain unrepresentative data),
% so we average around time points

% time points for topographies
times2plot = -200:50:800; % in ms (plot voltage activity at these time points)

tidx = dsearchn(EEG.times',times2plot'); % convert to indices

% window size
twin = 10; % in ms; half of window - 150ms previously will instead be the average from 140-160ms

% convert to indices
twinidx = round(twin/(1000/EEG.srate)); % nr sample points time-window - 1000 gets us into ms
% so, 2.56 samples to get 10 ms at 256 Hz. Round so we can actually index

% define subplot geometry
subgeomR = ceil(sqrt(length(tidx))); % how many rows we need
subgeomC = ceil(length(tidx)/subgeomR); % how many columns we need

figure(5), clf % now we also need to avg over 2nd dim (time points)
for i=1:length(tidx)
    subplot( subgeomR,subgeomC,i )
    
    % time points to average together
    times2ave = tidx(i)-twinidx : tidx(i)+twinidx; % 2 avg. center-wind to center+wind
    
    % draw the topomap
    topoplotIndie( mean(mean(EEG.data(:,times2ave,:),3),2),EEG.chanlocs,'electrodes','on','numcontour',0 );
    set(gca,'clim',[-1 1]*10)
    title([ num2str(times2plot(i)) ' ms' ])
end
colormap jet
sgtitle('Topoplot time series')

% Plot above shows electrodes, but not iso-contour lines
% Very similar with and without averaging 20 ms. Avg more robust


%% Permutation testing ERP
% For each channel
% Start by plotting the two ERPs for all subjects (grAvg subplot?)
% Null 



% Fieldtrip mass-univariate things





%% Random notes
% EEG.times has the time points (at least after epoching). It has
% a zero latency point find(EEG.times==0). Func checkeegzerolat
% might be of interest

% chap 15 for between subject stats (on e.g.
% mean amp from erplab, easy). Single trials, single sub
% ERPs etc, how to get them in Matlab variable?
% Averager.m?

% see pop_averager and averager.m (ERPLAB)


% Average reference
% new channel vector is itself minus average over channels (mean center
% each time and trial point)
% EEG.cardata = bsxfun(@minus,EEG.data,mean(EEG.data,1)); % car: common average reference


%% Channel operations - Just trying things out, we should decide what constitutes "fronto-central" channels etc., I guess.
% EEG2=EEG;
% 
% % ERPLAB channel operations
% % ch69 = (ch2+ch3) / 2  %AF7+AF3
% % ch70 = (ch35+ch36) / 2 % AF8+AF4
% EEG = pop_eegchanoperator( EEG, {  'ch69 = (ch2+ch3) / 2',  'ch70 = (ch35+ch36) / 2'} , 'ErrorMsg', 'popup', 'KeepChLoc', 'on', 'Warning',...
%  'on' );
% 
% 
% % Manually - same result
% EEG2.data(69,:) = (EEG2.data(2,:) + EEG2.data(3,:)) ./ 2;
% EEG2.data(70,:) = (EEG2.data(35,:) + EEG2.data(36,:)) ./ 2;
% EEG2.nbchan = EEG2.nbchan+2;
% EEG2.chanlocs(69).labels = 'weird cluster'
% EEG2.chanlocs(70).labels = 'weird cluster 2'
% isequal(EEG.data,EEG2.data)
