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
% CREATE FOLDER TO SAVE FILES IN
if ~exist('EEG_TFA', 'dir')
    mkdir EEG_Preprocessed EEG_TFA;
end

% DEFINE THE SET OF SUBJECTS THAT WERE ETHICALLY APPROVED
subject_list = {'sub-002', 'sub-005', 'sub-006', 'sub-008', 'sub-009', ...
    'sub-011', 'sub-013', 'sub-014', 'sub-015', 'sub-019', ...
    'sub-020', 'sub-021', 'sub-022', 'sub-025', 'sub-027', ...
    'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

% PATH TO THE EEG AND PREPROCESSED FOLDERS
eegfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\';
final = [ eegfolder 'EEG_Preprocessed'];


%% TIME-FRQUENCY ANALYSIS

% ELECTRODE CLUSTERS
nchans_left = [9 11 13 15]; % LEFT = [AF3 F7 F5 F3]
nchans_right = [10 12 14 16]; % RIGHT = [AF4 F8 F6 F4]

for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED EO AND EC DATA
    EEG_EO = pop_loadset('filename',[subject '_EO_Preprocessed.set'],'filepath', final);
    EEG_EC = pop_loadset('filename',[subject '_EC_Preprocessed.set'],'filepath', final);
    
    % COMPUTE THE POWER SPECTAL DENSITY (PSD) OF THE EPOCHS AT LEFT ELECTRODES
    [EC_spect_left, EC_freq_left] = spectopo(EEG_EC.data(nchans_left, :), ...
        EEG_EC.pnts, EEG_EC.srate, ...
        'chanlocs', EEG_EC.chanlocs, ...
        'freqrange', [8 13] ...
        'plot', off);
    [EO_spect_left, EO_freq_left] = spectopo(EEG_EO.data(nchans_left, :), ...
        EEG_EO.pnts, EEG_EO.srate, ...
        'chanlocs', EEG_EO.chanlocs, ...
        'freqrange', [8 13] ...
        'plot', off);

    % COMPUTE THE POWER SPECTAL DENSITY (PSD) OF THE EPOCHS AT RIGHT ELECTRODES
    [EC_spect_right, EC_freq_right] = spectopo(EEG_EC.data(nchans_right, :), ...
        EEG_EC.pnts, EEG_EC.srate, ...
        'chanlocs', EEG_EC.chanlocs, ...
        'freqrange', [8 13] ...
        'plot', off);
    [EO_spect_right, EO_freq_right] = spectopo(EEG_EO.data(nchans_right, :), ...
        EEG_EO.pnts, EEG_EO.srate, ...
        'chanlocs', EEG_EO.chanlocs, ...
        'freqrange', [8 13] ...
        'plot', off);
    
end

% HOW TO CLUSTER ELECTRODES? MEAN OF ALL 4 ELECTRODES?

%------------------------------------------------------------
% https://sccn.ucsd.edu/pipermail/eeglablist/2012/004511.html
% https://sccn.ucsd.edu/pipermail/eeglablist/2010/003550.html
% https://sccn.ucsd.edu/pipermail/eeglablist/2014/008043.html
% https://sccn.ucsd.edu/~arno/eeglab/auto/spectopo.html
% https://download.ni.com/evaluation/pxi/Understanding%20FFTs%20and%20Windowing.pdf

% CONSIDER MEDIAL, LATERAL, AND MID FRONTAL CLUSTERS TOO. LATER.


%    'wintype'  = ['hamming','blackmanharris'] Window type used on the power spectral 
%                  density estimation. The Blackman-Harris windows offers better attenuation
%                  than Hamming windows, but lower spectral resolution. {default: 'hamming'}

%    'overlap'  = [integer] window overlap in data points {default: 0}
% DO I NEED OVERLAP?

%    'nfft'     = [integer] Data points to zero-pad data windows to (overwrites 'freqfac')
%           Do I need this?


% newtimef() for event-related.

% GOOGLE "eeg alpha asymmetry site:sccn.ucsd.edu/pipermail/eeglablist/"