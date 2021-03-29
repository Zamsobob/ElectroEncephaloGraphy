clear;
clc;
%% SET UP FILES AND FOLDERS

% MAKE SURE EEGLAB IS IN PATH
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2021.0');
% WORKING DIRECTORY
cd 'D:\MPI_LEMON\EEG_MPILMBB_LEMON'

% SET EEGLAB PREFERENCES
pop_editoptions('option_storedisk', 1);
pop_editoptions( 'option_single', 0);

% PATH TO THE NECESSARY FOLDERS
eegfolder = 'D:\MPI_LEMON\EEG_MPILMBB_LEMON\';
rawfolder = 'D:\MPI_LEMON\EEG_MPILMBB_LEMON\EEG_Raw_BIDS_ID\';
ppfolder = [eegfolder 'EEG_Preprocessed\'];
final = [ppfolder 'EEG_Final'];
csdfolder = [ppfolder 'RS_CSD'];
csddir = [eegfolder 'CSDtoolbox'];

% ADD CSDTOOLBOX (WHICH IS IN EEGFOLDER) AND SUBFOLDERS TO PATH
addpath(genpath(csddir));

% DEFINE THE SET OF SUBJECTS
subject_list = {'sub-010002', 'sub-010003', 'sub-010004', 'sub-010005', 'sub-010006', 'sub-010007', ...
    'sub-010010', 'sub-010010', 'sub-010012', 'sub-010015', 'sub-010016', 'sub-010017', 'sub-010019', ...
    'sub-010020', 'sub-010021', 'sub-010022', 'sub-010023', 'sub-010024', 'sub-010026', 'sub-010027', ...
    'sub-010028', 'sub-010029', 'sub-010030', 'sub-010031', 'sub-010032', 'sub-010033', 'sub-010034', ...
    'sub-010035', 'sub-010036', 'sub-010037', 'sub-010038', 'sub-010039', 'sub-010040', 'sub-010041', ...
    'sub-010042', 'sub-010044', 'sub-010045', 'sub-010046', 'sub-010047', 'sub-010048', 'sub-010049', ...
    'sub-010050', 'sub-010051', 'sub-010052', 'sub-010053', 'sub-010056', 'sub-010059', 'sub-010060', ...
    'sub-010061', 'sub-010062', 'sub-010063', 'sub-010064', 'sub-010065', 'sub-010066', 'sub-010067', ...
    'sub-010068', 'sub-010069', 'sub-010070', 'sub-010071', 'sub-010072', 'sub-010073', 'sub-010074', ...
    'sub-010075', 'sub-010076', 'sub-010077', 'sub-010078', 'sub-010079', 'sub-010080', 'sub-010081', ...
    'sub-010083', 'sub-010084', 'sub-010085', 'sub-010086', 'sub-010087', 'sub-010088', 'sub-010089', ...
    'sub-010090', 'sub-010091', 'sub-010092', 'sub-010093', 'sub-010094', 'sub-010100', 'sub-010104', ...
    'sub-010126', 'sub-010134', 'sub-010136', 'sub-010137', 'sub-010138', 'sub-010141', 'sub-010142', ...
    'sub-010146', 'sub-010148', 'sub-010150', 'sub-010152', 'sub-010155', 'sub-010157', 'sub-010162', ...
    'sub-010163', 'sub-010164', 'sub-010165', 'sub-010166', 'sub-010168', 'sub-010170', 'sub-010176', ...
    'sub-010183', 'sub-010191', 'sub-010192', 'sub-010193', 'sub-010194', 'sub-010195', 'sub-010196', ...
    'sub-010197', 'sub-010199', 'sub-010200', 'sub-010201', 'sub-010202', 'sub-010204', 'sub-010207', ...
    'sub-010210', 'sub-010213', 'sub-010214', 'sub-010215', 'sub-010216', 'sub-010218', 'sub-010219', ...
    'sub-010220', 'sub-010222', 'sub-010223', 'sub-010224', 'sub-010226', 'sub-010227', 'sub-010228', ...
    'sub-010230', 'sub-010231', 'sub-010232', 'sub-010233', 'sub-010234', 'sub-010236', 'sub-010238', ...
    'sub-010239', 'sub-010240', 'sub-010241', 'sub-010242', 'sub-010243', 'sub-010244', 'sub-010245', ...
    'sub-010246', 'sub-010247', 'sub-010248', 'sub-010249', 'sub-010250', 'sub-010251', 'sub-010252', ...
    'sub-010254', 'sub-010255', 'sub-010256', 'sub-010257', 'sub-010258', 'sub-010260', 'sub-010261', ...
    'sub-010262', 'sub-010263', 'sub-010264', 'sub-010265', 'sub-010266', 'sub-010267', 'sub-010268', ...
    'sub-010269', 'sub-010270', 'sub-010271', 'sub-010272', 'sub-010273', 'sub-010274', 'sub-010275', ...
    'sub-010276', 'sub-010277', 'sub-010278', 'sub-010279', 'sub-010280', 'sub-010282', 'sub-010283', ...
    'sub-010284', 'sub-010285', 'sub-010286', 'sub-010287', 'sub-010288', 'sub-010289', 'sub-010290', ...
    'sub-010291', 'sub-010292', 'sub-010294', 'sub-010295', 'sub-010296', 'sub-010297', 'sub-010298', ...
    'sub-010299', 'sub-010300', 'sub-010301', 'sub-010302', 'sub-010303', 'sub-010304', 'sub-010305', ...
    'sub-010306', 'sub-010307', 'sub-010308', 'sub-010309', 'sub-010310', 'sub-010311', 'sub-010314', ...
    'sub-010315', 'sub-010316', 'sub-010317', 'sub-010318', 'sub-010319', 'sub-010321'};
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
cd 'D:\FAA_Study_2021\Skovde\Skovde_EEG\EEG_CSD'
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
         'filepath', csdfolder);

     CSDdata_EO(:,:,:) = NaN;    % RE-INITIALIZE DATA OUTPUT
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
    EEG_EC.setname = [subject '_EC_CSD_Estimates']; % NAME FOR DATASET MENU
    EEG_EC = pop_saveset(EEG_EC, ...
         'filename',[subject '_EC_CSD_Estimates.set'], ...
         'filepath', csdfolder);

     CSDdata_EC(:,:,:) = NaN;    % RE-INITIALIZE DATA OUTPUT
end

fprintf('\n\n\n**** CSD FINISHED ****\n\n\n');

%% ------------------------------------------------------------------
% NOTES

% verify the integrity and correctness of the identified EEG montage with the function “MapMontage” in
% CSD toolbox by entering “MapMontage(montage)” in the MATLAB command window. This produces a
% topographical plot of the EEG montage. Very important.

% NEED TO MAKE SURE THAT I HAVE THE CORRECT POWER UNITS AFTER FOURIER TRANSFORM
% SEE PAGE 7:
% https://jallen.faculty.arizona.edu/sites/jallen.faculty.arizona.edu/files/Chapter_22_Surface_Laplacian.pdf 