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
final = [eegfolder 'EEG_Preprocessed'];
csddir = [eegfolder 'CSDtoolbox'];

% ADD CSDTOOLBOX (WHICH IS IN EEGFOLDER) AND SUBFOLDERS TO PATH
addpath(genpath(csddir));

% DEFINE THE SET OF SUBJECTS THAT WERE ETHICALLY APPROVED
subject_list = {'sub-002', 'sub-005', 'sub-006', 'sub-008', 'sub-009', ...
    'sub-011', 'sub-013', 'sub-014', 'sub-015', 'sub-019', ...
    'sub-020', 'sub-021', 'sub-022', 'sub-025', 'sub-027', ...
    'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

%% GENERATE EEG MONTAGE AND TRANSFORMATION MATRICES

for q = 1 % ONLY ONE SUBJECT NEEDED SINCE THEY ALL HAVE THE SAME ELECTRODES
    
    subject = subject_list{q};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED DATA FOR ONE SUBJECT
    EEG = pop_loadset('filename',[subject '_EO_Preprocessed.set'],'filepath', final);

    % CREATE A COLUMN VECTOR OF CHANNEL LABELS BY TRANSPOSITION
    electrodes = {EEG.chanlocs.labels}';
    
    % SPECIFY AN EEG MONTAGE OF THE SPATIAL ELECTRODE LOCATIONS USING THE
    % CSD TOOLBOX. THE HEAD IS REPRESENTED AS A UNTI SPHERE (RADIUS OF 1)
    montage = ExtractMontage('10-5-System_Mastoids_EGI129.csd', electrodes);
    
    % GENERATE THE ELECTRODES BY ELECTRODES TRANSFORMATION MATRICES 'G' AND
    % 'H THAT THE SURFACE LAPLACIAN IN THE CSD TOOLBOX IS BASED ON.
    % 'G' USED FOR SPHERICAL SPLINE INTERPOLATION OF SURFACE POTENTIALS
    % 'H' USED FOR CURRENT SOURCE DENSITIES
    [G, H] = GetGH(montage); % SPLINE FLEXIBILITY m = 4 (DEFAULT)
    
    % SAVE G AND H TO LATER IMPORT WHEN COMPUTING THE CSD TRANFORM
    cd 'Saved_Variables';
    save CSDmontage.mat G H montage;
    cd 'D:\FAA_Study_2021\Skovde\Skovde_EEG'
end

%% CURRENT SOURCE DENSITY (CSD) TRANSFORMATION

% LOOP THROUGH ALL SUBJECTS IN THE EYES OPEN CONDITION
for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED EO DATASETS
    EEG = pop_loadset('filename',[subject '_EO_Preprocessed.set'],'filepath', final);
    
    
    % APPLY THE SURFACE LAPLACIAN TRANSFORM TO EACH EPOCH
    for i = 1:size(EEG.data, 3)
        D = squeeze(EEG.data(:,:,i)); % D CONTAINS EEG SIGNALS TO BE TRANSFORMED
        X = CSD(D, G, H); % X IS THE CSD ESTIMATE OF D
        CSDdata(:,:,i) = X;   
    end
    
    EEG.data = CSDdata; % REPLACE EEG DATA WITH CSD ESTIMATES
    EEG = eeg_checkset(EEG);
    EEG.setname = [subject '_EO_CSD_Estimates']; % NAME FOR DATASET MENU
    
    % SAVE CSD TRANSFORMED DATA. NOTE: DATA CONTAINS CSD ESTIMATES, NOT EEG SIGNALS
    EEG = pop_saveset(EEG, ...
         'filename',[subject '_EO_CSD_Estimates.set'], ...
         'filepath', final);
     
     clear i EEG D X CSDdata
     
end

clear s

% LOOP THROUGH ALL SUBJECTS IN THE EYES CLOSED CONDITION
for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED EC DATASETS
    EEG = pop_loadset('filename',[subject '_EC_Preprocessed.set'],'filepath', final);
    
    
    % APPLY THE SURFACE LAPLACIAN TRANSFORM TO EACH EPOCH
    for i = 1:size(EEG.data, 3)
        D = squeeze(EEG.data(:,:,i)); % D CONTAINS EEG SIGNALS TO BE TRANSFORMED
        X = CSD(D, G, H); % X IS THE CSD ESTIMATE OF D
        CSDdata(:,:,i) = X;
    end
    
    EEG.data = CSDdata; % REPLACE EEG DATA WITH CSD ESTIMATE
    EEG = eeg_checkset(EEG);
    EEG.setname = [subject '_EC_CSD_Estimates']; % NAME FOR DATASET MENU
    
    % SAVE CSD TRANSFORMED DATA. NOTE: DATA CONTAINS CSD ESTIMATES, NOT EEG SIGNALS
    EEG = pop_saveset(EEG, ...
         'filename',[subject '_EC_CSD_Estimates.set'], ...
         'filepath', final);
     
     clear i EEG D X CSDdata
     
end

% REREF??
fprintf('\n\n\n**** CSD FINISHED ****\n\n\n');
