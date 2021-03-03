% CLEAR MEMORY AND THE COMMAND WINDOW
clear;
clc;

% SET VARIABLE TO 1 TO SAVE INTERMEDIATE STEPS. SET TO 0 TO SAVE
% ONLY THE NECESSARY FILES (RAW RS, EPOCHED EO AND EC, FINAL).
save_everything = 1;

%% SET UP FILES AND FOLDERS

% MAKE SURE EEGLAB IS IN PATH
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2020_0')
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

%% LOADING RAW FAA DATA AND RELEVANT FILES

% LOOP THROUGH ALL SUBJECTS
for s = 1:numsubjects
    
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
    EEG = pop_chanedit(EEG, 'load', {[localizer 'Locations_32Channels.ced'], ...
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
    
    %% EXTRACT AND CLEAN EYES OPEN RESTING-STATE DATA
     
    % OPEN RS FILE FROM PREVIOUS STEP
    EEG = pop_loadset('filename',[subject '_RS.set'],'filepath', rsdir);
    
    % CREATE 1 MINUTE EPOCHS OF EYES OPEN (EO) CONDITION. EVENT CODE 30
    EEG_EO = pop_epoch(EEG, {'30'}, [0 59.9], ...
        'newname', [subject '_EO'], ...
        'epochinfo', 'yes');    
     
    % CONCATENATE THE EO EPOCHS
    EEG_EO = pop_epoch2continuous(EEG_EO, 'Warning', 'off');
    EEG_EO.setname = [subject '_EO']; % NAME FOR DATASET MENU
    
    % SAVE RAW EO DATA
    if (save_everything)
        EEG_EO = pop_saveset(EEG_EO, 'filename',[subject '_EO'], ...
            'filepath', eodir);
    end
    
    % NOTCH FILTER 50 HZ TO REMOVE LINE NOISE. (CLEANLINE NOT WORKING)
    % LOW-PASS AT 40 HZ COULD BE ALTERNATIVE
    EEG_EO = pop_basicfilter(EEG_EO, 1:EEG_EO.nbchan, ...
        'Boundary', 'boundary', ...
        'Cutoff', 50, ...
        'Design', 'notch', ...
        'Filter', 'PMnotch', ...
        'Order',  180);
    
    % SAVE ORIGINAL DATA BEFORE REMOVING BAD CHANNELS
    originalchanlocs = EEG.chanlocs; % FOR INTERPOLATION LATER
    oldchans = {EEG.chanlocs.labels};
    origEEG_EO = EEG_EO;
    
    % USE CLEAN_RAWDATA TO IDENTIFY CHANNELS FOR REMOVAL
    EEG_EO = pop_clean_rawdata(EEG_EO, 'FlatlineCriterion', 5, ...
        'ChannelCriterion', 0.7, ...
        'LineNoiseCriterion', 4, ...
        'Highpass', [0.75 1.25], ...
        'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', ...
        'availableRAM_GB', 8, ...
        'BurstRejection', 'off', ...
        'Distance', 'Euclidian');
    
    % I DO NOT WANT TO REMOVE EOG CHANNELS
    newchans_EO = {EEG_EO.chanlocs.labels}; % SAVE NEW EO CHANS AFTER CLEAN
    chandiff_EO = setdiff(oldchans, newchans_EO); % REMOVED CHANNELS
    
    % IDENTIFY IF EOG CHANNELS WERE REMOVED WITH CLEAN_RAWDATA
    % CREATED A LIST OF CHANNELS CLEAN_RAWDATA REMOVED, MINUS EOG CHANNELS
    if any(strcmp(chandiff_EO,'LO2'))
        chandiff_EO(strncmpi(chandiff_EO,'LO2',3)) = [];
    end
    if any(strcmp(chandiff_EO,'SO2'))
        chandiff_EO(strncmpi(chandiff_EO,'SO2',3)) = [];
    end
    if any(strcmp(chandiff_EO,'IO2'))
        chandiff_EO(strncmpi(chandiff_EO,'IO2',3)) = [];
    end
    if any(strcmp(chandiff_EO,'LO1'))
        chandiff_EO(strncmpi(chandiff_EO,'LO1',3)) = [];
    end
    
    % GO BACK TO DATA BEFORE CLEAN_RAW AND REMOVE ONLY EEG CHANNELS,
    % LEAVING EOG CHANNELS IN THE DATASET
    EEG_EO = origEEG_EO;
    if ~isempty(chandiff_EO)
        EEG_EO = pop_select(origEEG_EO, 'nochannel', chandiff_EO);
    end
    
    % HIGH-PASS FILTER AT 1 HZ AND PERFORM ARTIFACT SUBSPACE RECONSTRUCTION
    %(ASR) WITH CLEAN_RAWDATA
    EEG_EO = pop_clean_rawdata(EEG_EO, 'FlatlineCriterion', 'off', ...
        'ChannelCriterion', 'off',  ...
        'LineNoiseCriterion', 'off', ...
        'Highpass', [0.75 1.25], ...
        'BurstCriterion', 20, ...
        'WindowCriterion', 0.25, ...
        'availableRAM_GB', 8, ...
        'BurstRejection', 'on', ...
        'Distance', 'Euclidian', ...
        'WindowCriterionTolerances', [-Inf 7] );
    EEG_EO.setname = [subject '_EO_Clean']; % NAME FOR DATASET MENU
    
    % SAVE CLEANED EO DATA FOR VISUAL EXAMINATION
    if (save_everything)
        EEG_EO = pop_saveset(EEG_EO, 'filename',[subject '_EO_Clean.set'], ...
            'filepath', eodir);
    end
    
    %% EPOCH EYES OPEN DATA
     
    % CREATE CONTINOUS EO EPOCHS OF 2 SECONDS, WITH 75% OVERLAP (0.5)
    EEG_EO = eeg_regepochs(EEG_EO, 'recurrence', 0.5, ...
        'limits', [0 2], ...
        'rmbase', NaN);
    
    % REMOVE BASELINE (MEAN OF THE WHOLE EPOCH)
    EEG_EO = pop_rmbase(EEG_EO, [],[]);
    EEG_EO.setname = [subject '_EO_Clean_Epoch']; % NAME FOR DATASET MENU
      
    % SAVE EO DATA IN EO FOLDER
    EEG_EO = pop_saveset(EEG_EO, 'filename',[subject '_EO_Clean_Epoch.set'], ...
        'filepath', eodir);
    
    %% EXTRACT AND CLEAN EYES CLOSED RESTING-STATE DATA
    
    % CREATE 1 MINUTE EPOCHS OF EYES CLOSED (EC) CONDITION. EVENT CODE 20
    EEG_EC = pop_epoch(EEG, {'20'}, [0 59.9], ...
        'newname', [ subject '_EC'], ...
        'epochinfo', 'yes');
    
    % CONCATENATE THE EO EPOCHS
    EEG_EC = pop_epoch2continuous(EEG_EC, 'Warning', 'off');
    EEG_EC.setname = [ subject '_EC']; % NAME FOR DATASET MENU
    
    % SAVE RAW EC DATA
    if (save_everything)
        EEG_EC = pop_saveset(EEG_EC, 'filename',[subject '_EC'], ...
            'filepath', ecdir);
    end
    
    % NOTCH FILTER 50 HZ TO REMOVE LINE NOISE. (CLEANLINE NOT WORKING)
    % LOW-PASS AT 40 HZ COULD BE ALTERNATIVE
    EEG_EC = pop_basicfilter(EEG_EC, 1:EEG_EC.nbchan, ...
        'Boundary', 'boundary', ...
        'Cutoff', 50, ...
        'Design', 'notch', ...
        'Filter', 'PMnotch', ...
        'Order',  180);
    
    % SAVE ORIGINAL DATA BEFORE REMOVING BAD CHANNELS
    originalchanlocs = EEG.chanlocs; % FOR INTERPOLATION LATER
    oldchans = {EEG.chanlocs.labels};
    origEEG_EC = EEG_EC;
    
    % USE CLEAN_RAWDATA TO IDENTIFY CHANNELS FOR REMOVAL
    EEG_EC = pop_clean_rawdata(EEG_EC, 'FlatlineCriterion', 5, ...
        'ChannelCriterion', 0.7, ...
        'LineNoiseCriterion', 4, ...
        'Highpass', [0.75 1.25], ...
        'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', ...
        'availableRAM_GB', 8, ...
        'BurstRejection', 'off', ...
        'Distance', 'Euclidian');
    
    % I DO NOT WANT TO REMOVE EOG CHANNELS
    newchans_EC = {EEG_EC.chanlocs.labels}; % SAVE NEW EO CHANS AFTER CLEAN
    chandiff_EC = setdiff(oldchans, newchans_EC); % DIFFERENCE OLD AND NEW CHANNELS
    
    % IDENTIFY IF EOG CHANNELS WERE REMOVED WITH CLEAN_RAWDATA
    if any(strcmp(chandiff_EC,'LO2'))
        chandiff_EC(strncmpi(chandiff_EC,'LO2',3)) = [];
    end
    if any(strcmp(chandiff_EC,'SO2'))
        chandiff_EC(strncmpi(chandiff_EC,'SO2',3)) = [];
    end
    if any(strcmp(chandiff_EC,'IO2'))
        chandiff_EC(strncmpi(chandiff_EC,'IO2',3)) = [];
    end
    if any(strcmp(chandiff_EC,'LO1'))
        chandiff_EC(strncmpi(chandiff_EC,'LO1',3)) = [];
    end
    
    % GO BACK TO DATA BEFORE CLEAN_RAW AND REMOVE ONLY EEG CHANNELS,
    % LEAVING EOG CHANNELS IN THE DATASET
    EEG_EC = origEEG_EC;
    if ~isempty(chandiff_EO)
        EEG_EC = pop_select(origEEG_EC, 'nochannel', chandiff_EC);
    end
    
    % HIGH-PASS FILTER AT 1 HZ AND PERFORM ARTIFACT SUBSPACE RECONSTRUCTION
    %(ASR) WITH CLEAN_RAWDATA
    EEG_EC = pop_clean_rawdata(EEG_EC, 'FlatlineCriterion', 'off', ...
        'ChannelCriterion', 'off',  ...
        'LineNoiseCriterion', 'off', ...
        'Highpass', [0.75 1.25], ...
        'BurstCriterion', 20, ...
        'WindowCriterion', 0.25, ...
        'availableRAM_GB', 8, ...
        'BurstRejection', 'on', ...
        'Distance', 'Euclidian', ...
        'WindowCriterionTolerances', [-Inf 7] );
    EEG_EC.setname = [subject '_EC_Clean']; % NAME FOR DATASET MENU
    
    % SAVE CLEANED RS DATA FOR VISUAL EXAMINATION
    if (save_everything)
        EEG_EC = pop_saveset(EEG_EC, 'filename',[subject '_EC_Clean.set'], ...
            'filepath', ecdir);
    end
    
    %% EPOCH EYES CLOSED DATA
    
    % CREATE CONTINOUS EO EPOCHS OF 2 SEC, WITH 75% OVERLAP (0.5)
    EEG_EC = eeg_regepochs(EEG_EC, 'recurrence', 0.5, ...
        'limits', [0 2], ...
        'rmbase', NaN); 
    % REMOVE BASELINE (MEAN OF THE WHOLE EPOCH)
    EEG_EC = pop_rmbase(EEG_EC, [],[]);
    EEG_EC.setname = [subject '_EC_Clean_Epoch']; % NAME FOR DATASET MENU
    
    % SAVE EC DATA IN EC FOLDER
    EEG_EC = pop_saveset(EEG_EC, 'filename',[subject '_EC_Clean_Epoch.set'], ...
        'filepath', ecdir);
     
    %% EPOCH REMOVAL BEFORE ICA
    
    % LOAD EPOCHED DATA
    EEG_EO = pop_loadset('filename',[subject '_EO_Clean_Epoch.set'],'filepath', eodir);
    EEG_EC = pop_loadset('filename',[subject '_EC_Clean_Epoch.set'],'filepath', ecdir);
    
    % MARK BAD EPOCHS (-500 TO 500 uV THRESHOLD). ONLY EEG CHANNELS. DO NOT
    % WANT TO CATCH EYE BLINKS HERE 
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
     
    % APPLY IMPROBABILITY TEST WITH 6SD FOR SINGLE CHANNELS AND 2SD FOR
    % ALL CHANNELS. REJECT SELECTED EPOCHS AGAIN. MAKOTO RECOMMENDATION
    EEG_EO = pop_jointprob(EEG_EO, 1, [5:length(EEG_EO.chanlocs)], ...
        6, 2, 0, 1, 0, [], 0);
    EEG_EC = pop_jointprob(EEG_EC, 1, [5:length(EEG_EC.chanlocs)], ...
        6, 2, 0, 1, 0, [], 0);
    EEG_EO.setname = [subject '_EO_epochrej']; % NAME FOR DATASET MENU
    EEG_EC.setname = [subject '_EC_epochrej']; % NAME FOR DATASET MENU
    EEG_EO = eeg_checkset(EEG_EO);
    EEG_EC = eeg_checkset(EEG_EC);
     
    % SAVE DATA AFTER EPOCH REJECTION
    if (save_everything)
        EEG_EO = pop_saveset(EEG_EO, ...
            'filename',[subject '_EO_epochrej.set'], ...
            'filepath', eodir);
        EEG_EC = pop_saveset(EEG_EC, ...
            'filename',[subject '_EC_epochrej.set'], ...
            'filepath', ecdir);
    end
     
    %% RUN ICA ON ALL CHANNELS
     
    EEG_EO = pop_runica(EEG_EO, 'extended', 1, ...
        'interupt','on', ...
        'pca', length(EEG_EO.chanlocs));
    EEG_EC = pop_runica(EEG_EC, 'extended', 1, ...
        'interupt', 'on', ...
        'pca', length(EEG_EC.chanlocs));
    EEG_EO.setname = [subject '_EO_ICA']; % NAME FOR DATASET MENU
    EEG_EC.setname = [subject '_EC_ICA']; % NAME FOR DATASET MENU
    EEG_EO = eeg_checkset(EEG_EO, 'ica');
    EEG_EC = eeg_checkset(EEG_EC, 'ica');
      
    % SAVE DATA WITH ICA WEIGHTS
    if (save_everything)
        EEG_EO = pop_saveset(EEG_EO, 'filename',[subject '_EO_ICA.set'], ...
            'filepath', eodir);
        EEG_EC = pop_saveset(EEG_EC, 'filename',[subject '_EC_ICA.set'], ...
            'filepath', ecdir);
    end
 
    % RUN ICLABEL(Pion-Tonachini et al., 2019) TO LABEL COMPONENTS
    EEG_EO = pop_iclabel(EEG_EO, 'default');
    EEG_EC = pop_iclabel(EEG_EC, 'default');
     
    % MARK COMPONENTS WITH >= 90% PROBABILITY OF BEING NON-BRAIN COMPONENTS
    EEG_EO = pop_icflag(EEG_EO, ...
        [NaN NaN;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1]);
    EEG_EC = pop_icflag(EEG_EC, ...
        [NaN NaN;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1]);
    EEG_EO.setname = [subject '_EO_ICA_marked']; % NAME FOR DATASET MENU
    EEG_EC.setname = [subject '_EC_ICA_marked']; % NAME FOR DATASET MENU
     
    % SAVE DATA WITH COMPONENTS MARKED FOR REMOVAL
    if (save_everything)
        EEG_EO = pop_saveset(EEG_EO, ...
            'filename',[subject '_EO_ICA_Marked.set'], ...
            'filepath', eodir);
        EEG_EC = pop_saveset(EEG_EC, ...
            'filename',[subject '_EC_ICA_Marked.set'], ...
            'filepath', ecdir);
    end
     
    % REMOVE SELECTED COMPONENTS
    EEG_EO = pop_subcomp(EEG_EO, ...
        [find(EEG_EO.reject.gcompreject == 1)], ...
        0);
    EEG_EC = pop_subcomp(EEG_EC, ...
        [find(EEG_EC.reject.gcompreject == 1)], ...
        0);
    EEG_EO.setname = [subject '_EO_ICA_Removed']; % NAME FOR DATASET MENU
    EEG_EC.setname = [subject '_EC_ICA_Removed']; % NAME FOR DATASET MENU
     
    % SAVE DATA WITH COMPONENTS REMOVED
    if (save_everything)
        EEG_EO = pop_saveset(EEG_EO, ...
            'filename',[subject '_EO_ICA_Removed.set'], ...
            'filepath', eodir);
        EEG_EC = pop_saveset(EEG_EC, ...
            'filename',[subject '_EC_ICA_Removed.set'], ...
            'filepath', ecdir);
    end
     
    %% POST ICA
     
    % INTERPOLATE CHANNELS USING ORIGINAL CHANNEL LOCATIONS
    EEG_EO = pop_interp(EEG_EO, originalchanlocs, 'spherical');
    EEG_EC = pop_interp(EEG_EC, originalchanlocs, 'spherical');
    EEG_EO.setname = [subject '_EO_Interp']; % NAME FOR DATASET MENU
    EEG_EC.setname = [subject '_EC_Interp']; % NAME FOR DATASET MENU
     
    % REMOVE EOG CHANNELS (1:4)
    EEG_EO = pop_select(EEG_EO, ...
        'nochannel', {'LO2' 'SO2' 'IO2' 'LO1'});
    EEG_EC = pop_select(EEG_EC, ...
        'nochannel', {'LO2' 'SO2' 'IO2' 'LO1'});
    EEG_EO.setname = [subject '_EO_Preprocessed']; % NAME FOR DATASET MENU
    EEG_EC.setname = [subject '_EC_Preprocessed']; % NAME FOR DATASET MENU
     
    % SAVE PREPROCESSED DATA
    EEG_EO = pop_saveset(EEG_EO, ...
        'filename',[subject '_EO_Preprocessed.set'], ...
        'filepath', final);
    EEG_EC = pop_saveset(EEG_EC, ...
        'filename',[subject '_EC_Preprocessed.set'], ...
        'filepath', final);
   
    % STORE LIST OF INTERPOLATED CHANNELS FOR EACH SUBJECT
    interchans_EO(s) = {chandiff_EO};
    interchans_EC(s) = {chandiff_EC};
     
    % STORE NUMBER OF EPOCHS FOR EACH SUBJECT
    numepochs_EO(s) = {length(EEG_EO.epoch)};
    numepochs_EC(s) = {length(EEG_EC.epoch)};
     
end

% SAVE INTERPOLATED CHANNELS AND NUMBER OF EPOCHS AS .MAT IN FOLDER Saved_Variables
cd 'Saved_Variables';
save InterpolatedChannelsEO.mat interchans_EO
save InterpolatedChannelsEC.mat interchans_EC
save NumberOfEpochsEO.mat numepochs_EO
save NumberOfEpochsEC.mat numepochs_EC

fprintf('\n\n\n**** PREPROCESSING FINISHED ****\n\n\n');
