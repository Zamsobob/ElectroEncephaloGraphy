% CLEAR MEMORY AND THE COMMAND WINDOW
clear;
clc;

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


% DEFINE THE SET OF SUBJECTS THAT WERE ETHICALLY APPROVED
subject_list = {'sub-002', 'sub-005', 'sub-006', 'sub-008', 'sub-009', ...
    'sub-011', 'sub-013', 'sub-014', 'sub-015', 'sub-019', ...
    'sub-020', 'sub-021', 'sub-022', 'sub-025', 'sub-027', ...
    'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

% PATH TO THE EEG and RAW FOLDERS
eegfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\';
rawfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_RAW\';

%PATH TO LOCALIZER FILE (INCLUDES CHANNEL LOCATIONS AND TEMPLATES)
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

if ~exist('RS_Preprocessed', 'dir')
    mkdir EEG_Preprocessed
end
final = [ eegfolder 'EEG_Preprocessed'];

%% LOADING RAW FAA DATA AND RELEVANT FILES

% LOOP THROUGH ALL SUBJECTS
for s = 2 %:numsubjects
    
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
    
    % IMPORT CHANNELS WITH Cz AS REFERENCE. ADD Cz COORDINATES
    EEG = pop_chanedit(EEG, 'load',{[localizer 'Locations_32Channels.ced'], ...
        'filetype','autodetect'}, 'append', EEG.nbchan, ...
        'changefield', {33, 'labels', 'Zc'}, ...
        'changefield', {33, 'theta', '90'}, ...
        'changefield', {33, 'radius', '0'}, ...
        'changefield', {33, 'X', '3.7494e-33'}, ...
        'changefield', {33, 'Y', '-6.1232e-17'}, ...
        'changefield', {33,'Z','1'}, ...
        'changefield', {33, 'sph_theta', '-90'}, ...
        'changefield', {33, 'sph_phi', '90'}, ...
        'changefield', {33, 'sph_radius', '1'}, ...
        'setref', {'1:33', 'Cz'}, ...
        'eval','chans = pop_chancenter( chans, [],[]);');

    % RE-REFERENCE TO MASTOIDS AND ADD Cz BACK
    EEG = pop_reref( EEG, [5 6] ,'refloc', struct('labels',{'Zc'}, ...
        'theta', {90}, 'radius', {0}, ...
        'X', {3.7494e-33}, 'Y', {-6.1232e-17}, 'Z', {1}, ...
        'sph_theta', {-90}, 'sph_phi', {90}, 'sph_radius', {1}, ...
        'type', {''}, 'ref', {'Cz'}, ...
        'urchan', {[]}, ...
        'datachan', {0}, ...
        'sph_theta_besa', {0}, ...
        'sph_phi_besa', {0}));
    
    % RESAMPLE DATASET FROM 512 TO 250 HZ
    EEG = pop_resample(EEG, 250);
    
    %% EXTRACT RESTING-STATE (RS) AND STATE-DEPENDENT (SD) DATA
    % DEFINE WHERE TO SPLIT TRIALS. RS PERIOD ENDS AFTER 16TH EVENT.
    
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
    EEG_RSFAA.setname = [subject '_RS']; % NAME FOR DATASET MENU
    EEG_SDFAA.setname = [subject '_SD']; % NAME FOR DATASET MENU
    
    % SAVE RS AND SD DATA IN RS AND SD FOLDERS
    EEG_RSFAA = pop_saveset(EEG_RSFAA, 'filename',[subject '_RS.set'], ...
        'filepath', rsdir);
    EEG_SDFAA = pop_saveset(EEG_SDFAA, 'filename',[subject '_SD.set'], ...
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
    EEG_EO  = pop_basicfilter(EEG_EO, 1:EEG_EO.nbchan, ... 
        'Filter', 'PMnotch', ...
        'Design', 'notch', ...
        'Cutoff', 50, ...
        'Order', 180);
    
    % SAVE ORIGINAL DATA BEFORE REMOVING BAD CHANNELS
    originalchanlocs = EEG.chanlocs; % FOR INTERPOLATION LATER
    oldchans = {EEG.chanlocs.labels};
    origEEG_EO = EEG_EO;
    
    % USE CLEAN_RAW TO REMOVE BAD CHANNELS
    EEG_EO = pop_clean_rawdata(EEG_EO, 'FlatlineCriterion', 5, ...
        'ChannelCriterion', 0.7, ...
        'LineNoiseCriterion', 4, ...
        'Highpass', [0.25 1], ...
        'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', ...
        'availableRAM_GB', 8, ...
        'BurstRejection', 'off', ...
        'Distance', 'Euclidian');
    
    newchans_EO = {EEG_EO.chanlocs.labels}; % SAVE NEW EO CHANS AFTER CLEAN
    chandiff_EO = setdiff(oldchans, newchans_EO); % REMOVED CHANNELS
    
    % REMOVE EOG CHANNELS FROM LIST OF REMOVED CHANNELS
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
    
    % GO BACK TO DATA BEFORE CLEAN_RAW AND REMOVE ONLY EEG CHANNELS
    if ~isempty(chandiff_EO)
        EEG_EO = pop_select(origEEG_EO, 'nochannel', chandiff_EO);
    end
    
    % HIGH-PASS FILTER AT 1 HZ AND PERFORM ARTIFACT SUBSPACE RECONSTRUCTION
    %(ASR) WITH CLEAN_RAW
    EEG_EO = pop_clean_rawdata(EEG_EO, 'FlatlineCriterion', 'off', ...
        'ChannelCriterion', 'off',  ...
        'LineNoiseCriterion', 'off', ...
        'Highpass', [0.25 1], ...
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
     
    % CREATE CONTINOUS EO EPOCHS OF 2.048 SECONDS, WITH 75% OVERLAP (0.512)
    EEG_EO = eeg_regepochs(EEG_EO, 'recurrence', 0.512, ...
        'limits', [-1.024 1.024], ...
        'rmbase', NaN); 
      
    % REMOVE BASELINE (MEAN OF THE WHOLE EPOCH)
    EEG_EO = pop_rmbase(EEG_EO, [],[]);
    EEG_EO.setname = [subject '_EO_Clean_Epoch']; % NAME FOR DATASET MENU
    
    % ADD EOG CHANNEL COORDINATES FOR ICA AND INTERPOLATION
    EEG_EO = pop_chanedit(EEG_EO, 'changefield', {1,'theta','42'}, ...
        'changefield', {1,'radius','0.65556'}, 'changefield', {1, 'X', '55.7734'}, ...
        'changefield', {1, 'Y', '-50.2186'}, 'changefield', {1, 'Z', '-39.9051'}, ...
        'changefield', {1, 'sph_theta', '-42'}, 'changefield', {1, 'sph_phi','-28'}, ...
        'changefield', {1, 'sph_radius', '85'}, 'changefield', {2, 'theta', '25'}, ...
        'changefield', {2, 'radius', '0.58333'}, 'changefield', {2, 'X', '74.4112'}, ...
        'changefield', {2, 'Y', '-34.6985'}, 'changefield', {2, 'Z', '-21.9996'}, ...
        'changefield', {2, 'sph_theta', '-25'}, 'changefield', {2, 'sph_phi', '-15'}, ...
        'changefield', {2, 'sph_radius', '85'}, 'changefield', {3, 'theta', '27'}, ...
        'changefield', {3, 'radius', '.69444'}, 'changefield', {3, 'X', '62.0389'}, ...
        'changefield', {3, 'Y', '-31.6104'}, 'changefield', {3, 'Z', '-48.754'}, ...
        'changefield', {3, 'sph_theta', '-27'}, 'changefield', {3, 'sph_phi', '-35'}, ...
        'changefield', {3, 'sph_radius', '85'}, 'changefield', {4, 'theta', '-42'}, ...
        'changefield', {4, 'radius', '0.65556'}, 'changefield', {4, 'X', '55.7734'}, ...
        'changefield', {4, 'Y', '50.2186'}, 'changefield', {4, 'Z', '-39.9051'}, ...
        'changefield', {4, 'sph_theta', '42'}, 'changefield', {4, 'sph_phi', '-29'}, ...
        'changefield', {4,' sph_radius', '85'});
      
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
    EEG_EC  = pop_basicfilter(EEG_EC, 1:EEG_EC.nbchan, ... 
        'Filter', 'PMnotch', ...
        'Design', 'notch', ...
        'Cutoff', 50, ...
        'Order', 180);
    
   % SAVE ORIGINAL DATA BEFORE REMOVING BAD CHANNELS
    originalchanlocs = EEG.chanlocs; % FOR INTERPOLATION LATER
    oldchans = {EEG.chanlocs.labels};
    origEEG_EC = EEG_EC;
    
    % USE CLEAN_RAW TO REMOVE BAD CHANNELS
    EEG_EC = pop_clean_rawdata(EEG_EC, 'FlatlineCriterion', 5, ...
        'ChannelCriterion', 0.7, ...
        'LineNoiseCriterion', 4, ...
        'Highpass', [0.25 1], ...
        'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', ...
        'availableRAM_GB', 8, ...
        'BurstRejection', 'off', ...
        'Distance', 'Euclidian');
    
    newchans_EC = {EEG_EC.chanlocs.labels}; % SAVE NEW EO CHANS AFTER CLEAN
    chandiff_EC = setdiff(oldchans, newchans_EC); % DIFFERENCE OLD AND NEW CHANNELS
    
    % REMOVE EOG CHANNELS FROM LIST OF REMOVED CHANNELS
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
    
    % GO BACK TO DATA BEFORE CLEAN_RAW AND REMOVE ONLY EEG CHANNELS
    if ~isempty(chandiff_EO)
        EEG_EC = pop_select(origEEG_EC, 'nochannel', chandiff_EC);
    end
    
    % HIGH-PASS FILTER AT 1 HZ AND PERFORM ARTIFACT SUBSPACE RECONSTRUCTION
    %(ASR) WITH CLEAN_RAW
    EEG_EC = pop_clean_rawdata(EEG_EC, 'FlatlineCriterion', 'off', ...
        'ChannelCriterion', 'off',  ...
        'LineNoiseCriterion', 'off', ...
        'Highpass', [0.25 1], ...
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
    
    %% EPOCH EYES OPEN DATA
    
    % CREATE CONTINOUS EO EPOCHS OG 2.048 SEC, WITH 75% OVERLAP (0.512)
    EEG_EC = eeg_regepochs(EEG_EC, 'recurrence', 0.512, ...
        'limits', [-1.024 1.024], ...
        'rmbase', NaN); 
     
    % REMOVE BASELINE (MEAN OF THE WHOLE EPOCH)
    EEG_EC = pop_rmbase(EEG_EC, [],[]);
    EEG_EC.setname = [subject '_EC_Clean_Epoch']; % NAME FOR DATASET MENU
    
    % ADD EOG CHANNEL COORDINATES FOR ICA AND INTERPOLATION
    EEG_EC = pop_chanedit(EEG_EC, 'changefield', {1,'theta','42'}, ...
        'changefield', {1,'radius','0.65556'}, 'changefield', {1, 'X', '55.7734'}, ...
        'changefield', {1, 'Y', '-50.2186'}, 'changefield', {1, 'Z', '-39.9051'}, ...
        'changefield', {1, 'sph_theta', '-42'}, 'changefield', {1, 'sph_phi','-28'}, ...
        'changefield', {1, 'sph_radius', '85'}, 'changefield', {2, 'theta', '25'}, ...
        'changefield', {2, 'radius', '0.58333'}, 'changefield', {2, 'X', '74.4112'}, ...
        'changefield', {2, 'Y', '-34.6985'}, 'changefield', {2, 'Z', '-21.9996'}, ...
        'changefield', {2, 'sph_theta', '-25'}, 'changefield', {2, 'sph_phi', '-15'}, ...
        'changefield', {2, 'sph_radius', '85'}, 'changefield', {3, 'theta', '27'}, ...
        'changefield', {3, 'radius', '.69444'}, 'changefield', {3, 'X', '62.0389'}, ...
        'changefield', {3, 'Y', '-31.6104'}, 'changefield', {3, 'Z', '-48.754'}, ...
        'changefield', {3, 'sph_theta', '-27'}, 'changefield', {3, 'sph_phi', '-35'}, ...
        'changefield', {3, 'sph_radius', '85'}, 'changefield', {4, 'theta', '-42'}, ...
        'changefield', {4, 'radius', '0.65556'}, 'changefield', {4, 'X', '55.7734'}, ...
        'changefield', {4, 'Y', '50.2186'}, 'changefield', {4, 'Z', '-39.9051'}, ...
        'changefield', {4, 'sph_theta', '42'}, 'changefield', {4, 'sph_phi', '-29'}, ...
        'changefield', {4,' sph_radius', '85'});
    
    % SAVE EC DATA IN EC FOLDER
        EEG_EC = pop_saveset(EEG_EC, 'filename',[subject '_EC_Clean_Epoch.set'], ...
            'filepath', ecdir);
     
    %% EPOCH REMOVAL BEFORE ICA
    
    % LOAD EPOCHED DATA
    EEG_EO = pop_loadset('filename',[subject '_EO_Clean_Epoch.set'],'filepath', eodir);
    EEG_EC = pop_loadset('filename',[subject '_EC_Clean_Epoch.set'],'filepath', ecdir);
    
    % MARK BAD EPOCHS (-200 TO 200 uV THRESHOLD), CHANNEL 1-4 ARE EOG,
    % HENCE THEY ARE EXCLUDED HERE.
     EEG_EO = pop_eegthresh(EEG_EO,1, ...
         [5:length(EEG_EO.chanlocs)], ...
         -200, 200, ...
         -1.024, 1.024, ...
         0, 0);
     EEG_EC = pop_eegthresh(EEG_EC,1, ...
         [5:length(EEG_EC.chanlocs)], ...
         -200,200, ...
         -1.024, 1.024, ...
         0, 0);
     
     % REJECT BAD EPOCHS FOR EO AND EC DATA
     EEG_EO = pop_rejepoch(EEG_EO, EEG_EO.reject.rejthresh,0);
     EEG_EC = pop_rejepoch(EEG_EC, EEG_EC.reject.rejthresh,0);
     EEG_EO.setname = [subject '_EO_epochrej']; % NAME FOR DATASET MENU
     EEG_EC.setname = [subject '_EC_epochrej']; % NAME FOR DATASET MENU
     
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
      
     % SAVE DATA WITH ICA WEIGHTS
     if (save_everything)
         EEG_EO = pop_saveset(EEG_EO, 'filename',[ subject '_EO_ICA.set'], ...
             'filepath', eodir);
         EEG_EC = pop_saveset(EEG_EC, 'filename',[ subject '_EC_ICA.set'], ...
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
     
     % REMOVE EOG CHANNELS 1:4
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

% SAVE INTERPOLATED CHANNELS AS .MAT
save InterpolatedChannelsEO.mat interchans_EO
save InterpolatedChannelsEC.mat interchans_EC
save NumberOfEpochsEO.mat numepochs_EO
save NumberOfEpochsEC.mat numepochs_EC

fprintf('\n\n\n**** FINISHED ****\n\n\n');

%% OTHER THINGS TO CONSIDER
    
    % TRIM DATASET (BETWEEN REREFERENCE AND RESAMPLE?). TURKU
    % EEG  = pop_eegtrim(EEG, 0, 3000 , 'post',  3000, 'pre',  0);
    
    % CHANGE ORDER OF CERTAIN FUNCTIONS?
    
    % LOW-PASS FILTER AT 40 HZ INSTEAD OF NOTCH? OR BOTH?
    
    % USE CLEANLINE OR CLEANLINENOISE. DOES NOT WORK WELL ATM.
   
    % LORETA? SINGLE EQUIVALENT CURRENT DIPOLES?
    
    % WHAT ABOUT ALL THE BOUNDARY EVENTS CREATED WHEN EXTRACTING RS DATA?
    
    % CREATE STUDY IN EEGLAB?
    
    % CONSIDER PREP PIPELINE (2015) AND ROBUST PIPELINE (2019)
    
    % CREATE SUBJECT FOLDERS FOR PREPROCESSED DATA? Preprocess folder?
    
    % CODE FOR SPLITTING INTO RS/SD UP TO DATE?
    
    % RUN HIGH-PASS WITH CLEAN_RAW, THEN NOTCH, THEN RUN THE REST OF CLEAN?
    
    % Add "save_everything" for possibility to skip intermediate steps.
    
    % DOWNSAMPLE AFTER ICA? SEE SMITH ET AL
    % CANT RESAMPLE AFTER EPOCHING SO CHANGED IT BACK. WHY DID THEY DO IT?
    
    % 1-50 HZ BANDPASS? WHY? SMTIH ET AL
    
    % WHEN TO ADD EOG COORDINATES? AFTER ICA AND BEFORE INTERP?
    
    % trimOutlier https://github.com/sccn/trimOutlier (UNEPOCHED DATA)
    
    % PROJECT ICA BACK TO 0.1 HZ HIGH-PASS DATA? MAYBE NOT, MAKOTO
    
    % REJECT EPOCHS AGAIN AFTER -500 +500 UV? WITH SD? 
    % Improbability test with 6SD for single channels and 2SD for all channels
    % EEG = pop_jointprob(EEG,1,[1:21] ,6,2,0,0,0,[],0);
    % EEG = pop_rejepoch(EEG,find(EEG.reject.rejglobal),1)
    % EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
    
    % AM I ADDING Cz CORRECTLY? APPEND?
    
    % SPEED UP ICA BY DOWNSAMPLING TO 100 OR USE HIGH-PASS FILTER BEFORE?
    % SEE MAKOTO
    
    % "INCLUDE EOG CHANNELS IN ICA UNLESS THEY ARE BIPOLAR-REFERENCED TO
    % EACH OTHER"
    
    % MY EPOCHS ARE NOT 2.048 AFTER EPOCHING. PROBLEM?
    
    % SHOULD I CHANGE SAMPLING RATE TO 250 TO GET 2^N DATA POINTS IN THE
    % EPOCHS? I BELIEVE I HAVE 524 NOW, CHANGING TO 250 HZ GIVES 512. SMITH
    % SEE FRAMES PER EPOCH IN GUI OR EEG.pnts
