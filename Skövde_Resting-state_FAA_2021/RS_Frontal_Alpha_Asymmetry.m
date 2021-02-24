% SET VARIABLE TO 1 TO SAVE INTERMEDIATE STEPS. SET TO 0 TO SAVE
% ONLY THE NECESSARY FILES (RAW RS, EPOCHED EO AND EC, FINAL).
save_everything = 1;

% SET EEGLAB PREFERENCES
pop_editoptions( 'option_storedisk', 1);
pop_editoptions( 'option_single', 0);

%% SET UP FILES AND FOLDERS

% MAKE SURE EEGLAB IS IN PATH
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2020_0')
% WORKING DIRECTORY
cd 'D:\FAA_Study_2021\Skovde\Skovde_EEG'

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

%% CONVERSION INTO FREQUENCY DOMAIN

% ELECTRODE CLUSTERS
nchans_left = [9 11 13 15]; % LEFT = [AF3 F7 F5 F3]
nchans_right = [10 12 14 16]; % RIGHT = [AF4 F8 F6 F4]


for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED EO AND EC DATASETS
    EEG_EO = pop_loadset('filename',[subject '_EO_Preprocessed.set'],'filepath', final);
    EEG_EC = pop_loadset('filename',[subject '_EC_Preprocessed.set'],'filepath', final);
    
    % CREATE LEFT AND RIGHT ELECTRODE CLUSTERS
    EO_eleclust_left = mean(EEG_EO.data(nchans_left,:,:),1);
    EO_eleclust_right = mean(EEG_EO.data(nchans_right,:,:),1); 
    EC_eleclust_left = mean(EEG_EC.data(nchans_left,:,:),1);
    EC_eleclust_right = mean(EEG_EC.data(nchans_right,:,:),1);

    
    % COMPUTE THE POWER SPECTAL DENSITY (PSD) OF THE EPOCHS AT LEFT ELECTRODES
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

    % COMPUTE THE POWER SPECTAL DENSITY (PSD) OF THE EPOCHS AT RIGHT ELECTRODES
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
    
    alphaindex = find(freqs >= 8 & freqs <= 13); % FREQUENCY RANGE 8-13 Hz
    
    % MEAN ALPHA POWER (uV^2) LEFT ELECTRODE CLUSTER FOR EO AND EC
    EO_alphapower_L(s,1) = 10^(mean(EO_spect_L(alphaindex))/10); 
    EC_alphapower_L(s,1) = 10^(mean(EC_spect_L(alphaindex))/10); 
    
    % MEAN ALPHA POWER (uV^2) RIGHT ELECTRODE CLUSTER FOR EO AND EC
    EO_alphapower_R(s,1) = 10^(mean(EO_spect_R(alphaindex))/10); 
    EC_alphapower_R(s,1) = 10^(mean(EC_spect_R(alphaindex))/10); 
    
    % ALPHA ASYMMETRY SCORES EO AND EC
    EO_asymmetry(s,1) = log(EO_alphapower_R(s,1)) - log(EO_alphapower_L(s,1));
    EC_asymmetry(s,1) = log(EC_alphapower_R(s,1)) - log(EC_alphapower_L(s,1));
    
    % IS THIS MEAN ALPHA POWER (dB)?
    meanalpha = 10^(mean(EO_spect_R(alphaindex))/10); 
    
    % DON'T I NEED AT LEAST THE STD TO DO SOME STATISTICS?
    % AVERAGE POWER SPECTRA FOR EACH SITE
    
    % CALCULATE ALPHA POWER, EITHER BY SUMMING ALL SPECTRAL POINTS IN THE
    % FREQUENCY RANGE (TOTAL) OR SUMMING THE SPECTRAL POINTS AND DIVIDING
    % BY THE RANGE IN HZ (DENSITY).
    
    % LOG TRANSFORM ALPHA POWER AT ANY GIVEN SITE.
    % CALCULATE DIFFERENCE SCORE ln(power_left) - ln(power_right).
    
    % SAVE DATA
%     EEG_EO = pop_saveset(EEG_EO, ...
%          'filename',[subject '_EO_Spectopo.set'], ...
%          'filepath', tfadir);
%      EEG_EC = pop_saveset(EEG_EC, ...
%          'filename',[subject '_EC_Spectopo.set'], ...
%          'filepath', tfadir);
%     
end

% SAVE NECESSARY INFORMATION (E.G ASYMMETRY SCORES)
cd D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_Preprocessed\EEG_TFA
save EO_AsymmetryScores EO_asymmetry
save EC_AssymetryScores EC_asymmetry

fprintf('\n\n\n**** FINISHED ****\n\n\n');

%------------------------------------------------------------
% https://sccn.ucsd.edu/pipermail/eeglablist/2012/004511.html
% https://sccn.ucsd.edu/pipermail/eeglablist/2010/003550.html
% https://sccn.ucsd.edu/pipermail/eeglablist/2014/008043.html
% https://sccn.ucsd.edu/~arno/eeglab/auto/spectopo.html
% https://download.ni.com/evaluation/pxi/Understanding%20FFTs%20and%20Windowing.pdf
% https://community.sw.siemens.com/s/article/what-is-a-power-spectral-density-psd
% ERSP https://sccn.ucsd.edu/pipermail/eeglablist/2012/005254.html

% MAKOTO POWER: https://sccn.ucsd.edu/wiki/Makoto's_useful_EEGLAB_code#How_to_add_an_electrode_.2802.2F18.2F2021.29
% NOT SURE I HAVE CALCULATED POWER CORRECTLY. OUTPUT IN dB


% CONSIDER MEDIAL, LATERAL, AND MID FRONTAL CLUSTERS TOO. LATER.


%    'wintype'  = ['hamming','blackmanharris'] Window type used on the power spectral 
%                  density estimation. The Blackman-Harris windows offers better attenuation
%                  than Hamming windows, but lower spectral resolution. {default: 'hamming'}

%    'overlap'  = [integer] window overlap in data points {default: 0}
% DO I NEED OVERLAP?

%    'nfft'     = [integer] Data points to zero-pad data windows to (overwrites 'freqfac')
%           Do I need this?


% newtimef() for event-related.

% output: spectra  = (nchans,nfreqs) power spectra (mean power over epochs), in dB
% GOOGLE "eeg alpha asymmetry site:sccn.ucsd.edu/pipermail/eeglablist/"
