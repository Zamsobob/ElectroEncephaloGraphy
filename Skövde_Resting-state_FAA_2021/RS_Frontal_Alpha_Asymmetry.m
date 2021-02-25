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

%% FREQUENCY DECOMPOSITION

% ELECTRODE CLUSTERS
nchans_left = [9 11 13 15]; % LEFT = [AF3 F7 F5 F3]
nchans_right = [10 12 14 16]; % RIGHT = [AF4 F8 F6 F4]

% INITIALIZING VARIABLES
EO_alphapower_L = zeros(numsubjects, 1);
EC_alphapower_L = zeros(numsubjects, 1); 
EO_alphapower_R = zeros(numsubjects, 1);
EC_alphapower_R = zeros(numsubjects, 1);

EO_asymmetry = zeros(numsubjects, 1);
EC_asymmetry = zeros(numsubjects, 1);

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
    
    % ALPHA POWER (uV^2/Hz) LEFT ELECTRODE CLUSTER FOR EO AND EC
    EO_alphapower_L(s,1) = mean(10.^(EO_spect_L(alphaindex)/10));
    EC_alphapower_L(s,1) = mean(10.^(EC_spect_L(alphaindex)/10));
    
    % ALPHA POWER (uV^2/Hz) RIGHT ELECTRODE CLUSTER FOR EO AND EC
    EO_alphapower_R(s,1) = mean(10.^(EO_spect_R(alphaindex)/10));
    EC_alphapower_R(s,1) = mean(10.^(EC_spect_R(alphaindex)/10));
    
    % ALPHA ASYMMETRY SCORES EO AND EC
    EO_asymmetry(s,1) = log(EO_alphapower_R(s,1)) - log(EO_alphapower_L(s,1));
    EC_asymmetry(s,1) = log(EC_alphapower_R(s,1)) - log(EC_alphapower_L(s,1));
    
    
    % DIVIDING BY 10 (Hz) IN POWER CALCULATION SO THAT POWER IS
    % IN (uV^2/Hz). REMOVE 10 TO HAVE uV^2 INSTEAD. BOTH SHOULD WORK.
    
    % DON'T I NEED AT LEAST THE STD TO DO SOME STATISTICS?
      
end

% GROUP FAA SCORES
EO_Group_FAA_Score = mean(EO_asymmetry(:,1)); % SUM? SOMETHING ELSE?
EC_Group_FAA_Score = mean(EC_asymmetry(:,1)); % THINK IT'S MEAN

% SAVE NECESSARY INFORMATION (E.G ASYMMETRY SCORES)
cd D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_Preprocessed\EEG_TFA
save EO_AsymmetryScores EO_asymmetry
save EC_AssymetryScores EC_asymmetry
save EO_GroupFAAScores EO_Group_FAA_Score
save EC_GroupFAAScores EC_Group_FAA_Score

fprintf('\n\n\n**** FINISHED ****\n\n\n');


% clim = [-2 2];
% figure; imagesc(times, freqs, EO_Group_FAA_Score, clim);
% line([0 0], [0 50]) % line at 0 ms
% set(gca,'Ydir','normal')
% title('group')
% xlabel('time (ms)')
% ylabel('frequency')
% colorbar;
