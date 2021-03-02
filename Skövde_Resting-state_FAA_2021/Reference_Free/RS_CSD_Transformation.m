clear;
clc;
%% SET UP FILES AND FOLDERS

% MAKE SURE EEGLAB IS IN PATH
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2020_0');
% WORKING DIRECTORY
cd 'D:\FAA_Study_2021\Skovde\Skovde_EEG'

% SET EEGLAB PREFERENCES
pop_editoptions('option_storedisk', 1);
pop_editoptions( 'option_single', 0);

% PATH TO THE NECESSARY FOLDERS
eegfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\';
rawfolder = 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_RAW\';
final = [eegfolder 'EEG_Preprocessed'];
csddir = [eegfolder 'CSDtoolbox'];

% ADD CSDTOOLBOX (WHICH IS IN EEGFOLDER) AND SUBFOLDERS TO PATH
addpath(genpath(csddir));

% DEFINE THE SET OF SUBJECTS
subject_list = {'sub-002', 'sub-005', 'sub-006', 'sub-008', 'sub-009', ...
    'sub-011', 'sub-013', 'sub-014', 'sub-015', 'sub-019', ...
    'sub-020', 'sub-021', 'sub-022', 'sub-025', 'sub-027', ...
    'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

%% GENERATE EEG MONTAGE AND TRANSFORMATION MATRICES

% LOAD PREPROCESSED DATA FOR ONE SUBJECT
EEG = pop_loadset('filename', 'sub-002_EO_Preprocessed.set','filepath', final);

% CREATE A COLUMN VECTOR OF CHANNEL LABELS BY TRANSPOSITION
electrodes = {EEG.chanlocs.labels}';
    
% SPECIFY AN EEG MONTAGE OF THE SPATIAL ELECTRODE LOCATIONS USING THE
% CSD TOOLBOX. THE HEAD IS REPRESENTED AS A UNIT SPHERE (RADIUS OF 1)
montage = ExtractMontage('10-5-System_Mastoids_EGI129.csd', electrodes);
    
% GENERATE THE ELECTRODES X ELECTRODES TRANSFORMATION MATRICES 'G' AND
% 'H' THAT THE SURFACE LAPLACIAN IN THE CSD TOOLBOX IS BASED ON.
% 'G' USED FOR SPHERICAL SPLINE INTERPOLATION OF SURFACE POTENTIALS
% 'H' USED FOR CURRENT SOURCE DENSITIES
[G, H] = GetGH(montage); % SPLINE FLEXIBILITY(m) = 4 (DEFAULT)
    
% SAVE G AND H TO LATER IMPORT WHEN COMPUTING THE CSD TRANFORM
save CSDmontage.mat G H montage;

%% SURFACE LAPLACIAN TRANSFORMATION

% LOOP THROUGH ALL SUBJECTS IN THE EYES OPEN CONDITION
for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED EO DATASETS
    EEG_EO = pop_loadset('filename',[subject '_EO_Preprocessed.set'],'filepath', final);
    CSDdata_EO = repmat(NaN,size(EEG_EO.data)); % INITIALIZE
    
    % APPLY THE SURFACE LAPLACIAN TRANSFORM TO EACH EPOCH
    % SMOOTHING CONSTANT(LAMBDA) = 0.00001 = 1.0e-5
    % HEAD RADIUS = 10CM -> RETURNS VALUES OF uV/cm^2
    for ep = 1:length(EEG_EO.epoch)
        Data = squeeze(EEG_EO.data(:,:,ep)); % DATA CONTAINS EEG SIGNALS TO BE TRANSFORMED
        X = CSD(Data, G, H); % X IS THE CSD ESTIMATE OF DATA. 
        CSDdata_EO(:,:,ep) = X;   
    end
    EEG_EO.data = CSDdata_EO; % REPLACE EEG DATA WITH CSD ESTIMATES
    
    % SAVE CSD TRANSFORMED DATA. NOTE: DATA CONTAINS CSD ESTIMATES, NOT EEG SIGNALS
    EEG_EO.setname = [subject '_EO_CSD_Estimates']; % NAME FOR DATASET MENU
    EEG_EO = pop_saveset(EEG_EO, ...
         'filename',[subject '_EO_CSD_Estimates.set'], ...
         'filepath', final);

     CSDdata_EO(:,:,:) = NaN;    % RE-INITIALIZE DATA OUTPUT
     
     CSDALL_EO{s} = CSDdata_EO   % REMOVE LATER
end

clear s ep Data X

% LOOP THROUGH ALL SUBJECTS IN THE EYES CLOSED CONDITION
for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED EO DATASETS
    EEG_EC = pop_loadset('filename',[subject '_EC_Preprocessed.set'],'filepath', final);
    CSDdata_EC = repmat(NaN,size(EEG_EC.data)); % INITIALIZE
    
    % APPLY THE SURFACE LAPLACIAN TRANSFORM TO EACH EPOCH
    % SMOOTHING CONSTANT(LAMBDA) = 0.00001 = 1.0e-5
    % HEAD RADIUS = 10CM -> RETURNS VALUES OF uV/cm^2
    for ep = 1:length(EEG_EC.epoch)
        Data = squeeze(EEG_EC.data(:,:,ep)); % DATA CONTAINS EEG SIGNALS TO BE TRANSFORMED
        X = CSD(Data, G, H); % X IS THE CSD ESTIMATE OF DATA
        CSDdata_EC(:,:,ep) = X;   
    end
    EEG_EC.data = CSDdata_EC; % REPLACE EEG DATA WITH CSD ESTIMATES
    
    % SAVE CSD TRANSFORMED DATA. NOTE: DATA CONTAINS CSD ESTIMATES, NOT EEG SIGNALS
    EEG_EO.setname = [subject '_EC_CSD_Estimates']; % NAME FOR DATASET MENU
    EEG_EO = pop_saveset(EEG_EO, ...
         'filename',[subject '_EC_CSD_Estimates.set'], ...
         'filepath', final);

     CSDdata_EC(:,:,:) = NaN;    % RE-INITIALIZE DATA OUTPUT
     
     CSDALL_EC{s} = CSDdata_EC   % REMOVE LATER
end

fprintf('\n\n\n**** CSD FINISHED ****\n\n\n');
