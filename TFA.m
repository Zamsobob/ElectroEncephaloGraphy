%% Time-Frequency Analysis

% We implemented time-frequency analysis by convolving the preprocessed and epoched EEG data with a set of complex
% Morlet wavelets, defined as complex sine waves tapered by a Gaussian. The frequencies of the wavelets ranged from
% 2 Hz to 40 Hz in 42 linearly spaced steps. The width of the Gaussian ranged from 3 to 15 cycles with linearly
% increasing wavelet peak frequency. An estimate of total power at each time point and frequency for each
% experimental condition was computed by squaring the absolute value of the complex signal and averaging over trials.
% Power was then normalized using a decibel (dB) transformation where the baseline activity was the average power of
% both experimental conditions combined from −500 to -200 ms prior to event onset. This process resulted in a
% time-frequency map for each EEG electrode and condition for each subject.

% This script was used on data produced by the script epochingForTFA.m

% This script is heavily based on the work of
% Mike X Cohen (https://mikexcohen.com/), especially the book "Analyzing
% neural time series data (2014)" and https://www.udemy.com/course/solved-challenges-ants


%% Soft-code parameters:
freqrange   = [2 40]; % Frequency range [min max] Hz
numfrex     = 42;     % number of frequency steps

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

%% Time-frequency analysis

% Loop over hypotheses 2, 3, and 4
for hypothesis = 2:4
    % Loop over all subjects
    for sub = 1:length(lists.subjectList)

        %% Load current subject
        subject      = lists.subjectList{sub};
        subject      = extractBefore(subject, fileExt);
        if hypothesis == 2
            fileName = [subject '_preprocessed_hypothesis2.set'];
        elseif hypothesis == 3
            fileName = [subject '_preprocessed_hypothesis3.set'];
        else
            fileName = [subject '_preprocessed_hypothesis4.set'];
        end
        subjFolder   = lists.subjFolderPaths(sub).subjFolderPaths;

        % Load current dataset into EEGLAB
        EEG = pop_loadset('filename',fileName, ...
            'filepath', subjFolder);
        EEG.data = double(EEG.data);

        % Condition indices - generated from epoching script
        if hypothesis == 2
            nCond1   = EEG.etc.epochingForTFA.hypothesis2.cond1NrOfEvents;
            nCond2   = EEG.etc.epochingForTFA.hypothesis2.cond2NrOfEvents;
        elseif hypothesis == 3
            nCond1   = EEG.etc.epochingForTFA.hypothesis3.cond1NrOfEvents;
            nCond2   = EEG.etc.epochingForTFA.hypothesis3.cond2NrOfEvents;
        else
            nCond1   = EEG.etc.epochingForTFA.hypothesis4.cond1NrOfEvents;
            nCond2   = EEG.etc.epochingForTFA.hypothesis4.cond2NrOfEvents;
        end

        cond1Idx = 1:nCond1;
        cond2Idx = length(cond1Idx)+1:EEG.trials;

        % parameters for post-analysis temporal downsampling
        times2save = -250:25:1250; % in ms (40 Hz)
        tidx       = dsearchn(EEG.times',times2save');

        % baseline time window (-500 to -200 ms)
        baseidx = dsearchn(EEG.times',[-500 -200]');

        %% Create a family of complex Morlet Wavelets

        % set up convolution parameters
        frex    = linspace(freqrange(1),freqrange(2),numfrex);
        wavtime = -2:1/EEG.srate:2; % length(wavtime) is odd (and symmetric around 0)
        nData   = EEG.pnts*EEG.trials;
        nKern   = length(wavtime);
        nConv   = nData + nKern -1;
        halfwav = (length(wavtime)-1)/2;
        nCycles = linspace(3,15,numfrex); % number of cycles
        % nCycles  = logspace(log10(4),log10(15),numfrex);
        % fwhms    = linspace(.5,.3,numfrex);

        % create wavelets
        cmwX = zeros(numfrex,nConv);
        for fi=1:numfrex

            % create time-domain wavelet
            s   = nCycles(fi)/(2*pi*frex(fi)); % frequency-normalized width of Gaussian
            cmw = exp(2*1i*pi*frex(fi).*wavtime) .* exp( (-wavtime.^2) ./ (2*s^2) );

            % compute fourier coefficients of wavelet and (max-value) normalize
            cmwX(fi,:) = fft(cmw,nConv);
            cmwX(fi,:) = cmwX(fi,:) ./ max(cmwX(fi,:));
        end
        %plot(wavtime,real(cmw),wavtime,imag(cmw),wavtime,abs(cmw))
        %% Time-frequency decomposition

        % initialize time-frequency output matrices (chans x frex x time x measure)
        tfCond1 = zeros(EEG.nbchan,numfrex,length(tidx),3);
        tfCond2 = zeros(EEG.nbchan,numfrex,length(tidx),3);

        % loop over channels
        for chani=1:EEG.nbchan

            % compute nConv-point Fourier coefficients of EEG data (reshaped into a "super-trial" to increase speed)
            dataX = fft( reshape(EEG.data(chani,:,:),1,[]) ,nConv);

            % loop over frequencies
            for fi=1:numfrex

                % Convolution data and wavelet + inverse transform
                as = ifft( cmwX(fi,:) .* dataX ,nConv );

                % cut wavelet back to size of data ("clip wings")
                as = as(halfwav+1:end-halfwav);
                as = reshape(as, EEG.pnts, EEG.trials); % reshape back to timepoints-by-trials

                % Baseline power from the conditions combined ("Condition average baseline")
                powts   = mean(abs(as).^2,2); % power time-series averaged over trials
                basepow = mean(powts(baseidx(1):baseidx(2))); %plot(EEG.times,powts)

                % Power time-series for each condition
                powtsCond1 = mean(abs(as(:,cond1Idx)).^2,2); % avg over condition 1 trials
                powtsCond2 = mean(abs(as(:,cond2Idx)).^2,2); % avg over condition 2 trials

                % extract power and phase-angle time-series (ITPC) for condition 1
                tfCond1(chani,fi,:,1) = powtsCond1(tidx); % power as amplitude^2 (uV^2). Also called total power
                tfCond1(chani,fi,:,2) = 10*log10( powtsCond1(tidx) / basepow ); % dB
                tfCond1(chani,fi,:,3) = abs(mean( exp(1i*angle(as(tidx,cond1Idx))) ,2)); % ITPC: magnitude of average phase vector (unit normalized)
                % inter-trial phase clustering (ITPC) describes the
                % consistency of the phase angles across trials (note: sensitive to nr of trials)

                % extract power and phase-angle time-series (ITPC) for condition 2
                tfCond2(chani,fi,:,1) = powtsCond2(tidx); % uV^2
                tfCond2(chani,fi,:,2) = 10*log10( powtsCond2(tidx) / basepow ); % dB
                tfCond2(chani,fi,:,3) = abs(mean( exp(1i*angle(as(tidx,cond2Idx))) ,2)); % ITPC

            end % end frequency loop
        end % end channel loop

        % Add time-frequency data to EEG structure
        if hypothesis == 2
            EEG.TFA.hypo2.tfCond1 = tfCond1;
            EEG.TFA.hypo2.tfCond2 = tfCond2;
            EEG.TFA.hypo2.nCond1  = nCond1;
            EEG.TFA.hypo2.nCond2  = nCond2;
        elseif hypothesis == 3
            EEG.TFA.hypo3.tfCond1 = tfCond1;
            EEG.TFA.hypo3.tfCond2 = tfCond2;
            EEG.TFA.hypo3.nCond1  = nCond1;
            EEG.TFA.hypo3.nCond2  = nCond2;
        else
            EEG.TFA.hypo4.tfCond1 = tfCond1;
            EEG.TFA.hypo4.tfCond2 = tfCond2;
            EEG.TFA.hypo4.nCond1  = nCond1;
            EEG.TFA.hypo4.nCond2  = nCond2;
        end

        % Save time-frequency decomposed data for this subject
        EEG.setname = [EEG.setname '_TFA'];
        EEG = pop_saveset(EEG, ...
            'filename', EEG.setname, ...
            'filepath', subjFolder);

        %% Plots
        %% Time-Frequency plot
        % Loop over conditions plot
        for i=1:2
            chan2plot = 11;
            colormap jet
            figure(i), clf

            plotName = [subjFolder filesep 'Hypothesis_' num2str(hypothesis) '_TFA_condition_' num2str(i) '.png']; 
            
            if i == 1
                subplot(311) % This can be removed, I just wanted to see effect of baseline normalization
                contourf(times2save,frex,squeeze(tfCond1(chan2plot,:,:,1)),40,'linecolor','none')
                xlabel('Time (s)'), ylabel('Frequencies (Hz)'), title([ 'Power (non-normalized) from all trials at channel ' num2str(chan2plot) ])
                set(gca,'xlim',[times2save(1) times2save(end)])
                a = colorbar;
                a.Label.String = 'Power (\muV^2)';
                xline(0,'k:','LineWidth', 2);

                subplot(312)
                contourf(times2save,frex,squeeze(tfCond1(chan2plot,:,:,2)),40,'linecolor','none')
                xlabel('Time (s)'), ylabel('Frequencies (Hz)'), title([ 'Power (dB) from all trials at channel ' num2str(chan2plot) ])
                set(gca,'xlim',[times2save(1) times2save(end)], 'clim',[-1 1]*3)
                b = colorbar;
                b.Label.String = 'Power (10*log10(\muV^2 / baseline))';
                xline(0,'k:','LineWidth', 2);

                subplot(313)
                contourf(times2save,frex,squeeze(tfCond1(chan2plot,:,:,3)),40,'linecolor','none')
                xlabel('Time (s)'), ylabel('Frequencies (Hz)'), title([ 'ITPC at channel ' num2str(chan2plot) ])
                set(gca,'xlim',[times2save(1) times2save(end)])
                c = colorbar;
                c.Label.String = 'Magnitude';
                xline(0,'k:','LineWidth', 2);

                sgtitle(['Time-frequency Analysis for condition ' num2str(i)])
                colormap jet
                saveas(gcf, plotName)
            else
                subplot(311) % This can be removed, I just wanted to see effect of baseline normalization
                contourf(times2save,frex,squeeze(tfCond2(chan2plot,:,:,1)),40,'linecolor','none')
                xlabel('Time (s)'), ylabel('Frequencies (Hz)'), title([ 'Power (non-normalized) from all trials at channel ' num2str(chan2plot) ])
                set(gca,'xlim',[times2save(1) times2save(end)])
                a = colorbar;
                a.Label.String = 'Power (\muV^2)';
                xline(0,'k:','LineWidth', 2);

                subplot(312)
                contourf(times2save,frex,squeeze(tfCond2(chan2plot,:,:,2)),40,'linecolor','none')
                xlabel('Time (s)'), ylabel('Frequencies (Hz)'), title([ 'Power (dB) from all trials at channel ' num2str(chan2plot) ])
                set(gca,'xlim',[times2save(1) times2save(end)], 'clim',[-1 1]*3)
                b = colorbar;
                b.Label.String = 'Power (10*log10(\muV^2 / baseline))';
                xline(0,'k:','LineWidth', 2);

                subplot(313)
                contourf(times2save,frex,squeeze(tfCond2(chan2plot,:,:,3)),40,'linecolor','none')
                xlabel('Time (s)'), ylabel('Frequencies (Hz)'), title([ 'ITPC at channel ' num2str(chan2plot) ])
                set(gca,'xlim',[times2save(1) times2save(end)])
                c = colorbar;
                c.Label.String = 'Magnitude';
                xline(0,'k:','LineWidth', 2);

                sgtitle(['Time-frequency Analysis for condition ' num2str(i)])
                colormap jet
                saveas(gcf, plotName)

            end % end if-else
        end % end for loop


        %% View one channel and topoplot at a time
        % human-readable terms
        chan2plot = 'Pz'; % channel label
        time2plot = [ 200 400 600 800 ]; % in ms
        freq2plot =  12; % in hz

        % indices
        chanidx = strcmpi(chan2plot,{EEG.chanlocs.labels});
        timeidx = dsearchn(times2save',time2plot');
        freqidx = dsearchn(frex',freq2plot);

        % plot time-frequency plot and topoplot
        for j = 1:2
            h = figure(j+2);clf
            colormap jet
            if j == 1
                subplot(3,2,[1,2])
                contourf(times2save,frex,squeeze(tfCond1(chanidx,:,:,2)),40,'linecolor','none')
                set(gca,'xlim',[times2save(1) times2save(end)], 'clim',[-1 1]*3)
                title([ 'TF power from channel ' chan2plot ])
                colorbar

                for q = 1:4
                    subplot(3,2,q+2)
                    topoplotIndie(squeeze(tfCond1(:,freqidx,timeidx(q))),EEG.chanlocs);
                    title([ 'Topo at ' num2str(time2plot(q)) ' ms, ' num2str(freq2plot) ' Hz' ])
                    colorbar
                    set(gca,'clim',[-1 1]*3)
                end
                sgtitle(h,['Condition ' num2str(j) ': Topoplots for channel ' num2str(chan2plot) ' (' num2str(freq2plot) ' Hz)'])
                plotName1 = [subjFolder filesep 'Hypothesis_' num2str(hypothesis) '_TFATopoplots_condition_' num2str(j) '.png'];
                saveas(h, plotName1)
            else
                subplot(3,2,[1,2])
                contourf(times2save,frex,squeeze(tfCond2(chanidx,:,:,2)),40,'linecolor','none')
                set(gca,'xlim',[times2save(1) times2save(end)], 'clim',[-1 1]*3)
                title([ 'TF power from channel ' chan2plot ])
                colorbar

                for q = 1:4
                    subplot(3,2,q+2)
                    topoplotIndie(squeeze(tfCond2(:,freqidx,timeidx(q))),EEG.chanlocs);
                    title([ 'Topo at ' num2str(time2plot(q)) ' ms, ' num2str(freq2plot) ' Hz' ])
                    colorbar
                    set(gca,'clim',[-1 1]*3)
                end
                sgtitle(h,['Condition ' num2str(j) ': Topoplots for channel ' num2str(chan2plot) ' (' num2str(freq2plot) ' Hz)'])
                plotName2 = [subjFolder filesep 'Hypothesis_' num2str(hypothesis) '_TFATopoplots_condition_' num2str(j) '.png'];
                saveas(h, plotName2)
            end % end if-else
        end % end for loop

    end % end subject loop
end % end hypothesis loop
fprintf('\n\n\n**** TFA finished ****\n\n\n');


% Some notes
% %tfviewerx(times2save,frex,tfCond1(:,:,:,2),EEG.chanlocs,'Time-frequency power');
% 
% 
% % Plot one example Morlet wavelet (max Hz in this case)
% figure(2), clf, hold on
% plot(wavtime,real(cmw),'b')
% plot(wavtime,imag(cmw),'r')
% plot(wavtime,abs(cmw),'k') % Analytic envelope
% xlim([-.4 .4])
% legend({'real';'imag';'abs'})
% title([ 'numcyc wavelet at ' num2str(frex(fi)) ' Hz' ])
% 


% plot power time-series for a channel and a frequency
% e.g. plot(EEG.times(tidx),squeeze(tf(1,10,:,2)))

