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

for s = 1
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED DATA FOR ONE SUBJECT
    EEG = pop_loadset('filename',[subject '_EO_Preprocessed.set'],'filepath', final);

    % CREATE COLUMN VECTORS OF CHANNEL LABELS BY TRANSPOSITION
    electrodes = {EEG.chanlocs.labels}';
    
    % SPECIFY AN EEG MONTAGE OF THE SPATIAL ELECTRODE LOCATIONS WITH THE
    % CSD TOOLBOX. THE HEAD IS REPRESENTED AS A UNTI SPHERE (RADIUS OF 1)
    montage = ExtractMontage('10-5-System_Mastoids_EGI129.csd', electrodes);
    
    % Generate the transformation matrices “G” and “H.” The surface Laplacian transform in CSD
    % toolbox is based on two “electrodes-by-electrodes” transformation matrices “G” and “H”
    [G, H] = GetGH(montage);
    
    % SAVE G AND H TO LATER IMPORT WHEN COMPUTING THE CSD TRANFORM
    cd 'Saved_Variables';
    save CSDmontage.mat G H montage;
    cd 'D:\FAA_Study_2021\Skovde\Skovde_EEG'
end

%% CURRENT SOURCE DENSITY (CSD) TRANSFORMATION

% LOOP THROUGH ALL SUBJECTS IN THE EYES OPEN CONDITION
for s = 1:numsubjects
    
    % LOAD PREPROCESSED EO DATASETS
    EEG = pop_loadset('filename',[subject '_EO_Preprocessed.set'],'filepath', final);
    
    
    % APPLY THE SURFACE LAPLACIAN TRANSFORM TO EVERY EPOCH
    for i = 1:size(EEG.data, 3)
        
        D = squeeze(EEG.data(:,:,i));
        X = CSD(D, G, H); % X IS THE CSD ESTIMATES
        CSDdata(:,:,i) = X;
        
    end
    EEG.data = CSDdata; % REPLACE EEG DATA WITH CSD ESTIMATES
    EEG = eeg_checkset(EEG);
    EEG.setname = [subject '_EO_Preprocessed_CSD_Estimates']; % NAME FOR DATASET MENU
    
    % SAVE CSD TRANSFORMED DATA. NOTE: DATA CONTAIN CSD ESTIMATES, NOT EEG SIGNALS
    EEG = pop_saveset(EEG, ...
         'filename',[subject '_EO_Preprocesseed_CSD_Estimates.set'], ...
         'filepath', final);
     
     clear i EEG D X CSDdata
     
end

% LOOP THROUGH ALL SUBJECTS IN THE EYES CLOSED CONDITION
for s = 1:numsubjects
    
    % LOAD PREPROCESSED EC DATASETS
    EEG = pop_loadset('filename',[subject '_EC_Preprocessed.set'],'filepath', final);
    
    
    % APPLY THE SURFACE LAPLACIAN TRANSFORM TO EVERY EPOCH
    for i = 1:size(EEG.data, 3)
        
        D = squeeze(EEG.data(:,:,i));
        X = CSD(D, G, H); % X IS THE CSD ESTIMATES
        CSDdata(:,:,i) = X;
        
    end
    EEG.data = CSDdata; % REPLACE EEG DATA WITH CSD ESTIMATES
    EEG = eeg_checkset(EEG);
    EEG.setname = [subject '_EC_Preprocessed_CSD_Estimates']; % NAME FOR DATASET MENU
    
    % SAVE CSD TRANSFORMED DATA. NOTE: DATA CONTAIN CSD ESTIMATES, NOT EEG SIGNALS
    EEG = pop_saveset(EEG, ...
         'filename',[subject '_EC_Preprocesseed_CSD_Estimates.set'], ...
         'filepath', final);
     
     clear i EEG D X CSDdata
     
end

% REREF??
fprintf('\n\n\n**** CSD FINISHED ****\n\n\n');
