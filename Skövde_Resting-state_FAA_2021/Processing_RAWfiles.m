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
subject_list = {'sub-001', 'sub-003', 'sub-004', 'sub-005', 'sub-006', 'sub-007', 'sub-008', 'sub-009', 'sub-010', 'sub-011', 'sub-012', 'sub-013', 'sub-014', 'sub-015', 'sub-016', 'sub-017', 'sub-018', 'sub-019', 'sub-020', 'sub-021', 'sub-022', 'sub-023', 'sub-025', 'sub-026', 'sub-027', 'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

% PATH TO THE EEG and RAW FOLDERS
eegfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\';
rawfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_RAW\';

% PATH TO EEGLAB TEMPLATE (BESA) CAP
chanlocs = 'C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2020_0\plugins\dipfit3.7\standard_BESA\standard-10-5-cap385.elp';

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
    EEG = pop_importdata('dataformat','matlab','nbchan',35,'data',[subjectfolder subject '.mat'],'srate',512,'pnts',0,'xmin',0);
    
    % IMPORT EVENT INFORMATION (CHANNEL 18)
    EEG = pop_chanevent(EEG, 18, 'edge', 'leading', 'edgelen', 0 );
    
    % REMOVE FIRST(G.TEC TIME) AND LAST (EMPTY) CHANNELS
    EEG = pop_select( EEG, 'nochannel', [1 34] );
    
    % IMPORT CHANNEL LOCATIONS
    EEG = pop_chanedit(EEG, 'lookup', chanlocs,'load',{[ localizer 'Locations_32Channels.ced'] 'filetype' 'autodetect'});
    
    % RE-REFERENCE TO LM RM (FOR NOW)
    EEG = pop_reref( EEG, [5 6] );

    % TRIM DATASET
    % EEG  = pop_eegtrim( EEG, 0, 3000 , 'post',  3000, 'pre',  0 );
    
    % RESAMPLE DATASET FROM 512 TO 256 HZ
    EEG = pop_resample(EEG, 256);
    
    % HIGH-PASS FILTER THE DATA AT 1 HZ. --Clean rawdata and ASR?--
    EEG = pop_eegfiltnew(EEG, 'locutoff',1);
    
    % LOW-PASS FILTER THE DATA AT 40 HZ
    EEG = pop_eegfiltnew(EEG, 'hicutoff',40);
    
    % CLEAN DATA
    % EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
    EEG.setname = subject;
    
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
    EEG_RSFAA = pop_select( EEG,'time',[startPoint_RS splitPoint_RS] );
    EEG_SDFAA = pop_select( EEG,'time',[splitPoint_SD endPoint_SD] );
    EEG_RSFAA.setname = [ subject '_RS'];
    EEG_SDFAA.setname = [ subject '_SD'];
    
    % SAVE RS AND SD DATA IN RS AND SD FOLDERS
    EEG_RSFAA = pop_saveset( EEG_RSFAA, 'filename',[subject '_RS.set'],'filepath', rsdir);
    EEG_SDFAA = pop_saveset( EEG_SDFAA, 'filename',[subject '_SD.set'],'filepath', sddir);
    
    % GOOD PLACE TO EXAMINE THE DATA
    
%% EPOCHING
    
%%%%% EYES OPEN %%%%%%
    
    % OPEN RS FILE FROM PREVIOUS STEP
    EEG = pop_loadset( 'filename',[ subject '_RS.set'],'filepath', rsdir);
     
    % CREATE 1 MINUTE EPOCHS OF EYES OPEN (EO) CONDITION. EVENT CODE 30
    EEG_EO = pop_epoch( EEG, {  '30'  }, [0         59.9], 'newname', [ subject '_EO'], 'epochinfo', 'yes');
     
    % CONCATENATE THE EO EPOCHS
    EEG_EO = pop_epoch2continuous(EEG_EO, 'Warning', 'off');
     
    % CREATE CONTINOUS EO EPOCHS OF 2.048 SECONDS, WITH 75% OVERLAP (0.512)
    EEG_EO = eeg_regepochs(EEG_EO, 'recurrence', 0.512, 'limits', [-1.024 1.024], 'rmbase', NaN); 
      
    % REMOVE BASELINE (MEAN OF THE WHOLE EPOCH)
    EEG_EO = pop_rmbase( EEG_EO, [],[]);
    EEG_EO.setname = [ subject '_EO'];
      
    % SAVE EO DATA IN EO FOLDER
    EEG_EO = pop_saveset( EEG_EO, 'filename',[ subject '_EO.set'],'filepath', eodir);
    
%%%%% EYES CLOSED %%%%%%
    
    % CREATE 1 MINUTE EPOCHS OF EYES CLOSED (EC) CONDITION. EVENT CODE 20
    EEG_EC = pop_epoch( EEG, {  '20'  }, [0         59.9], 'newname', [ subject '_EO'], 'epochinfo', 'yes');
    
    % CONCATENATE THE EO EPOCHS
    EEG_EC = pop_epoch2continuous(EEG_EC, 'Warning', 'off');
    
    % CREATE CONTINOUS EO EPOCHS OG 2.048 DRVONFD, WITH 75% OVERLAP (0.512)
    EEG_EC = eeg_regepochs(EEG_EC, 'recurrence', 0.512, 'limits', [-1.024 1.024], 'rmbase', NaN); 
     
    % REMOVE BASELINE (MEAN OF THE WHOLE EPOCH)
    EEG_EC = pop_rmbase( EEG_EC, [],[]);
    EEG_EC.setname = [ subject '_EC'];
    
    % SAVE EC DATA IN EC FOLDER
    EEG_EC = pop_saveset( EEG_EC, 'filename',[ subject '_EC.set'],'filepath', ecdir);
     
    %% EPOCH REMOVAL
    
    % MARK BAD EPOCHS (-500 TO 500 uV THRESHOLD), CHANNEL 1-4 ARE EOG,
    % HENCE THEY ARE EXCLUDED HERE
    EEG_EO = pop_eegthresh(EEG_EO,1, [5:length(EEG_EO.chanlocs)],-500,500,-1.024,1.024,0,0);
    EEG_EC = pop_eegthresh(EEG_EC,1, [5:length(EEG_EC.chanlocs)],-500,500,-1.024,1.024,0,0);
    
    % REJECT BAD EPOCHS FOR EO AND EC DATA
    EEG_EO = pop_rejepoch( EEG_EO, EEG_EO.reject.rejthresh,0);
    EEG_EC = pop_rejepoch( EEG_EC, EEG_EC.reject.rejthresh,0);
    EEG_EO.setname = [ subject '_EO_epochrej'];
    EEG_EC.setname = [ subject '_EC_epochrej'];
    
    % SAVE DATA AFTER EPOCH REJECTION
    EEG_EO = pop_saveset( EEG_EO, 'filename',[ subject '_EO_epochrej.set'],'filepath', eodir);
    EEG_EC = pop_saveset( EEG_EC, 'filename',[ subject '_EC_epochrej.set'],'filepath', ecdir);
    
    %% RUN ICA ON EEG CHANNELS
    
    EEG_EO = pop_runica(EEG_EO, 'extended',1,'interupt','on','pca', length(EEG_EO.chanlocs));
    EEG_EC = pop_runica(EEG_EC, 'extended',1,'interupt','on','pca', length(EEG_EC.chanlocs));
    EEG_EO.setname = [ subject '_EO_ICA']
    EEG_EC.setname = [ subject '_EC_ICA']
    
    % SAVE DATA WITH ICA WEIGHTS
    EEG_EO = pop_saveset( EEG_EO, 'filename',[ subject '_EO_ICA.set'],'filepath', eodir);
    EEG_EC = pop_saveset( EEG_EC, 'filename',[ subject '_EC_ICA.set'],'filepath', ecdir);
    
    %% MARA
    
    % INITIALIZE ALLEEG BY OPENING EEGLAB
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
    % ADD CURRENT EEG TO ALLEEG BY RELOADING SAVED ICA DATA
    EEG_EO = pop_loadset( 'filename',[ subject '_EO_ICA.set'],'filepath', eodir);
    EEG_EC = pop_loadset( 'filename',[ subject '_EC_ICA.set'],'filepath', ecdir);
    EEG_EO = eeg_checkset(EEG_EO);
    EEG_EC = eeg_checkset(EEG_EC);
    
    % AUTOMATICALLY REMOVE COMPONENTS WITH MARA
    EEG_EO = processMARA (ALLEEG, EEG_EO, CURRENTSET, [0,0,0,0,1]);
    EEG_CO = processMARA (ALLEEG, EEG_EC, CURRENTSET, [0,0,0,0,1]);
    
    % automatically remove artifacts without gui
    % EEG = pop_subcomp(EEG);

    % SAVE DATA AFTER REMOVING COMPONENTS
    EEG_EO = pop_saveset( EEG_EO, 'filename',[ subject '_EO_MARA.set'],'filepath', eodir);
    EEG_EC = pop_saveset( EEG_EC, 'filename',[ subject '_EC_MARA.set'],'filepath', ecdir);
    EEG_EO.setname = [ subject '_EO_MARA']
    EEG_EC.setname = [ subject '_EC_MARA']
    
    % ----------------------------
    % Interpolate channels with original channel locations (before ICA?)
    % EEG_EO = pop_interp(EEG, EEG.originalEEG.chanlocs, 'spherical');
    % EEG_EC = pop_interp(EEG, EEG.originalEEG.chanlocs, 'spherical');
    
    
    % CLEAN RAWDATA? (AFTER/INSTEAD OF HIGH-PASS FILTER AND BEFORE ICA)
    % EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );

    % TO DO: EOG channels. Reject data/channels. Interpolate bad
    % electrodes. Clean rawdata. Reject epochs (manually?). Before ICA. 
    % Separate into RS and SD before anything else perhaps? Maybe that is
    % where one event is disappearing? EEG = eeg_interp? Fix MARA.
    
end

fprintf('\n\n\n**** FINISHED ****\n\n\n');  
