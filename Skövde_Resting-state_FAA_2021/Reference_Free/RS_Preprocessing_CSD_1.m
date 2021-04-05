% CLEAR MEMORY AND THE COMMAND WINDOW
clear;
clc;

% SET VARIABLE TO 1 TO SAVE INTERMEDIATE STEPS. SET TO 0 TO SAVE
% ONLY THE NECESSARY FILES (RAW RS, EPOCHED EO AND EC, FINAL).
save_everything = 1;

%% SET UP FILES AND FOLDERS

% MAKE SURE EEGLAB IS IN PATH
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2021.0');
% WORKING DIRECTORY
cd 'D:\FAA_Study_2021\Skovde\Skovde_EEG'

% SET EEGLAB PREFERENCES
pop_editoptions('option_storedisk', 1);
pop_editoptions('option_single', 0);

% DEFINE THE SET OF SUBJECTS
subject_list = {'sub-002', 'sub-005', 'sub-006', 'sub-008', 'sub-009', ...
    'sub-011', 'sub-013', 'sub-014', 'sub-015', 'sub-019', ...
    'sub-020', 'sub-021', 'sub-022', 'sub-025', 'sub-027', ...
    'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

% PATH TO THE EEG AND RAW FOLDERS
eegfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\';
rawfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_RAW\';

%PATH TO LOCALIZER FILE (INCLUDES CHANNEL LOCATIONS)
localizer = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_Localizer\';

% CREATE FOLDERS FOR THE PREPROCESSED DATA
if~exist('EEG_CSD', 'dir')
    mkdir 'EEG_CSD'
end
csdfolder = [eegfolder 'EEG_CSD\'];
cd 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_CSD'

if ~exist('EEG_RS', 'dir')
    mkdir EEG_RS RS;
end
rsdir = [csdfolder 'EEG_RS\RS'];
    
if ~exist('EEG_SD', 'dir')
    mkdir EEG_SD SD;
end
sddir = [csdfolder 'EEG_SD\SD'];
    
if ~exist('RS_EO', 'dir')
    mkdir EEG_RS RS_EO
end
eodir = [csdfolder 'EEG_RS\RS_EO'];

if ~exist('RS_EC', 'dir')
    mkdir EEG_RS RS_EC
end
ecdir = [csdfolder 'EEG_RS\RS_EC'];

if ~exist('EEG_Preprocessed', 'dir')
    mkdir EEG_Preprocessed
end
final = [csdfolder 'EEG_Preprocessed'];

if ~exist('Saved_Variables', 'dir')
    mkdir Saved_Variables
end
%% LOADING RAW EEG RESTING-STATE DATA AND RELEVANT FILES

% LOOP THROUGH ALL SUBJECTS
parfor s = 1:numsubjects % CHANGE TO FOR IF PARALLEL COMPUTING TOOLBOX IS NOT INSTALLED
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % IMPORT RAW DATA
    EEG = pop_importdata('dataformat', 'matlab', 'nbchan', 35, ...
        'data',[subjectfolder subject '.mat'], ...
        'srate',512, ...
        'pnts',0, ...
        'xmin',0);
    
   % IMPORT EVENT INFORMATION (CHANNEL 18)
    EEG = pop_chanevent(EEG, 18, 'edge', 'leading', 'edgelen', 0);
    
    % REMOVE FIRST(G.TEC TIME) AND LAST (EMPTY) CHANNELS
    EEG = pop_select(EEG, 'nochannel', [1 34]);
    
    % IMPORT CHANNELS WITH Cz AS ONLINE REFERENCE. HEAD CENTER IS OPTIMIZED
    EEG = pop_chanedit(EEG, 'load', {[localizer 'Locations_32Channels_LM_RM.ced'], ...
        'filetype', 'autodetect'}, ...
        'changefield', {EEG.nbchan + 1, 'datachan', 0}, ...
        'setref', {[1:EEG.nbchan + 1], 'Cz'});
    
    % RESAMPLE DATASET FROM 512 TO 256 Hz
    % EEG = pop_resample(EEG, 256);
    
     %% EXTRACT RESTING-STATE (RS) AND STATE-DEPENDENT (SD) DATA
    % DEFINE WHERE TO SPLIT TRIALS. RS PERIOD ENDS AFTER 16TH EVENT.
    % SLIGHTLY DIFFERENT EVENTS FOR SUB-032 (ENDS AFTER EVENT 17)
    
    if s == 20 % SUB-032
        startpoint_RS = EEG.event(1).latency/EEG.srate; % FIRST EVENT RS
        endpoint_RS = EEG.event(17).latency/EEG.srate; % LAST EVENT RS
    
        startpoint_SD = EEG.event(57).latency/EEG.srate; % FIRST EVENT SD
        endpoint_SD = EEG.event(length(EEG.event)).latency; % LAST EVENT SD
        
    else % REST OF SUBJECTS
        startpoint_RS = EEG.xmin/EEG.srate; % FIRST EVENT RS
        endpoint_RS = EEG.event(16).latency/EEG.srate; % LAST EVENT RS
    
        startpoint_SD = EEG.event(56).latency/EEG.srate; % FIRST EVENT SD
        endpoint_SD = EEG.event(length(EEG.event)).latency; % LAST EVENT SD
        
    end

    % SELECT RS DATA AND SD DATA
    EEG_RS = pop_select(EEG,'time',[startpoint_RS endpoint_RS]);
    EEG_SD = pop_select(EEG,'time',[startpoint_SD endpoint_SD]);
    EEG_RS.setname = [subject '_RS']; % NAME FOR DATASET MENU
    EEG_SD.setname = [subject '_SD']; % NAME FOR DATASET MENU
    
    % SAVE RS AND SD DATA IN RS AND SD FOLDERS
    EEG_RS = pop_saveset(EEG_RS, 'filename',[subject '_RS.set'], ...
        'filepath', rsdir);
    EEG_SD = pop_saveset(EEG_SD, 'filename',[subject '_SD.set'], ...
        'filepath', sddir);
    
    %% PREPROCESSING
    
    % LOAD RS DATA
    EEG = pop_loadset('filename',[subject '_RS.set'],'filepath', rsdir);
    
    % HIGH-PASS FILTER 1 HZ. 827 POINTS. CUTOFF FREQUENCY (~6dB): 0.5 Hz.
    % ZERO-PHASE. NON-CAUSAL (FIRFILT).
    EEG = pop_eegfiltnew(EEG, 'locutoff',1);
    
    % LOW-PASS FILTER 45 HZ TO SUPPRESS POSSIBLE LINE NOISE. 75 points.
    % CUTOFF FREQUENCY (~6dB): 50.625 Hz. ZERO-PHASE, NON-CAUSAL (FIRFILT)
    EEG = pop_eegfiltnew(EEG, 'hicutoff',45);
    EEG.setname = [subject '_Filt']; % NAME FOR DATASET MENU
   
    % SAVE FILTERED DATA
    if (save_everything)
    EEG = pop_saveset(EEG, 'filename',[subject '_Filt'], ...
        'filepath', rsdir);
    end
    
    % SAVE ORIGINAL DATA BEFORE REMOVING BAD CHANNELS
    % originalchanlocs = EEG.chanlocs; % FOR INTERPOLATION LATER
    oldchans = {EEG.chanlocs.labels};
    
    % CLEAN_RAW DATA WITH CHANNEL REMOVAL AND ASR
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, ...
    'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, ...
    'Highpass', 'off', ...
    'BurstCriterion', 20, ...
    'WindowCriterion', 0.25, ...
    'availableRAM_GB', 8, ...
    'BurstRejection', 'on', ...
    'Distance', 'Euclidian', ...
    'WindowCriterionTolerances',[-Inf 7] );
    EEG.setname = [subject '_ASR']; % NAME FOR DATASET MENU
    
    % STORE REMOVED CHANNELS FOR REVIEW
    newchans = {EEG.chanlocs.labels}; % SAVE NEW EO CHANS AFTER CLEAN
    chandiff = setdiff(oldchans, newchans); % DIFFERENCE OLD AND NEW CHANNELS
    interchans(s) = {chandiff}; % STORE LIST OF INTERPOLATED CHANNELS FOR EACH SUBJECT

    % SAVE DATA
    if (save_everything)
        EEG = pop_saveset(EEG, 'filename',[subject '_ASR.set'], ...
            'filepath', rsdir);
    end
    
    %% RUN ICA ON ALL CHANNELS
    EEG = pop_runica(EEG, 'extended', 1, ...
        'interupt', 'on', ...
        'pca', length(EEG.chanlocs));
    EEG.setname = [subject '_ICA_Weights']; % NAME FOR DATASET MENU
    EEG = eeg_checkset(EEG, 'ica');
      
    % SAVE DATA WITH ICA WEIGHTS
    if (save_everything)
        EEG = pop_saveset(EEG, 'filename',[subject '_ICA_Weights.set'], ...
            'filepath', rsdir);
    end
end

% SAVE INTERPOLATED CHANNELS AS .MAT IN FOLDER Saved_Variables
cd 'Saved_Variables';
save InterpolatedChannels.mat interchans

fprintf('\n\n\n**** SKÖVDE PREPROCESSING 1 FINISHED ****\n\n\n');
