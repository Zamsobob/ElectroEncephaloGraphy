%% All electrodes
% Standard deviations?
% Loop for EO and EC?

%% SET UP FILES AND FOLDERS

% MAKE SURE EEGLAB IS IN PATH
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2020_0');
% WORKING DIRECTORY
cd 'D:\FAA_Study_2021\Skovde\Skovde_EEG'

% SET EEGLAB PREFERENCES
pop_editoptions( 'option_storedisk', 1);
pop_editoptions( 'option_single', 0);

% PATH TO THE NECESSARY FOLDERS
eegfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\';
rawfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_RAW\';
final = [ eegfolder 'EEG_Preprocessed'];

% CREATE FOLDER TO SAVE FILES IN
if ~exist('EEG_TFA', 'dir')
    mkdir EEG_Preprocessed EEG_TFA;
end
tfadir = [final filesep 'EEG_TFA'];

% DEFINE THE SET OF SUBJECTS THAT WERE ETHICALLY APPROVED
subject_list = {'sub-002', 'sub-005', 'sub-006', 'sub-008', 'sub-009', ...
    'sub-011', 'sub-013', 'sub-014', 'sub-015', 'sub-019', ...
    'sub-020', 'sub-021', 'sub-022', 'sub-025', 'sub-027', ...
    'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

% INITIALIZE VARIABLES FOR ANALYSING ALL FRONTAL ELECTRODES
numelectrodes = 27; % NUMBER OF ELECTRODES IN DATASET
numelecpairs = 4; % NUMBER OF ELECTRODE PAIRS TO COMPARE (E.G., F3/F4)
nchans = 9:2:16; % VECTOR OF ALL ELECTRODES (LEFT & RIGHT) TO COMPARE
EO_alphapower = zeros(numelectrodes, numsubjects); % EO ALPHA POWER
EC_alphapower = zeros(numelectrodes, numsubjects); % EC ALPHA POWER
EO_asymmetry = zeros(numelecpairs, numsubjects); % EO FAA SCORES
EC_asymmetry = zeros(numelecpairs, numsubjects); % EC FAA SCORES

% INITIALIZING VARIABLES FOR ANALYSIS OF LEFT AND RIGHT ELECTRODE CLUSTERS
EO_alphapower_L = zeros(1, numsubjects); % EO ALPHA POWER LEFT CLUSTER
EC_alphapower_L = zeros(1, numsubjects); % EC ALPHA POWER LEFT CLUSTER
EO_alphapower_R = zeros(1, numsubjects); % EO ALPHA POWER RIGHT CLUSTER
EC_alphapower_R = zeros(1, numsubjects); % EO ALPHA POWER RIGHT CLUSTER

EO_asymmetry_clust = zeros(1, numsubjects); % EO FAA SCORES CLUSTERS
EC_asymmetry_clust = zeros(1, numsubjects); % EC FAA SCORES CLUSTERS

% ELECTRODE CLUSTERS
nchans_left = [9 11 13 15]; % LEFT = [AF3 F7 F5 F3]
nchans_right = [10 12 14 16]; % RIGHT = [AF4 F8 F6 F4]

%% FREQUENCY DECOMPOSITION

% LOOP THROUGH ALL SUBJECTS
for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED EO AND EC DATASETS
    EEG_EO = pop_loadset('filename',[subject '_EO_Preprocessed.set'],'filepath', final);
    EEG_EC = pop_loadset('filename',[subject '_EC_Preprocessed.set'],'filepath', final);
   
    %% ANALYSIS OF ALL CHANNELS
    
    % COMPUTE POWER SPECTAL DENSITY (PSD) OF THE EPOCHS FOR ALL CHANNELS
    [EO_spect, freqs] = spectopo(EEG_EO.data, ...
        EEG_EO.pnts, EEG_EO.srate, ...
        'chanlocs', EEG_EO.chanlocs, ...
        'freqfac', 2, ...
        'plot', 'off'); 
    [EC_spect, freqs] = spectopo(EEG_EC.data, ...
        EEG_EC.pnts, EEG_EC.srate, ...
        'chanlocs', EEG_EC.chanlocs, ...
        'freqfac', 2, ...
        'plot', 'off');
    
    % OUTPUT IS IN dB -> 10*log10(uV^2/Hz)
    
    % CONVERT TO ALPHA POWER (uV^2/Hz) AND AVERAGE ACROSS FREQUENCIES
    
    alphaindex = find(freqs >= 8 & freqs <= 13); % FREQUENCY RANGE 8-13 Hz
    
    % CREATE CHANNEL X SUBEJCT MATRIX OF MEAN ALPHA POWER
    for electrode = 1:numelectrodes  
        EO_alphapower(electrode, s) = mean(10.^(EO_spect(electrode, alphaindex)/10));
        EC_alphapower(electrode, s) = mean(10.^(EC_spect(electrode, alphaindex)/10));
    end
    
    % CREATE MATRIX OF ASYMMETRY SCORES. ROWS ARE ELECTRODE PAIRS AF3-AF4,
    % F3-F4, F5-F6, AND F7-F8. COLUMNS ARE SUBJECTS
    for i = 1:numelecpairs
        EO_asymmetry(i, s) = log(EO_alphapower(nchans(i),s)) - log(EO_alphapower(nchans(i)+1,s));
        EC_asymmetry(i, s) = log(EC_alphapower(nchans(i),s)) - log(EC_alphapower(nchans(i)+1,s));
    end
 
    %% ANALYSIS OF LEFT AND RIGHT ELECTRODE CLUSTERS
    
    % CREATE LEFT AND RIGHT ELECTRODE CLUSTERS
    EO_eleclust_left = mean(EEG_EO.data(nchans_left,:,:),1);
    EO_eleclust_right = mean(EEG_EO.data(nchans_right,:,:),1); 
    EC_eleclust_left = mean(EEG_EC.data(nchans_left,:,:),1);
    EC_eleclust_right = mean(EEG_EC.data(nchans_right,:,:),1);
    
    % COMPUTE PSD OF THE EPOCHS AT LEFT ELECTRODE CLUSTER
    [EO_spect_L, freqs] = spectopo(EO_eleclust_left, ...
        EEG_EO.pnts, EEG_EO.srate, ...
        'chanlocs', EEG_EO.chanlocs, ...
        'freqfac', 2, ...
        'plot', 'off'); 
    [EC_spect_L, freqs] = spectopo(EC_eleclust_left, ...
        EEG_EC.pnts, EEG_EC.srate, ...
        'chanlocs', EEG_EC.chanlocs, ...
        'freqfac', 2, ...
        'plot', 'off');

    % COMPUTE PSD OF THE EPOCHS AT RIGHT ELECTRODE CLUSTER
    [EO_spect_R, freqs] = spectopo(EO_eleclust_right, ...
        EEG_EO.pnts, EEG_EO.srate, ...
        'chanlocs', EEG_EO.chanlocs, ...
        'freqfac', 2, ...
        'plot', 'off');
    [EC_spect_R, freqs] = spectopo(EC_eleclust_right, ...
        EEG_EC.pnts, EEG_EC.srate, ...
        'chanlocs', EEG_EC.chanlocs, ...
        'freqfac', 2, ...
        'plot', 'off');
    
    % OUTPUT IS IN dB -> 10*log10(uV^2/Hz)
    
    % CONVERT TO ALPHA POWER (uV^2/Hz) AND AVERAGE ACROSS FREQUENCIES
    
    % ALPHA POWER LEFT ELECTRODE CLUSTER FOR EO AND EC
    EO_alphapower_L(1,s) = mean(10.^(EO_spect_L(alphaindex)/10));
    EC_alphapower_L(1,s) = mean(10.^(EC_spect_L(alphaindex)/10));
    
    % ALPHA POWER RIGHT ELECTRODE CLUSTER FOR EO AND EC
    EO_alphapower_R(1,s) = mean(10.^(EO_spect_R(alphaindex)/10));
    EC_alphapower_R(1,s) = mean(10.^(EC_spect_R(alphaindex)/10));
    
    
    % ALPHA ASYMMETRY SCORES EO AND EC
    EO_asymmetry_clust(1,s) = log(EO_alphapower_R(1,s)) - log(EO_alphapower_L(1,s));
    EC_asymmetry_clust(1,s) = log(EC_alphapower_R(1,s)) - log(EC_alphapower_L(1,s));
    
end

% EXPORT FILES TO EXCEL FOR STATISTICAL ANALYSIS
xlswrite('FAAscores', EO_alphapower, 'EO Alpha Power');
xlswrite('FAAscores', EC_alphapower, 'EC Alpha Power');
xlswrite('FAAscores', EO_asymmetry, 'EO Asymmetry Scores');
xlswrite('FAAscores', EC_asymmetry, 'EC Asymmetry Scores');

xlswrite('FAAscores', EO_alphapower_L, 'EO Alpha Power Left Cluster');
xlswrite('FAAscores', EO_alphapower_R, 'EO Alpha Power right Cluster');
xlswrite('FAAscores', EC_alphapower_L, 'EC Alpha Power Left Cluster');
xlswrite('FAAscores', EC_alphapower_R, 'EC Alpha Power right Cluster');
xlswrite('FAAscores', EO_asymmetry_clust, 'EO Cluster Asymmetry Scores');
xlswrite('FAAscores', EC_asymmetry_clust, 'EC Cluster Asymmetry Scores');

fprintf('\n\n\n**** FINISHED ****\n\n\n');

% PLOT POWER SPECTRUM. LOOP CAN BE USED TO MAKE SUBPLOTS
% CREATE BETTER PLOTS WITH SPECTOPO THOUGH LATER
figure
subplot(221)
bar(freqs, abs(EO_spect_L))
set(gca,'xlim',[-5 105])
xlabel('Frequency (Hz)')
ylabel('Log Power Spectral Density 10*log(uV^2/Hz)')
title('Power Spectra for Eyes Open Left Cluster')

subplot(222)
bar(freqs, abs(EO_spect_R))
set(gca,'xlim',[-5 105])
xlabel('Frequency (Hz)')
ylabel('Log Power Spectral Density 10*log(uV^2/Hz)')
title('Power Spectra for Eyes Open Right Cluster')

subplot(223)
bar(freqs, abs(EC_spect_L))
set(gca,'xlim',[-5 105])
xlabel('Frequency (Hz)')
ylabel('Log Power Spectral Density 10*log(uV^2/Hz)')
title('Power Spectra for Eyes Closed Left Cluster')

subplot(224)
bar(freqs, abs(EC_spect_R))
set(gca,'xlim',[-5 105])
xlabel('Frequency (Hz)')
ylabel('Log Power Spectral Density 10*log(uV^2/Hz)')
title('Power Spectra for Eyes Closed Right Cluster')


% EYES OPEN AND EYES CLOSED. COMBINE THEM? MIGHT NEED TO TEST FOR
% STATISTICAL DIFFERENCE BETWEEN THE CONDITIONS WITH T-TEST?
