% CLEAR MEMORY AND THE COMMAND WINDOW
clear;
clc;

% MAKE SURE EEGLAB IS IN PATH
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2020_0')
% WORKING DIRECTORY SHOULD BE D:
cd 'D:\FAA_Study_2021\Skovde\Skovde_EEG'


% DEFINE THE SET OF SUBJECTS
% subject 24 missing. Cancelled participation?
% REMOVING SUB-002 TEMPORARILY. WHICH SHOULD I USE LATER AS I HAVE 2 FILES?
subject_list = {'sub-001', 'sub-003', 'sub-004', 'sub-005', ... 
    'sub-006', 'sub-007', 'sub-008', 'sub-009', 'sub-010', ... 
    'sub-011', 'sub-012', 'sub-013', 'sub-014', 'sub-015', ... 
    'sub-016', 'sub-017', 'sub-018', 'sub-019', 'sub-020', ... 
    'sub-021', 'sub-022', 'sub-023', 'sub-025', 'sub-026', ... 
    'sub-027', 'sub-028', 'sub-029', 'sub-030', 'sub-031', ... 
    'sub-032'};
numsubjects = length(subject_list);

% PATH TO THE EEG and RAW FOLDERS
eegfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\';
rawfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_RAW\';

%PATH TO LOCALIZER FILE (INCLUDES CHANNEL LOCATIONS)
localizer = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_Localizer\';

% CREATE FOLDERS FOR THE PREPROCESSED DATA
if ~exist('EEG_RS', 'dir')
    mkdir EEG_RS RS;
end
    rsdir = [ eegfolder 'EEG_RS\RS'];
    
if ~exist('EEG_SD', 'dir')
    mkdir EEG_SD SD;
end
    sddir = [ eegfolder 'EEG_SD\SD'];
    
if ~exist('RS_EO', 'dir')
    mkdir EEG_RS RS_EO
end
eodir = [ eegfolder 'EEG_RS\RS_EO'];

if ~exist('RS_EC', 'dir')
    mkdir EEG_RS RS_EC
end
ecdir = [ eegfolder 'EEG_RS\RS_EC'];

%% PREPROCESSING OF RAW DATA

% LOOP THROUGH ALL SUBJECTS
for s = 1 %:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [ rawfolder subject '\'];

    % IMPORT RAW DATA
    EEG = pop_importdata('dataformat', 'matlab', 'nbchan', 35, ...
        'data',[subjectfolder subject '.mat'], ...
        'srate',512, ...
        'pnts',0, ...
        'xmin',0);
    
    % IMPORT EVENT INFORMATION (CHANNEL 18)
    EEG = pop_chanevent(EEG, 18, 'edge', 'leading', 'edgelen', 0 );
    
    % REMOVE FIRST(G.TEC TIME) AND LAST (EMPTY) CHANNELS
    EEG = pop_select(EEG, 'nochannel', [1 34] );
    
    % IMPORT CHANNEL LOCATIONS AND OPTIMIZE HEAD CENTER
    EEG = pop_chanedit(EEG, ...
        'load',{[localizer 'Locations_32Channels.ced'] ...
        'filetype' ...
        'autodetect'},'eval', ...
        'chans = pop_chancenter( chans, [],[]);');
    
    % RE-REFERENCE TO LM RM (FOR NOW)
    EEG = pop_reref(EEG, [5 6] );
    
    % RESAMPLE DATASET FROM 512 TO 256 HZ
    EEG = pop_resample(EEG, 256);
    
    %% EXTRACT RESTING-STATE AND STATE-DEPENDENT DATA
    % DEFINE WHERE TO SPLIT DATASETS (RESTING-STATE AND STATE-DEPENDENT
    % TRIALS). RESTING-STATE PERIOD ENDS AFTER 16TH EVENT.
    % RS = RESTING-STATE
    % SD = STATE-DEPENDENT
    
    startPoint_RS = EEG.event(1).latency;
    startPoint_RS = startPoint_RS/EEG.srate;
    
    splitPoint_RS = EEG.event(16).latency;
    splitPoint_RS = splitPoint_RS/EEG.srate;

    splitPoint_SD = EEG.event(56).latency;
    splitPoint_SD = splitPoint_SD/EEG.srate;

    endPoint = length(EEG.event);
    endPoint_SD = EEG.event(endPoint).latency;

    % SELECT RS DATA AND SD DATA
    EEG_RSFAA = pop_select(EEG,'time',[startPoint_RS splitPoint_RS] );
    EEG_SDFAA = pop_select(EEG,'time',[splitPoint_SD endPoint_SD] );
    EEG_RSFAA.setname = [ subject '_RS']; % NAME FOR DATASET MENU
    EEG_SDFAA.setname = [ subject '_SD']; % NAME FOR DATASET MENU
    
    % SAVE RS AND SD DATA IN RS AND SD FOLDERS
    EEG_RSFAA = pop_saveset(EEG_RSFAA, 'filename',[subject '_RS.set'], ...
        'filepath', rsdir);
    EEG_SDFAA = pop_saveset(EEG_SDFAA, 'filename',[subject '_SD.set'], ...
        'filepath', sddir);
    
%% EXTRACT AND CLEAN EYES OPEN DATA
     
% OPEN RS FILE FROM PREVIOUS STEP
    EEG = pop_loadset( 'filename',[ subject '_RS.set'],'filepath', rsdir);
    
    % CREATE 1 MINUTE EPOCHS OF EYES OPEN (EO) CONDITION. EVENT CODE 30
    EEG_EO = pop_epoch(EEG, {'30'}, [0 59.9], ...
        'newname', [ subject '_EO'], ...
        'epochinfo', 'yes');
     
    % CONCATENATE THE EO EPOCHS
    EEG_EO = pop_epoch2continuous(EEG_EO, 'Warning', 'off');
    
    % SAVE RAW EO DATA
    EEG_EO = pop_saveset(EEG_EO, 'filename',[subject '_EO'], ...
        'filepath', eodir);
    
    % NOTCH FILTER 50 HZ TO REMOVE LINE NOISE. (CLEANLINE NOT WORKING)
    % LOW-PASS AT 40 HZ COULD BE ALTERNATIVE
    EEG_EO  = pop_basicfilter(EEG_EO,  1:EEG_EO.nbchan, ... 
        'Filter', 'PMnotch', ...
        'Design', 'notch', ...
        'Cutoff', 50, ...
        'Order', 180 );
    
    % SAVE ORIGINAL CHANNELS BEFORE REMOVING BAD ONES
    originalchanlocs = EEG.chanlocs;
    
    % USE CLEAN_RAW TO HIGH-PASS FILTER (1HZ), CLEAN DATA, AND REMOVE BAD
    % CHANNELS
    EEG_EO = pop_clean_rawdata(EEG_EO, 'FlatlineCriterion',5, ...
        'ChannelCriterion',0.8, ...
        'LineNoiseCriterion',4, ...
        'Highpass', [0.25 1], ...
        'BurstCriterion', 20, ...
        'WindowCriterion', 0.25, ...
        'BurstRejection', 'on', ...
        'Distance','Euclidian', ...
        'WindowCriterionTolerances', [-Inf 7]);
    EEG_EO.setname = [ subject '_EO_Clean']; % NAME FOR DATASET MENU
    
    % SAVE CLEANED EO DATA FOR VISUAL EXAMINATION
    EEG_EO = pop_saveset(EEG_EO, 'filename',[subject '_EO_Clean.set'], ...
        'filepath', eodir);
    
    %% EPOCH EYES OPEN DATA
     
    % CREATE CONTINOUS EO EPOCHS OF 2.048 SECONDS, WITH 75% OVERLAP (0.512)
    EEG_EO = eeg_regepochs(EEG_EO, 'recurrence', 0.512, ...
        'limits', [-1.024 1.024], ...
        'rmbase', NaN); 
      
    % REMOVE BASELINE (MEAN OF THE WHOLE EPOCH)
    EEG_EO = pop_rmbase(EEG_EO, [],[]);
    EEG_EO.setname = [ subject '_EO_Clean_Epoch']; % NAME FOR DATASET MENU
      
    % SAVE EO DATA IN EO FOLDER
    EEG_EO = pop_saveset(EEG_EO, 'filename',[ subject '_EO_Clean_Epoch.set'], ...
        'filepath', eodir);
    
    %% EXTRACT AND CLEAN EYES CLOSED DATA
    
    % CREATE 1 MINUTE EPOCHS OF EYES CLOSED (EC) CONDITION. EVENT CODE 20
    EEG_EC = pop_epoch(EEG, {'20'}, [0 59.9], ...
        'newname', [ subject '_EC'], ...
        'epochinfo', 'yes');
    
    % CONCATENATE THE EO EPOCHS
    EEG_EC = pop_epoch2continuous(EEG_EC, 'Warning', 'off');
    
    % SAVE RAW EC DATA
    EEG_EC = pop_saveset(EEG_EC, 'filename',[subject '_EC'], ...
        'filepath', ecdir);
    
    % NOTCH FILTER 50 HZ TO REMOVE LINE NOISE. (CLEANLINE NOT WORKING)
    % LOW-PASS AT 40 HZ COULD BE ALTERNATIVE
    EEG_EC  = pop_basicfilter(EEG_EC,  1:EEG_EC.nbchan, ... 
        'Filter', 'PMnotch', ...
        'Design', 'notch', ...
        'Cutoff', 50, ...
        'Order', 180 );
    
    % SAVE ORIGINAL CHANNELS BEFORE REMOVING BAD ONES
    originalchanlocs = EEG.chanlocs;
    
    % USE CLEAN_RAW TO HIGH-PASS FILTER (1HZ), CLEAN DATA, AND REMOVE BAD
    % CHANNELS
    EEG_EC = pop_clean_rawdata(EEG_EC, 'FlatlineCriterion',5, ...
        'ChannelCriterion',0.8, ...
        'LineNoiseCriterion',4, ...
        'Highpass', [0.25 1], ...
        'BurstCriterion', 20, ...
        'WindowCriterion', 0.25, ...
        'BurstRejection', 'on', ...
        'Distance','Euclidian', ...
        'WindowCriterionTolerances', [-Inf 7]);
    EEG_EC.setname = [ subject '_EC_Clean']; % NAME FOR DATASET MENU
    
    % SAVE CLEANED RS DATA FOR VISUAL EXAMINATION
    EEG_EC = pop_saveset(EEG_EC, 'filename',[subject '_EC_Clean.set'], ...
        'filepath', ecdir);
    
    %% EPOCH EYES OPEN DATA
    
    % CREATE CONTINOUS EO EPOCHS OG 2.048 SEC, WITH 75% OVERLAP (0.512)
    EEG_EC = eeg_regepochs(EEG_EC, 'recurrence', 0.512, ...
        'limits', [-1.024 1.024], ...
        'rmbase', NaN); 
     
    % REMOVE BASELINE (MEAN OF THE WHOLE EPOCH)
    EEG_EC = pop_rmbase(EEG_EC, [],[]);
    EEG_EC.setname = [ subject '_EC_Clean_Epoch']; % NAME FOR DATASET MENU
    
    % SAVE EC DATA IN EC FOLDER
    EEG_EC = pop_saveset(EEG_EC, 'filename',[ subject '_EC_Clean_Epoch.set'], ...
        'filepath', ecdir);
     
    %% EPOCH REMOVAL BEFORE ICA
    
    % MARK BAD EPOCHS (-500 TO 500 uV THRESHOLD), CHANNEL 1-4 ARE EOG,
    % HENCE THEY ARE EXCLUDED HERE
    EEG_EO = pop_eegthresh(EEG_EO,1, ...
        [5:length(EEG_EO.chanlocs)], ...
        -500, 500, ...
        -1.024, 1.024, ...
        0, 0);
    EEG_EC = pop_eegthresh(EEG_EC,1, ...
        [5:length(EEG_EC.chanlocs)], ...
        -500,500, ...
        -1.024, 1.024, ...
        0, 0);
    
    % REJECT BAD EPOCHS FOR EO AND EC DATA
    EEG_EO = pop_rejepoch(EEG_EO, EEG_EO.reject.rejthresh,0);
    EEG_EC = pop_rejepoch(EEG_EC, EEG_EC.reject.rejthresh,0);
    EEG_EO.setname = [ subject '_EO_epochrej']; % NAME FOR DATASET MENU
    EEG_EC.setname = [ subject '_EC_epochrej']; % NAME FOR DATASET MENU
    
    % SAVE DATA AFTER EPOCH REJECTION
    EEG_EO = pop_saveset(EEG_EO, ...
        'filename',[ subject '_EO_epochrej.set'], ...
        'filepath', eodir);
    EEG_EC = pop_saveset(EEG_EC, ...
        'filename',[ subject '_EC_epochrej.set'], ...
        'filepath', ecdir);
    
    %% RUN ICA ON EEG CHANNELS
    
    EEG_EO = pop_runica(EEG_EO, 'extended', 1, ...
        'interupt','on', ...
        'pca', length(EEG_EO.chanlocs));
    EEG_EC = pop_runica(EEG_EC, 'extended', 1, ...
        'interupt', 'on', ...
        'pca', length(EEG_EC.chanlocs));
    EEG_EO.setname = [ subject '_EO_ICA']; % NAME FOR DATASET MENU
    EEG_EC.setname = [ subject '_EC_ICA']; % NAME FOR DATASET MENU
     
    % SAVE DATA WITH ICA WEIGHTS
    EEG_EO = pop_saveset(EEG_EO, 'filename',[ subject '_EO_ICA.set'], ...
        'filepath', eodir);
    EEG_EC = pop_saveset(EEG_EC, 'filename',[ subject '_EC_ICA.set'], ...
        'filepath', ecdir);

    % RUN ICLABEL(Pion-Tonachini et al., 2019) TO LABEL COMPONENTS
    EEG_EO = pop_iclabel(EEG_EO, 'default');
    EEG_EC = pop_iclabel(EEG_EC, 'default');
    
    % MARK COMPONENTS WITH >= 90% PROBABILITY OF BEING NON-BRAIN COMPONENTS
    EEG_EO = pop_icflag(EEG_EO, ...
        [NaN NaN;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1]);
    EEG_EC = pop_icflag(EEG_EC, ...
        [NaN NaN;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1]);
    EEG_EO.setname = [ subject '_EO_ICA_marked']; % NAME FOR DATASET MENU
    EEG_EC.setname = [ subject '_EC_ICA_marked']; % NAME FOR DATASET MENU
    
    % SAVE DATA WITH COMPONENTS MARKED FOR REMOVAL
    EEG_EO = pop_saveset(EEG_EO, ...
        'filename',[ subject '_EO_ICA_Marked.set'], ...
        'filepath', eodir);
    EEG_EC = pop_saveset(EEG_EC, ...
        'filename',[ subject '_EC_ICA_Marked.set'], ...
        'filepath', ecdir);
    
    % REMOVE SELECTED COMPONENTS
    EEG_EO = pop_subcomp(EEG_EO, ...
        [find(EEG_EO.reject.gcompreject == 1)], ...
        0);
    EEG_EC = pop_subcomp(EEG_EC, ...
        [find(EEG_EC.reject.gcompreject == 1)], ...
        0);
    EEG_EO.setname = [ subject '_EO_ICA_Removed']; % NAME FOR DATASET MENU
    EEG_EC.setname = [ subject '_EC_ICA_Removed']; % NAME FOR DATASET MENU
    
    % SAVE DATA WITH COMPONENTS REMOVED
    EEG_EO = pop_saveset(EEG_EO, ...
        'filename',[ subject '_EO_ICA_Removed.set'], ...
        'filepath', eodir);
    EEG_EC = pop_saveset(EEG_EC, ...
        'filename',[ subject '_EC_ICA_Removed.set'], ...
        'filepath', ecdir);
    
    %% POST ICA
    
    % INTERPOLATE CHANNELS USING ORIGINAL CHANNELS
    EEG_EO = pop_interp(EEG_EO, originalchanlocs, 'spherical');
    EEG_EC = pop_interp(EEG_EC, originalchanlocs, 'spherical');
    
    % REMOVE EOG CHANNELS 1:4
    EEG_EO = pop_select(EEG_EO,'nochannel', 1:4);
    EEG_EC = pop_select(EEG_EC,'nochannel', 1:4);
    EEG_EO.setname = [ subject '_EO_Preprocessed']; % NAME FOR DATASET MENU
    EEG_EC.setname = [ subject '_EC_Preprocessed']; % NAME FOR DATASET MENU
    
    % SAVE PREPROCESSED DATA
    EEG_EO = pop_saveset(EEG_EO, ...
        'filename',[ subject '_EO_Preprocessed.set'], ...
        'filepath', eodir);
    EEG_EC = pop_saveset(EEG_EC, ...
        'filename',[ subject '_EC_Preprocessed.set'], ...
        'filepath', ecdir);
    

    %% OTHER THINGS TO CONSIDER
    
    % TRIM DATASET (BETWEEN REREFERENCE AND RESAMPLE?)
    % EEG  = pop_eegtrim( EEG, 0, 3000 , 'post',  3000, 'pre',  0 );
    
    % CHANGE ORDER OF CERTAIN FUNCTIONS?
    
    % LOW-PASS FILTER AT 40 HZ INSTEAD OF NOTCH? OR BOTH?
    
    % REJECT EPOCHS AGAIN AFTER -500 +500 UV. WITH SD? SEE MAKOTO
    
    % USE CLEANLINE OR CLEANLINENOISE. DOES NOT WORK WELL ATM.
    % EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass',[0.25 1.25] ,'BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    
    % AVERAGE REFERENCE OR LORETA? SINGLE EQUIVALENT CURRENT DIPOLES?
    
    % WHAT ABOUT ALL THE BOUNDARY EVENTS CREATED BY E.G., CLEAN_RAW?
    
    % CREATE STUDY IN EEGLAB?
    
    % CONSIDER PREP PIPELINE (2015) AND ROBUST PIPELINE (2019)
    
    % CREATE SUBJECT FOLDERS FOR PREPROCESSED DATA?
    
    % CODE FOR SPLITTING INTO RS/SD UP TO DATE?
    
    % IS CHANNEL LOCATIONS WORKING CORRECTLY?
    
    % RUN HIGH-PASS WITH CLEAN_RAW, THEN NOTCH, THEN RUN THE REST?
end

fprintf('\n\n\n**** FINISHED ****\n\n\n');
    
