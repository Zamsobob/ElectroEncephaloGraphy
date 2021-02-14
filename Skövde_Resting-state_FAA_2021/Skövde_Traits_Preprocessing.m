% CLEAR MEMORY AND THE COMMAND WINDOW
clear;
clc;

% MAKE SURE EEGLAB IS IN PATH
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2020_0')
% WORKING DIRECTORY SHOULD BE D:
cd 'D:\FAA_Study_2021\Skovde\Skovde_Traits_FAA\Skovde_EEG'


% DEFINE THE SET OF SUBJECTS
% subject 24 missing. Cancelled participation?
% REMOVING SUB-002 REMPORARILY. WHICH SHOULD I USE LATER AS I HAVE 2 FILES?
subject_list = {'sub-001', 'sub-003', 'sub-004', 'sub-005', 'sub-006', 'sub-007', 'sub-008', 'sub-009', 'sub-010', 'sub-011', 'sub-012', 'sub-013', 'sub-014', 'sub-015', 'sub-016', 'sub-017', 'sub-018', 'sub-019', 'sub-020', 'sub-021', 'sub-022', 'sub-023', 'sub-025', 'sub-026', 'sub-027', 'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

% PATH TO THE PARENT FOLDERS
skovdefolder = 'D:\FAA_Study_2021\Skovde\Skovde_Traits_FAA\Skovde_EEG\';
parentfolder = 'D:\FAA_Study_2021\Skovde\Skovde_Traits_FAA\Skovde_EEG\EEG_RAW\';
newdir = [ skovdefolder 'EEG_Preprocessed\'];

% PATH TO EEGLAB TEMPLATE (BESA) CAP
chanlocs = 'C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2020_0\plugins\dipfit3.7\standard_BESA\standard-10-5-cap385.elp';

%PATH TO LOCALIZER FILE (INCLUDES CHANNEL LOCATIONS)
localizer = 'D:\FAA_Study_2021\Skovde\Skovde_Traits_FAA\Skovde_EEG\EEG_Localizer\';

% ALLEEG? [ALLEEG EEG CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

% CREATE FOLDERS FOR THE PREPROCESSED DATA
if ~exist('EEG_Resting-state', 'dir')
    mkdir EEG_Preprocessed EEG_Resting-state;
end
    rsdir = [ newdir 'EEG_Resting-state'];
    
if ~exist('EEG_State-dependent', 'dir')
    mkdir EEG_Preprocessed EEG_State-dependent;
end
    sddir = [ newdir 'EEG_State-dependent'];

%% PREPROCESSING OF RAW DATA

% LOOP THROUGH ALL SUBJECTS
for s = 1 %:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [ parentfolder subject '\'];

    % IMPORT RAW DATA
    EEG = pop_importdata('dataformat','matlab','nbchan',35,'data',[subjectfolder subject '.mat'],'srate',512,'pnts',0,'xmin',0);
    
    % IMPORT EVENT INFORMATION (CHANNEL 18)
    % Where is the resting-state "trial" ? D? Talk to B. See Turku_Step1
    % Event 4 is resting-state??
    EEG = pop_chanevent(EEG, 18, 'edge', 'leading', 'edgelen', 0 );
    
    % REMOVE CHANNEL 1 (G.TEC TIME CHANNEL) AND 35 (EMPTY CHANNEL)
    EEG = pop_select( EEG, 'nochannel', [1 34] );
    
    % IMPORT CHANNEL LOCATIONS
    EEG = pop_chanedit(EEG, 'lookup', chanlocs,'load',{[ localizer 'Locations_32Channels.ced'] 'filetype' 'autodetect'});
    
    % RE-REFERENCETO LM RM (FOR NOW)
    EEG = pop_reref( EEG, [5 6] );

    % TRIM DATASET
    % EEG  = pop_eegtrim( EEG, 0, 3000 , 'post',  3000, 'pre',  0 );
    
    % RESAMPLE DATASET FROM 512 TO 256 HZ
    EEG = pop_resample(EEG, 256);
    
    % HIGH PAS FILTER THE DATA AT 1 HZ
    EEG = pop_eegfiltnew(EEG, 'locutoff',1,'plotfreqz',1);
    
    % LOW-PAS FILTER THE DATA AT 40 HZ
    EEG = pop_eegfiltnew(EEG, 'hicutoff',40,'plotfreqz',1);
    EEG.setname = subject

    % SAVE IN CREATED FOLDER
    % EEG = pop_editset(EEG, 'setname', [subject '_Preprocess']);
    % EEG = pop_saveset( EEG, 'filename', [subject '_Preprocess.set'],'filepath', newdir);
    
    % TO DO: Extract RS data. Split into EO and EC. Overlapping epochs. ICA. EOG channels.
    % Reject data/channels. Interpolate bad electrodes. Clean rawdata.
    
    %% Test to extract resting-state and state-dependent data.
    
    % DEFINE WHERE TO SPLIT DATASETS (RESTING-STATE AND STATE-DEPENDENT
    % TRIALS). RESTING-STATE PERIOD ENDS AFTER 16TH EVENT.
    % RS = RESTING-STATE
    % SD = STATE-DEPENDENT
    % Sub-002 is messed up. It only has 2 events, due to being two parts.
    
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
    EEG.setname = subject
    
    % SAVE RS DATA IN RS FOLDER
    EEG_RSFAA = pop_saveset( EEG_RSFAA, 'filename',[subject '_RS.set'],'filepath', rsdir);
    
    % SAVE SD DATA IN SD FOLDER
    EEG_SDFAA = pop_saveset( EEG_SDFAA, 'filename',[subject '_SD.set'],'filepath', sddir);
    
    
    
end
    
fprintf('\n\n\n**** FINISHED ****\n\n\n');  
