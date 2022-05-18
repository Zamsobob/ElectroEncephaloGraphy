%% Statistics for hypotheses 3b and 3c
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

% Create out put folder for condition-level analyses
imgDir = 'outputStats';
if ~exist(imgDir, 'dir')
    mkdir(projectPath, imgDir)
end
imgDir = [projectPath filesep imgDir];

% Initialize output struct
tfdata.data      = [];
tfdata.note      = 'tf5D is condition x subject x channel x frequency x time';
tfdata.clusters  = [];
tfdata2.data     = [];
tfdata2.note     = 'tf5D is condition x subject x channel x frequency x time';
tfdata2.clusters = [];

%% Load all subjects
% loop over hypotheses 3, and 4
for hypothesis = 3:4
    % loop over subjects
    for sub = 1:length(lists.subjectList)

        % Find files to load
        subject    = lists.subjectList{sub};
        subject    = extractBefore(subject, fileExt);

        if hypothesis == 3
            fileName   = [subject '_preprocessed_hypothesis3_TFA.set'];
        else
            fileName   = [subject '_preprocessed_hypothesis4_TFA.set'];
        end

        subjFolder = lists.subjFolderPaths(sub).subjFolderPaths;

        % Load current dataset
        EEG = pop_loadset('filename',fileName, ...
            'filepath', subjFolder);

        % Store in ALLEEG structure
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, sub);

        %     [ALLEEGhyp2, EEG] = eeg_store(ALLEEG, EEG, sub);
        %
        %     [ALLEEGhyp3, EEG] = eeg_store(ALLEEG, EEG, sub);
    end

    % TFA parameters
    freqrange = [2 40]; % Frequency range [min max] Hz
    numfrex   = 42;     % number of frequency steps
    frex      = linspace(freqrange(1),freqrange(2),numfrex);
    times2save = -250:25:1250; % in ms (40 Hz)
    nSubs = length(ALLEEG); % for convenience

    % Initialize subject TF matrices
    tfCond1 = zeros(nSubs, EEG.nbchan, length(frex), length(times2save)); % subs x chans x freqs x timepoints (power dB)
    tfCond2 = zeros(nSubs, EEG.nbchan, length(frex), length(times2save));
    tf5D    = zeros(2, nSubs, EEG.nbchan, length(frex), length(times2save)); % cond x subs x chans x frex x pnts

    % Create TF matrix with all subjects for condition 1
    if hypothesis == 3
        for i = 1:nSubs
            tempCond1          = ALLEEG(i).TFA.hypo3.tfCond1(:,:,:,2);
            tfCond1(i,:,:,:)   = tempCond1;
        end
    else
        for i = 1:nSubs
            tempCond1          = ALLEEG(i).TFA.hypo4.tfCond1(:,:,:,2);
            tfCond1(i,:,:,:)   = tempCond1;
        end
    end

    % % Create TF matrix with all subjects for condition 2
    if hypothesis == 3
        for i = 1:nSubs
            tempCond2          = ALLEEG(i).TFA.hypo3.tfCond2(:,:,:,2);
            tfCond2(i,:,:,:)   = tempCond2;
        end
    else
        for i = 1:nSubs
            tempCond2          = ALLEEG(i).TFA.hypo4.tfCond2(:,:,:,2);
            tfCond2(i,:,:,:)   = tempCond2;
        end
    end

    % Create matrix with both conditions (and all subjects, all channels)
    tf5D(1,:,:,:,:) = tfCond1;
    tf5D(2,:,:,:,:) = tfCond2;

    % Save in output struct
    if hypothesis == 3
        tfdata.data      = tf5D;
    else
        tfdata2.data     = tf5D;
    end

    %% Statistics
    % Loop over EEG channels for plotting
    chans2run = 1:EEG.nbchan-4;
    for chanj = chans2run % minus 4 EOG channels
        % Create directory to save figures
        chanDir = ['Electrode_' num2str(chanj) '_' ALLEEG(1).chanlocs(chanj).labels];
        cd(imgDir)
        if ~exist(chanDir, 'dir')
            mkdir(chanDir)
        end
        chanImgDir = [imgDir filesep chanDir];

        % TF plots of each subject for one channel
        % Condition 1
        figure(1),clf
        for i = 1:nSubs
            subplot(6,6,i),hold on
            contourf(times2save, frex, squeeze(tf5D(1,i,chanj,:,:)),40,'linecolor','none')
            title(['S' num2str(i)])
            set(gca,'FontSize',4, 'TitleFontSizeMultiplier',2,'XTick',[0 400 800 1200])
            colormap jet
        end
        sgtitle(['Time-Frequency power (dB) of condition 1 for channel ' num2str(chanj)])
        plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
        saveas(gcf, plotName)

        % Condition 2
        figure(2),clf
        for i = 1:nSubs
            subplot(6,6,i),hold on
            contourf(times2save, frex, squeeze(tf5D(2,i,chanj,:,:)),40,'linecolor','none')
            title(['S' num2str(i)])
            set(gca,'FontSize',4, 'TitleFontSizeMultiplier',2,'XTick',[0 400 800 1200])
            colormap jet
        end
        sgtitle(['Time-Frequency power (dB) of condition 2 for channel ' num2str(chanj)])
        plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
        saveas(gcf, plotName)

        % Plot mean TF image for both conditions (across subjects) for one channel
        figure(3), clf
        for i=1:2
            subplot(2,1,i)
            contourf(times2save,frex,squeeze(mean(tf5D(i,:,chanj,:,:))),40,'linecolor','none')
            set(gca,'clim',[-1 1]*3)
            xlabel('Time (ms)'), ylabel('Frequency (Hz)')
            title([ 'Time-frequency map for condition ' num2str(i) ])
            colormap jet
            c = colorbar;
            c.Label.String = 'Power (db)';
            xline(0,'k:','LineWidth', 2);
        end
        sgtitle(['Time-Frequency Analysis for channel ' num2str(chanj)])
        plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
        saveas(gcf, plotName)


        %% Permutation

        % Hypothesis 3b. There are effects of successful recognition of old images
        % on spectral power, at any frequencies, at any channels, at any time.

        % The null hypothesis is that there is no difference between conditions 1
        % and 2. So, condition 1 minus condition 2 (and vice versa) should be 0 (plus noise).

        tf4D = squeeze(tf5D(:,:,chanj,:,:)); % cond x sub x frex x pnts

        % stats parameters
        nPerms = 10000;
        pVal   = .05; % two-tailed!
        sigThresh = norminv(1-pVal/2);

        % compute observed differences
        tfDiff = squeeze (diff(tf4D, [], 1)); % difference along 1st dim (condition)
        tfFake = zeros(size(tfDiff));

        % initialize permuted condition differences matrix
        permutedDiffs = zeros(nPerms, length(frex), length(times2save));

        % Loop over permutations
        for permi = 1:nPerms
            %random sequence of +/- 1
            fakeconds = sign(randn(nSubs,1));

            % randomize sign of the fake difference map
            for si=1:nSubs % loop over subjects
                tfFake(si,:,:) = fakeconds(si)*tfDiff(si,:,:); % fake diff = true diff for this subject times 1 or -1
            end

            % compute and store difference time series
            permutedDiffs(permi,:,:) = mean(tfFake);
        end

        %% pixel-based statistical thresholding

        % zmap - observed difference - mean of permuted differences divided by
        % standard deviation of null hypothesis differences
        [zmap,zthreshMap] = deal( squeeze( (mean(tfDiff)-mean(permutedDiffs,1)) ./ std(permutedDiffs,[],1) ) );
        zthreshMap(abs(zmap)<sigThresh) = 0; % set pixels below threshold to 0

        clim = [-1 1]*5;
        colormap jet

        figure(4), clf
        subplot(411)
        contourf(times2save,frex,squeeze(mean(tfDiff)),40,'linecolor','none')
        set(gca,'clim',[-1 1]*3,'FontSize',8, 'TitleFontSizeMultiplier',1.2,'XTick',[0 400 800 1200])
        xlabel('Time (ms)'), ylabel('Frequency (Hz)')
        title('Observed difference map "raw" power') % cond 1 minus cond 2
        set(gca,'clim',[-1 1]*3)
        c = colorbar;
        c.Label.String = 'Power (dB)';
        xline(0,'k:','LineWidth', 2);

        subplot(412)
        contourf(times2save,frex,zmap,40,'linecolor','none')
        set(gca,'clim',clim)
        xlabel('Time (ms)'), ylabel('Frequency (Hz)')
        title('Difference Z-map') % non-thresholded. Incorporates variance
        c = colorbar;
        c.Label.String = 'Z-score';
        xline(0,'k:','LineWidth', 2);

        subplot(413)
        contourf(times2save,frex,zthreshMap,40,'linecolor','none')
        set(gca,'clim',clim)
        xlabel('Time (ms)'), ylabel('Frequency (Hz)')
        title('Thresholded difference Z-map (uncorrected p<.05)') % uncorrected for multiple comparisons
        c = colorbar;
        c.Label.String = 'Z-score';
        xline(0,'k:','LineWidth', 2);

        %% Null hypothesis cluster size permutation

        % initialize cluster sizes from permutation
        clustsizes = zeros(nPerms,1);

        % Below, we take each permuted difference map and treat it as if it were a
        % real map by: computing a Z-map, thresholding it, finding clusters, and
        % saving the largest cluster on each iteration
        for permi=1:nPerms

            % compute z-score difference (permuted diff, expect 0 +- noise)
            zdiffFake = squeeze( (permutedDiffs(permi,:,:)-mean(permutedDiffs)) ./ std(permutedDiffs) );
            % imagesc(zdiffFake)

            % threshold fake map (cluster-threshold p < .05)
            zdiffFake( abs(zdiffFake)<sigThresh ) = 0; % imagesc(zdiffFake)

            % identify clusters (so we can find the biggest one)
            islands = bwconncomp( logical(zdiffFake) );
            % NumObjects - nr of clusters (even single values are clusters)
            % PixelIdxList - indices of the clusters. islands.PixelIdxList{1}

            % find cluster sizes (length of all elements, nr of pixels inside identified clusters (above threshold))
            if numel(islands.PixelIdxList)>0
                clustNs = cellfun(@length,islands.PixelIdxList);
                clustsizes(permi) = max(clustNs); % store largest cluster of each iteration
            end
        end

        % compute cluster threshold
        clustthresh = prctile(clustsizes,100-pVal*100); % 95th percentile
        %clustthresh

        % Plot nlull distribution of cluster sizes and threshold + null TF map
        figure(5), clf
        subplot(211)
        contourf(times2save,frex,squeeze(mean(permutedDiffs)),40,'linecolor','none')
        set(gca,'clim',[-.01 .01])
        xlabel('Time (ms)'), ylabel('Frequency (Hz)')
        title(['Null distribution TF map (averaged over ' num2str(nPerms) ' permutations)']) % Diff between conditions under the null hypothesis
        colormap jet
        c = colorbar;
        c.Label.String = 'Z-score';
        xline(0,'k:','LineWidth', 2);

        subplot(212), hold on
        histogram(clustsizes)
        plot([1 1]*clustthresh,get(gca,'ylim'),'r--','linew',3) % line for threshold
        xlabel('Maximum cluster size (pixels)'), ylabel('Count')
        title('Null hypothesis distribution of cluster sizes')

        plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
        saveas(gcf, plotName)

        %% remove small clusters from real thresholded data

        % find islands of the thresholded map of the observed differences
        islands = bwconncomp( logical(zthreshMap) );

        % find and remove any subthreshold islands
        % loop through all NumObjects clusters
        for ii=1:islands.NumObjects
            if numel(islands.PixelIdxList{ii})<clustthresh % if nr of pixels (elements) in each cluster is less than 95th prctile threshold
                zthreshMap(islands.PixelIdxList{ii}) = 0; % Then remove that cluster from thresholded zmap
            end
        end
        %islands.PixelIdxList
        % Indicate if any cluster size was significant
        islands.anySignificant = false;
        if sum(any(zthreshMap))
            islands.anySignificant = true;
        end

        % Add final tile to figure 3
        figure(4)
        subplot(414), hold on
        contourf(times2save,frex,zmap,40,'linecolor','none')
        try
            contour(times2save,frex,logical(zthreshMap),1,'linecolor','k')
        catch me
        end
        title('Cluster-corrected difference Z-map')
        set(gca,'clim',clim)
        colormap jet
        c = colorbar;
        c.Label.String = 'Z-score';
        xline(0,'k:','LineWidth', 2);
        sgtitle(['Statistical thresholding for channel ' num2str(chanj)])
        plotName = [chanImgDir filesep 'Hypothesis_' num2str(hypothesis) '_stats_figure_' num2str(gcf().Number) '.png'];
        saveas(gcf, plotName)

        % Save data for documentation
        if hypothesis == 3
            for k = chans2run
                tfdata.clusters(k).electrode      = EEG.chanlocs(k).labels;
            end
            tfdata.clusters(chanj).clustthresh    = clustthresh;
            tfdata.clusters(chanj).obsClusters    = islands;
            tfdata.clusters(chanj).anySignificant = islands.anySignificant;
        else
            for k = chans2run
                tfdata2.clusters(k).electrode      = EEG.chanlocs(k).labels;
            end
            tfdata2.clusters(chanj).clustthresh    = clustthresh;
            tfdata2.clusters(chanj).obsClusters    = islands;
            tfdata2.clusters(chanj).anySignificant = islands.anySignificant;
        end

    end % end channel loop
end % end hypothesis loop

% Save documentation to stats struct
if ~exist('stats', 'var')
load('stats.mat')
end
stats.hypo3 = tfdata;
stats.hypo4 = tfdata2;
save('stats.mat','stats')

%% Print out table of results

% create table for hyp 3b
tempstruct.Electrode          = [];
tempstruct.Clust_thresh       = [];
tempstruct.Size_largest_clust = [];
tempstruct.Any_sign_clust     = [];

for k = 1:64
tempstruct(k).Electrode          = stats.hypo3.clusters(k).electrode;
tempstruct(k).Clust_thresh       = stats.hypo3.clusters(k).clustthresh;
tempstruct(k).Size_largest_clust = max(cellfun(@length, stats.hypo3.clusters(k).obsClusters.PixelIdxList));
tempstruct(k).Any_sign_clust     = stats.hypo3.clusters(k).anySignificant;
end

T = struct2table(tempstruct);
writetable(T, 'statsHyp3b.txt', 'Delimiter', '\t', 'QuoteStrings', true)
%t=readtable('statsHyp3b.txt');
clear tempstruct

% create table for hyp 4b
tempstruct.Electrode          = [];
tempstruct.Clust_thresh       = [];
tempstruct.Size_largest_clust = [];
tempstruct.Any_sign_clust     = [];

for k = 1:64
tempstruct(k).Electrode          = stats.hypo4.clusters(k).electrode;
tempstruct(k).Clust_thresh       = stats.hypo4.clusters(k).clustthresh;
tempstruct(k).Size_largest_clust = max(cellfun(@length, stats.hypo4.clusters(k).obsClusters.PixelIdxList));
tempstruct(k).Any_sign_clust     = stats.hypo4.clusters(k).anySignificant;
end

T2 = struct2table(tempstruct);
writetable(T2, 'statsHyp4b.txt', 'Delimiter', '\t', 'QuoteStrings', true)

cd(projectPath)
fprintf('\n\n\n**** stats hyp3and4 finished ****\n\n\n');

%% Methods description (rough outline)
%% Hypothesis 3b

% To test for a difference between the conditions, cluster-based permutation testing was conducted in the following
% way, repeated for each electrode:
%   1.	A time-frequency difference map was calculated for each subject by taking the difference between the two
%       conditions at each (time-frequency) pixel.
%   2.	An empirical null distribution of time-frequency difference maps was generated by randomly permuting the
%       condition labels 10000 times.
%   3.	The empirical null distribution was used to calculate a group-level Z-map, where each pixel contains an
%       unthresholded Z-score. This map was thresholded at Z = 1.96 (equivalent to a two-tailed p<.05).
%   4.	An empirical null distribution of cluster sizes was generated by taking each permuted difference map and
%       computing a Z map, thresholding it, finding clusters of Z scores, and saving the largest cluster on each
%       iteration. This null distribution of cluster sizes was then used to identify the cluster size that was only
%       exceeded in five per cent of the permutations. Clusters in the actual time-frequency difference map
%       exceeding this threshold (95th percentile) were considered significant. 
%
% If an electrode contained any significant cluster, the null hypothesis that the two conditions come from the same
% distribution (and are thus exchangeable) was rejected, which was interpreted as a significant difference between
% conditions. A significant difference between the two conditions (hits and misses) was interpreted as confirming
% the hypothesis.
%
% Note that we did not correct for the large number of electrodes tested (64 tests), e.g., by calculating an
% experiment-wise error rate. Due to the exploratory nature of the stated hypothesis, we instead prioritized
% sensitivity to detect a potential effect.

%% Hypothesis 4b

% To test for a difference between the conditions, cluster-based permutation testing was conducted in the following
% way, repeated for each electrode:
%   1.	A time-frequency difference map was calculated for each subject by taking the difference between the two
%       conditions at each (time-frequency) pixel.
%   2.	An empirical null distribution of time-frequency difference maps was generated by randomly permuting the
%       condition labels 10000 times.
%   3.	The empirical null distribution was used to calculate a group-level Z-map, where each pixel contains an
%       unthresholded Z-score. This map was thresholded at Z = 1.96 (equivalent to a two-tailed p<.05).
%   4.	An empirical null distribution of cluster sizes was generated by taking each permuted difference map and
%       computing a Z map, thresholding it, finding clusters of Z scores, and saving the largest cluster on each
%       iteration. This null distribution of cluster sizes was then used to identify the cluster size that was only
%       exceeded in five per cent of the permutations. Clusters in the actual time-frequency difference map
%       exceeding this threshold (95th percentile) were considered significant. 

% If an electrode contained any significant cluster, the null hypothesis that the two conditions come from the same
% distribution (and are thus exchangeable) was rejected, which was interpreted as a significant difference between
% conditions. A significant difference between the two conditions (remembered and forgotten) was interpreted as
% confirming the hypothesis.

% Note that we did not correct for the large number of electrodes tested (64 tests), e.g., by calculating an
% experiment-wise error rate. Due to the exploratory nature of the stated hypothesis, we instead prioritized
% sensitivity to detect a potential effect.
