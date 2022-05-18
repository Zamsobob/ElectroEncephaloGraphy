%% Statistics for hypotheses 2b and 2c
%
% See the end of the script for a rough outline of what was done
%
%% Set up
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

% Create output folder for condition-level analyses
imgDir     = 'outputStats';
if ~exist(imgDir, 'dir')
    mkdir(projectPath, imgDir)
end
imgDir     = [projectPath filesep imgDir];
hypothesis = 2;

% Initialize output struct
tfdata.data    = [];
tfdata.note    = 'tf5D is condition x subject x channel x frequency x time';
tfdata.theta   = [];
tfdata.alpha   = [];
%% Load all subjects
% loop over subjects
for sub = 1:length(lists.subjectList)

    % Find files to load
    subject    = lists.subjectList{sub};
    subject    = extractBefore(subject, fileExt);
    fileName   = [subject '_preprocessed_hypothesis2_TFA.set'];
    subjFolder = lists.subjFolderPaths(sub).subjFolderPaths;

    % Load current dataset
    EEG = pop_loadset('filename',fileName, ...
        'filepath', subjFolder);

    % Store in ALLEEG structure
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, sub);

end

% TFA parameters
freqrange  = [2 40]; % Frequency range [min max] Hz
numfrex    = 42;     % number of frequency steps
frex       = linspace(freqrange(1),freqrange(2),numfrex);
times2save = -250:25:1250; % in ms (40 Hz)
nSubs      = length(ALLEEG); % for convenience

% Initialize subject TF matrices
tfCond1 = zeros(nSubs, EEG.nbchan, length(frex), length(times2save)); % subs x chans x freqs x timepoints (power dB)
tfCond2 = zeros(nSubs, EEG.nbchan, length(frex), length(times2save));
tf5D    = zeros(2, nSubs, EEG.nbchan, length(frex), length(times2save)); % cond x subs x chans x frex x pnts

% Create TF matrix with all subjects for condition 1
for i = 1:nSubs
    tempCond1          = ALLEEG(i).TFA.hypo2.tfCond1(:,:,:,2);
    tfCond1(i,:,:,:)   = tempCond1;
end

% % Create TF matrix with all subjects for condition 2

for i = 1:nSubs
    tempCond2          = ALLEEG(i).TFA.hypo2.tfCond2(:,:,:,2);
    tfCond2(i,:,:,:)   = tempCond2;
end

% Create matrix with both conditions (and all subjects, all channels)
tf5D(1,:,:,:,:) = tfCond1;
tf5D(2,:,:,:,:) = tfCond2;
tfdata.data     = tf5D;
%% Hypothesis 2b - Fronto-central theta power

loopCount = 1;
chans2run     = [9:11, 44:47];
% Loop over channels
for chanj = chans2run % fronto-central idx
tf4D = squeeze(tf5D(:,:,chanj,:,:)); % cond x sub x frex x pnts
% Create directory to save figures
chanDir    = ['Electrode_' num2str(chanj) '_' ALLEEG(1).chanlocs(chanj).labels];
cd(imgDir)
if ~exist(chanDir, 'dir')
    mkdir(chanDir)
end
chanImgDir = [imgDir filesep chanDir];

% compute grand average over all subjects and both conditions
grandAve = squeeze(mean(mean(tf5D),2));

% Plot grand average TF map
figure(1), clf
contourf(times2save,frex,squeeze(grandAve(chanj,:,:)),40,'linecolor','none')
set(gca,'clim',[-1 1]*3)
xlabel('Time (ms)'), ylabel('Frequency (Hz)')
    title([ 'Grand average time-frequency map for channel ' num2str(chanj) ])
colormap jet
c = colorbar;
c.Label.String = 'dB from baseline';
xline(0,'k:','LineWidth', 2);

% Time-frequency windows based on a priori hypothesized regions of interest
% (ROIs)
time1 = [300 500]; % 300 - 500 ms time-window

freq1 = [4 7]; % theta defined as 4-7 Hz

% Draw rectangles corresponding to ROIs on grand average TF map
hold on
rectangle('Position',[time1(1) freq1(1) diff(time1) diff(freq1)],'linew',3)
% rectangle('Position',[time2(1) freq2(1) diff(time2) diff(freq2)],'linew',3)
text(time1(1),freq1(2),'Theta ROI','VerticalAlignment','bottom','FontSize',10)
% text(time2(1),freq2(2),'Alpha ROI','VerticalAlignment','bottom','FontSize',10)
set(gca,'FontSize',12)

plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
saveas(gcf, plotName)
%% Extract data per subject and condition from the ROIs

% convert to indices
time1idx = dsearchn(times2save',time1');
freq1idx = dsearchn(frex',freq1');

% Condition 1 is new, condition 2 is old.

% Labels for bar plot
labels = { 'theta New';'theta Old' };
data = zeros(2,nSubs); % initialize

% Extract power from the ROIs for all subjects
data(1,:) = squeeze(mean(mean(tf4D(1,:,freq1idx(1):freq1idx(2),time1idx(1):time1idx(2)),3),4));
data(2,:) = squeeze(mean(mean(tf4D(2,:,freq1idx(1):freq1idx(2),time1idx(1):time1idx(2)),3),4));

% finally, show a bar plot of the results (errorbar is SEM)
figure(2), clf, hold on
bh = bar([1 2],mean(data,2));
eh = errorbar([1 2],mean(data,2),std(data,[],2)/sqrt(nSubs),'.'); % SEM
set(gca,'XTickLabel',labels,'xtick',[1 2])
set(eh,'LineWidth',2,'color','k')
ylabel('Mean power (dB) within a region of interest')
title(['Effect of image novelty on theta power for channel ' num2str(chanj)])
plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
saveas(gcf, plotName)

%% Inference
% Pool data for each sub-hypothesis (difference in theta and diff in alpha, b c)
dataTheta = cat(2, data(1,:), data(2,:));
dataTheta = dataTheta'; % row vec to column vec, convenience

% Save corresponding condition labels
truelabels = cat(1, ones(nSubs,1), 2*ones(nSubs,1) ); % 33 ones followed by 33 twos (same for both sub-hypotheses)

% compute the observed condition mean difference
trueConddiffTheta = mean(dataTheta(truelabels==2)) - mean(dataTheta(truelabels==1)); % 2 - 1

%% Permutation to generate null distribution
nPerms = 1000000;

% % initialize permuted condition differences
permvalsTheta = deal(zeros(nPerms,1));
for permi = 1:nPerms
    % generate shuffled labels
    shuffledlabels = truelabels(randperm(length(truelabels)));

    % mean difference of shuffled labels
    permvalsTheta(permi) = mean(dataTheta(shuffledlabels==2)) - mean(dataTheta(shuffledlabels==1));
end

% Plot null distribution and observed mean differences
figure(3), clf
subplot(2,1,1:2), hold on
histogram(permvalsTheta,40)
plot([1 1]*trueConddiffTheta,get(gca,'ylim'),'r--','linew',3) % line
legend({'Shuffled';'True'})
set(gca,'xlim',[-1 1]*2)
xlabel('Mean value')
ylabel('Count')
title('Theta sub-hypothesis')

sgtitle('Permuted null distributions and mean values')
plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
saveas(gcf, plotName)
%% Generate non-parametric p-values 

% permuted statistics
permmeanTheta = mean(permvalsTheta);
permstdTheta  = std(permvalsTheta);

% Number of permuted means that were greater than observed mean
pValTheta = sum( permvalsTheta>trueConddiffTheta ) / nPerms;

% Normalized distance of the observed p-value from the distribution of H_0 p-values
% zValTheta = (trueConddiffTheta - permmeanTheta) / permstdTheta;
% zValAlpha = (trueConddiffAlpha - permmeanAlpha) / permstdAlpha;
% 1-normcdf(zValTheta)
% 1-normcdf(zValAlpha)

%% Calculate descriptive statistics for output

% Initialize results field of output struct
tfdata.theta(loopCount).electrode = EEG.chanlocs(chanj).labels;
tfdata.theta(loopCount).theta     = [];

data=data'; % thetaNew, thetaOld
datastats = data(:,1:2);
datastats(:,3) = bsxfun(@minus,datastats(:,2),datastats(:,1));
% datastats(:,4:5) = data(:,3:4);
% datastats(:,6) = bsxfun(@minus,datastats(:,5),datastats(:,4));


% Descriptives:
meanvec     = mean(data,1); % mean each condition
stdvec      = std(data,[],1); % std each condition
varvec      = var(data,[],1); % var each condition
meandiff    = meanvec(2) - meanvec(1); % mean difference theta
% meandiff(2) = meanvec(4) - meanvec(3); % mean difference alpha
stddiff     = std(datastats(:,3),[],1); % std of difference scores
semdiff     = stddiff ./ sqrt(nSubs); % standard error of mean difference scores

for i = 1:nSubs
theta.data(i).subject = i;
theta.data(i).new = datastats(i,1);
theta.data(i).old = datastats(i,2);
theta.data(i).diff = datastats(i,3);
end

% theta descriptives
theta.descriptives.meanNew  = meanvec(1);
theta.descriptives.meanOld  = meanvec(2);
theta.descriptives.stdNew   = stdvec(1);
theta.descriptives.stdOld   = stdvec(2);
theta.descriptives.meanDiff = meandiff(1);
theta.descriptives.stdDiff  = stddiff(1);
theta.descriptives.SEMDiff  = semdiff(1);


%% Effect sizes
nTests = length(chans2run); % number of tests, 1 per electrode (for FWER)

% Theta
var1 = var(dataTheta(truelabels==1)); % variance condition 1
var2 = var(dataTheta(truelabels==2)); % variance condition 2
stdPooledTheta = sqrt((var1 + var2) / 2); % avg std of both conditions as standardizer
hedgecorr = 1-(3 / (4*(2*nSubs)-9)); % Hedge's correction

cohensD = trueConddiffTheta / stdPooledTheta; % Cohen's D_av
hedgesG = cohensD * hedgecorr; % Hedge's G

% Save for documentation
theta.inference.meanDiff   = meandiff(1);
theta.inference.cohensD    = cohensD;
theta.inference.hedgesG    = hedgesG;
theta.inference.pVal       = pValTheta;
theta.inference.signUncorr = false;
theta.inference.signCorr   = false;
if pValTheta <= .05 / nTests
    theta.inference.signCorr   = true;
    theta.inference.signUncorr = true;
elseif pValTheta <= .05
    theta.inference.signUncorr = true;
end

tfdata.theta(loopCount).theta = theta;


loopCount = loopCount+1;
end



%% hypothesis 2c - posterior alpha power
loopCount = 1;
chans2run     = [20:31, 57:64];

for chanj = chans2run % posterior channels
tf4D = squeeze(tf5D(:,:,chanj,:,:)); % cond x sub x frex x pnts
% Create directory to save figures
chanDir    = ['Electrode_' num2str(chanj) '_' ALLEEG(1).chanlocs(chanj).labels];
cd(imgDir)
if ~exist(chanDir, 'dir')
    mkdir(chanDir)
end
chanImgDir = [imgDir filesep chanDir];

% compute grand average over all subjects and both conditions
grandAve = squeeze(mean(mean(tf5D),2));

% Plot grand average TF map
figure(4), clf
contourf(times2save,frex,squeeze(grandAve(chanj,:,:)),40,'linecolor','none')
set(gca,'clim',[-1 1]*3)
xlabel('Time (ms)'), ylabel('Frequency (Hz)')
    title([ 'Grand average time-frequency map for channel ' num2str(chanj) ])
colormap jet
c = colorbar;
c.Label.String = 'dB from baseline';
xline(0,'k:','LineWidth', 2);

% Time-frequency windows based on a priori hypothesized regions of interest
% (ROIs)
time2 = [300 500]; % 300 - 500 ms time-window
freq2 = [8 12]; % alpha defined as 8-12 Hz

% Draw rectangles corresponding to ROIs on grand average TF map
hold on
% rectangle('Position',[time1(1) freq1(1) diff(time1) diff(freq1)],'linew',3)
rectangle('Position',[time2(1) freq2(1) diff(time2) diff(freq2)],'linew',3)
% text(time1(1),freq1(2),'Theta ROI','VerticalAlignment','bottom','FontSize',10)
text(time2(1),freq2(2),'Alpha ROI','VerticalAlignment','bottom','FontSize',10)
set(gca,'FontSize',12)

plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
saveas(gcf, plotName)

%% Extract data per subject and condition from the ROIs

% convert to indices
time2idx = dsearchn(times2save',time2');
freq2idx = dsearchn(frex',freq2');

% Condition 1 is new, condition 2 is old.

% Labels for bar plot
labels = { 'alpha New';'alpha Old' };
data = zeros(2,nSubs); % initialize

data(1,:) = squeeze(mean(mean(tf4D(1,:,freq2idx(1):freq2idx(2),time2idx(1):time2idx(2)),3),4));
data(2,:) = squeeze(mean(mean(tf4D(2,:,freq2idx(1):freq2idx(2),time2idx(1):time2idx(2)),3),4));

% finally, show a bar plot of the results (errorbar is SEM)
figure(5), clf, hold on
bh = bar([1 2],mean(data,2));
eh = errorbar([1 2],mean(data,2),std(data,[],2)/sqrt(nSubs),'.'); % SEM
set(gca,'XTickLabel',labels,'xtick',[1 2])
set(eh,'LineWidth',2,'color','k')
ylabel('Mean power (dB) within a region of interest')
title(['Effect of image novelty on alpha power for channel ' num2str(chanj)])
plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
saveas(gcf, plotName)

%% Inference
% Pool data
dataAlpha = cat(2, data(1,:), data(2,:));
dataAlpha = dataAlpha'; % row vec to column vec, convenience

% Save corresponding condition labels
truelabels = cat(1, ones(nSubs,1), 2*ones(nSubs,1) ); % 33 ones followed by 33 twos (same for both sub-hypotheses)

% compute the observed condition mean difference
trueConddiffAlpha = mean(dataAlpha(truelabels==2)) - mean(dataAlpha(truelabels==1)); % 2 - 1

%% Permutation to generate null distribution
nPerms = 1000000;

% % initialize permuted condition differences
permvalsAlpha = deal(zeros(nPerms,1));
for permi = 1:nPerms
    % generate shuffled labels
    shuffledlabels = truelabels(randperm(length(truelabels)));

    % mean difference of shuffled labels
    permvalsAlpha(permi) = mean(dataAlpha(shuffledlabels==2)) - mean(dataAlpha(shuffledlabels==1));
end

% Plot null distribution and observed mean differences
figure(5), clf

subplot(2,1,1:2), hold on
histogram(permvalsAlpha,40)
plot([1 1]*trueConddiffAlpha,get(gca,'ylim'),'r--','linew',3)
legend({'Shuffled';'True'})
set(gca,'xlim',[-1 1]*2)
xlabel('Mean value')
ylabel('Count')
title('Alpha sub-hypothesis')

sgtitle('Permuted null distributions and mean values')
plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
saveas(gcf, plotName)

%% Generate non-parametric p-values 
% permuted statistics
permmeanAlpha = mean(permvalsAlpha);
permstdAlpha  = std(permvalsAlpha);

% Number of permuted means that were greater than observed mean
pValAlpha = sum( permvalsAlpha>trueConddiffAlpha ) / nPerms;

%% Calculate descriptive statistics for output
tfdata.alpha(loopCount).electrode = EEG.chanlocs(chanj).labels;
tfdata.alpha(loopCount).alpha     = [];

data=data'; % alphaNew, alphaOld
datastats = data(:,1:2);
datastats(:,3) = bsxfun(@minus,datastats(:,2),datastats(:,1));
% datastats(:,4:5) = data(:,3:4);
% datastats(:,6) = bsxfun(@minus,datastats(:,5),datastats(:,4));


% Descriptives:
meanvec     = mean(data,1); % mean each condition
stdvec      = std(data,[],1); % std each condition
varvec      = var(data,[],1); % var each condition
meandiff    = meanvec(2) - meanvec(1); % mean difference alpha
stddiff     = std(datastats(:,3),[],1); % std of difference scores
semdiff     = stddiff ./ sqrt(nSubs); % standard error of mean difference scores

for i = 1:nSubs
alpha.data(i).subject = i;
alpha.data(i).new = datastats(i,1);
alpha.data(i).old = datastats(i,2);
alpha.data(i).diff = datastats(i,3);
end

% alpha descriptives
alpha.descriptives.meanNew  = meanvec(1);
alpha.descriptives.meanOld  = meanvec(2);
alpha.descriptives.stdNew   = stdvec(1);
alpha.descriptives.stdOld   = stdvec(2);
alpha.descriptives.meanDiff = meandiff(1);
alpha.descriptives.stdDiff = stddiff(1);
alpha.descriptives.SEMDiff = semdiff(1);


%% Effect sizes
nTests = length(chans2run); % number of tests, 1 per electrode (for FWER)

% Alpha
var1 = var(dataAlpha(truelabels==1)); % variance condition 1
var2 = var(dataAlpha(truelabels==2)); % variance condition 1
stdPooledAlpha = sqrt((var1 + var2) / 2); % avg std of both conditions as standardizer
hedgecorr = 1-(3 / (4*(2*nSubs)-9)); % Hedge's correction

cohensD = trueConddiffAlpha / stdPooledAlpha; % Cohen's D_average (see formula 10 in Lakens, 2013)
hedgesG = cohensD * hedgecorr; % Hedge's G

% Save for documentation
alpha.inference.meanDiff   = meandiff(1);
alpha.inference.cohensD    = cohensD;
alpha.inference.hedgesG    = hedgesG;
alpha.inference.pVal       = pValAlpha;
alpha.inference.signUncorr = false;
alpha.inference.signCorr   = false;
if pValAlpha <= .05 / nTests
    alpha.inference.signCorr   = true;
    alpha.inference.signUncorr = true;
elseif pValAlpha <= .05
    alpha.inference.signUncorr = true;
end

tfdata.alpha(loopCount).alpha = alpha;

loopCount = loopCount+1;
end

if ~exist('stats', 'var')
load('stats.mat')
end
stats.hypo2 = tfdata;

save('stats.mat','stats')

%% %% Print out table of results
% create table for hyp 2b
tempstruct.Electrode = [];
tempstruct.Mean_old  = [];
tempstruct.Mean_new  = [];
tempstruct.Mean_diff = [];
tempstruct.pvalue    = [];
tempstruct.Hedges_G  = [];

for k = 1:7
tempstruct(k).Electrode = stats.hypo2.theta(k).electrode;
tempstruct(k).Mean_old  = stats.hypo2.theta(k).theta.descriptives.meanOld;
tempstruct(k).Mean_new  = stats.hypo2.theta(k).theta.descriptives.meanNew;
tempstruct(k).Mean_diff = stats.hypo2.theta(k).theta.descriptives.meanDiff;
tempstruct(k).pvalue    = stats.hypo2.theta(k).theta.inference.pVal;
tempstruct(k).Hedges_G  = stats.hypo2.theta(k).theta.inference.hedgesG;
end

T = struct2table(tempstruct);
writetable(T, 'statsHyp2b.txt', 'Delimiter', '\t', 'QuoteStrings', true)
clear tempstruct

% create table for hyp 2c
tempstruct.Electrode = [];
tempstruct.Mean_old  = [];
tempstruct.Mean_new  = [];
tempstruct.Mean_diff = [];
tempstruct.pvalue    = [];
tempstruct.Hedges_G  = [];

for k = 1:20
tempstruct(k).Electrode = stats.hypo2.alpha(k).electrode;
tempstruct(k).Mean_old  = stats.hypo2.alpha(k).alpha.descriptives.meanOld;
tempstruct(k).Mean_new  = stats.hypo2.alpha(k).alpha.descriptives.meanNew;
tempstruct(k).Mean_diff = stats.hypo2.alpha(k).alpha.descriptives.meanDiff;
tempstruct(k).pvalue    = stats.hypo2.alpha(k).alpha.inference.pVal;
tempstruct(k).Hedges_G  = stats.hypo2.alpha(k).alpha.inference.hedgesG;
end

T2 = struct2table(tempstruct);
writetable(T2, 'statsHyp2c.txt', 'Delimiter', '\t', 'QuoteStrings', true)

cd(projectPath)
fprintf('\n\n\n**** hyp2 stats finished ****\n\n\n');

%% Methods description (rough outline)
%% Hypothesis 2b

% Based on a priori hypothesized time-frequency regions of interest (ROI), power corresponding to the theta band
% (defined as 4-7 Hz) was extracted during a time window from 300 ms to 500 ms for each subject and each condition.
% These values were subsequently averaged over time and frequency to produce one power value for each condition and
% subject. This process was repeated for each of the seven frontocentral electrodes (FC5, FC3, FC1, FC6, FC4, FC2,
% and FCz). 
%
% For each electrode of interest, conditions were randomly permuted 1 million times to produce a null distribution
% of mean differences between conditions. This empirical null distribution was then used to calculate nonparametric
% p-values representing the proportion of permuted mean differences greater than the observed mean differences.
% Because one permutation test was conducted for each electrode of interest, Bonferroni correction was applied,
% resulting in a nominal p-value threshold of 0.05/7=.0071429. The mean difference between conditions (old and new)
% was considered significant if the p-value was below this threshold. In this case, the null hypothesis that the two
% means come from the same distribution was rejected, which confirmed the hypothesis. Additionally, Cohen's d
% (using the average standard deviation of both conditions as a standardizer) was calculated and corrected with
% Hedge's correction factor to produce Hedges's g (see Lakens, 2013).

%% Hypothesis 2c

% Based on a priori hypothesized time-frequency regions of interest (ROI), power corresponding to the alpha band
% (defined as 8-12 Hz) was extracted during a time window from 300 ms to 500 ms for each subject and each condition.
% These values were subsequently averaged over time and frequency to produce one power value for each condition and
% subject. This process was repeated for each of the 20 posterior electrodes (P1, P3, P5, P7, P9, PO7, PO3, O1, Iz,
% Oz, POz, Pz, P2, P4, P6, P8, P10, PO8, PO4, and O2). 

% For each electrode of interest, conditions were randomly permuted 1 million times to produce a null distribution
% of mean differences between conditions. This empirical null distribution was then used to calculate nonparametric
% p-values representing the proportion of permuted mean differences greater than the observed mean differences.
% Because one permutation test was conducted for each electrode of interest, Bonferroni correction was applied,
% resulting in a nominal p-value threshold of 0.05/20=0.0025. The mean difference between conditions (old and new)
% was considered significant if the p-value was below this threshold. In this case, the null hypothesis that the two
% means come from the same distribution was rejected, which confirmed the hypothesis. Additionally, Cohen's d
% (using the average standard deviation of both conditions as a standardizer) was calculated and corrected with
% Hedge's correction factor to produce Hedges's g (see Lakens, 2013).
