% Script for preprocessing resting-state EEG data from the LEMON dataset (part 2)
% The pre-processing pipeline was developed for extraction of frontal alpha asymmetry (FAA)
% It is based on recommended guidelines from Smith et al. (2017)
% 
% Sources:
% https://doi.org/10.1038/sdata.2018.308
% https://doi.org/10.1016/j.ijpsycho.2016.11.005)
% 
% EEGLAB PREFERENCES (STORE 1 DATASET AND DOUBLE PRECISSION) USED:
% pop_editoptions('option_storedisk', 1);
% pop_editoptions('option_single', 0);

%% INITIAL SETUP

% SET VARIABLE TO 1 TO SAVE INTERMEDIATE STEPS. SET TO 0 TO SAVE
% ONLY THE NECESSARY FILES
save_everything = 1;

% SET PATHS
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2021.0'); % EEGLAB TO PATH
eegfolder = [pwd filesep]; % EEG_MPILMBB_LEMON. PATH TO SCRIPTS
rawfolder = [eegfolder 'EEG_Raw_BIDS_ID\']; % RAW FILES
localizer = [eegfolder 'EEG_Localizer_BIDS_ID\Channel_Loc_62_EOG.ced']; % PATH TO CHANNEL LOCATIONS
file_ext = '.vhdr'; % FILE EXTENSION OF RAW FILES

%% --------------------------NO FURTHER SETTINGS NECESSARY-----------------------------------------

% FOLDERS FOR PREPROCESSED DATA
ppfolder = [eegfolder 'EEG_Preprocessed\'];
rsdir = [ppfolder 'EEG_Intermediate'];
cd (ppfolder);
final = [ppfolder 'EEG_Final'];
savevars = [ppfolder 'Saved_Variables'];

% CREATE LIST OF SUBJECTS TO LOOP THROUGH
cd (rawfolder);
subject_list=dir(['*/*' file_ext]);
subject_list={subject_list.name};

% INITIALIZE VARIABLES FOR TABLE OF EPOCHS AND INTERPOLATED CHANNELS PER SUBJECT
% diagnostTable = cell(length(subject_list), 4);
% listsubjects = cell(length(subject_list), 1);
% numcomponents = zeros(length(subject_list), 1);
% numepochs = cell(length(subject_list), 1);
% interchans = cell(length(subject_list), 1);
diagnostTable = cell(2 , 4);

for s = 1:2 %:length(subject_list)
    
    % CURRENT SUBJECT
    subject = subject_list{s};
    subject = extractBefore(subject, file_ext);
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    EEG = pop_loadset('filename',[subject '_Filt.set'],'filepath', rsdir); % DATA BEFORE ASR
    originalchanlocs = EEG.chanlocs; % FOR INTERPOLATION LATER
    oldchans = {EEG.chanlocs.labels};
    
    % LOAD FILES WITH ICA WEIGHTS
    EEG = pop_loadset('filename',[subject '_ICA_Weights.set'],'filepath', rsdir);
    
    % SAVE LIST OF CHANNELS REMOVED WITH ASR FOR DIAGNOSTICS
    chandiff = setdiff(oldchans, {EEG.chanlocs.labels});
    
    % RUN ICLABEL(Pion-Tonachini et al., 2019) TO LABEL COMPONENTS
    EEG = pop_iclabel(EEG, 'default');
     
    % MARK COMPONENTS WITH >= 90% PROBABILITY OF BEING NON-BRAIN COMPONENTS
    EEG = pop_icflag(EEG, ...
        [NaN NaN;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1]);
    EEG.setname = [subject '_ICA_marked']; % NAME FOR DATASET MENU
    EEG = eeg_checkset(EEG, 'ica');
     
    % SAVE DATA WITH COMPONENTS MARKED FOR REMOVAL
    if (save_everything)
        EEG = pop_saveset(EEG, ...
            'filename',[subject '_ICA_Marked.set'], ...
            'filepath', rsdir);
    end
    
    EEG = pop_loadset('filename',[subject '_ICA_Marked.set'],'filepath', rsdir);
    numcomponents(s) = {length(find(EEG.reject.gcompreject == 1))}; % SAVE # OF REMOVED ICs
    
    % REMOVE SELECTED COMPONENTS
    EEG = pop_subcomp(EEG, ...
        find(EEG.reject.gcompreject == 1), ...
        0);
    EEG.setname = [subject '_ICA_Removed']; % NAME FOR DATASET MENU
     
    % SAVE DATA WITH COMPONENTS REMOVED
    if (save_everything)
        EEG = pop_saveset(EEG, ...
            'filename',[subject '_ICA_Removed.set'], ...
            'filepath', rsdir);
    end
     
    %% POST-ICA - INTERPOLATION
     
    % INTERPOLATE CHANNELS USING ORIGINAL CHANNEL LOCATIONS
    EEG = pop_interp(EEG, originalchanlocs, 'spherical');
    EEG.setname = [subject '_Interp']; % NAME FOR DATASET MENU
     
    % SAVE ICA PROCESSED DATA
    if (save_everything)
        EEG = pop_saveset(EEG, ...
            'filename',[subject '_Interp.set'], ...
            'filepath', rsdir);
    end
    
    %% CREATING OVERLAPPING EPOCHS
    
    % CONCATENATE THE EPOCHS INTO CONTINUOUS DATA BEFORE CREATING OVERLAPPING EPOCHS
    EEG = pop_epoch2continuous(EEG, 'Warning', 'off');
    
    % REMOVE ALL EVENT-VALUES
    EEG = pop_editeventvals(EEG,'delete', 1:length(EEG.event));
    
    % CREATE EPOCHS OF 2 SEC, WITH 75% OVERLAP (0.5 s RECURRENCE) 
    EEG = eeg_regepochs(EEG, 'recurrence', 0.5, ...
        'limits', [0 2], ...
        'rmbase', NaN); 
    EEG.setname = [subject '_Epoch']; % NAME FOR DATASET MENU
    
    % SAVE DATA WITH OVERLAPPING EPOCHS
    if (save_everything)
    EEG = pop_saveset(EEG, 'filename',[subject '_Epoch.set'], ...
        'filepath', rsdir);
    end
    
    EEG = pop_loadset('filename',[subject '_Epoch.set'],'filepath', rsdir);
    
    % REMOVE VEOG CHANNEL
    EEG = pop_select(EEG, ...
        'nochannel', {'VEOG'});
    EEG.setname = [subject '_Preprocessed.set']; % NAME FOR DATASET MENU
     
    % SAVE PRE-PROCESSED DATA
    EEG = pop_saveset(EEG, ...
        'filename',[subject '_Preprocessed.set'], ...
        'filepath', final);
    
    % STORE NUMBER OF EPOCHS AND INTERPOLATED CHANNELS FOR EACH SUBJECT
    listsubjects(s) = {subject};
    numepochs(s) = {length(EEG.epoch)};
    interchans(s) = {length(chandiff)};
    
end

% CREATE TABLE OF EPOCHS, INTERPOLATED CHANNELS, AND REMOVED INDEPENDENT COMPONENTS PER SUBJECT
listsubjects = listsubjects';
interchans = interchans';
numepochs = numepochs';
numcomponents = numcomponents';
diagnostTable(:, 1) = listsubjects;
diagnostTable(:, 2) = interchans;
diagnostTable(:, 3) = numepochs;
diagnostTable(:, 4) = numcomponents;
diagnostTable = cell2table(diagnostTable);
diagnostTable.Properties.VariableNames = {'Subject', 'Interpolated_Chans', 'Number_Overlapping_Epochs', 'Removed_ICs'};

% SAVE INTERPOLATED CHANNELS AS .MAT IN FOLDER Saved_Variables
cd (savevars);
% save Diagnostics.mat diagnostTable
writetable(diagnostTable, 'Diagnostics.csv', 'Delimiter',',','QuoteStrings',false)
% save InterpolatedChannels.mat interchans
% save NumberOfEpochs.mat numepochs

fprintf('\n\n\n**** LEMON PREPROCESSING 2 FINISHED ****\n\n\n');
