% SET VARIABLE TO 1 TO SAVE INTERMEDIATE STEPS. SET TO 0 TO SAVE
% ONLY THE NECESSARY FILES (RAW RS, EPOCHED EO AND EC, FINAL).
save_everything = 1;

%% SET UP FILES AND FOLDERS

% MAKE SURE EEGLAB IS IN PATH
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2021.0');
% WORKING DIRECTORY
cd 'D:\MPI_LEMON\EEG_MPILMBB_LEMON'

% SET EEGLAB PREFERENCES
pop_editoptions('option_storedisk', 1);
pop_editoptions('option_single', 0);

% DEFINE THE SET OF SUBJECTS
% 5 subjects removed from LEMON due to missing data:
% sub-010203. The VMRK-file is empty. 
% sub-010235, sub-010237, sub-010259, sub-010281, & sub-010293. No data in files.
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

% PATH TO THE EEG AND RAW FOLDERS
eegfolder = 'D:\MPI_LEMON\EEG_MPILMBB_LEMON\';
rawfolder = 'D:\MPI_LEMON\EEG_MPILMBB_LEMON\EEG_Raw_BIDS_ID\';

%PATH TO LOCALIZER FILE (INCLUDES CHANNEL LOCATIONS)
localizer = 'D:\MPI_LEMON\EEG_MPILMBB_LEMON\EEG_Localizer_BIDS_ID\'; % NOT SURE HERE

% CREATE FOLDERS FOR THE PREPROCESSED DATA
if~exist('EEG_Preprocessed', 'dir')
    mkdir 'EEG_Preprocessed'
end
ppfolder = [eegfolder 'EEG_Preprocessed\'];
cd 'D:\MPI_LEMON\EEG_MPILMBB_LEMON\EEG_Preprocessed'
    
if ~exist('RS_EO', 'dir')
    mkdir EEG_RS RS_EO
end
rsdir = [ppfolder 'EEG_RS'];
eodir = [ppfolder 'EEG_RS\RS_EO'];

if ~exist('RS_EC', 'dir')
    mkdir EEG_RS RS_EC
end
ecdir = [ppfolder 'EEG_RS\RS_EC'];

if ~exist('EEG_Final', 'dir')
    mkdir EEG_Final
end
final = [ppfolder 'EEG_Final'];

if ~exist('Saved_Variables', 'dir')
    mkdir Saved_Variables
end

%% LOADING RAW EEG RESTING-STATE DATA AND RELEVANT FILES

% LOOP THROUGH ALL SUBJECTS
for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD DATASET
    EEG = pop_loadset('filename',[subject '_ICA_Interp.set'],'filepath', rsdir);
    
    %% EYES CLOSED (EC) SEGMENTS
    
    % EXTRACT EC EPOCHS
    EEG_EC = pop_epoch(EEG, {'S210'}, [0 2], ...
        'newname', [subject '_EC'], ...
        'epochinfo', 'yes');
    
    % CONCATENATE THE EC EPOCHS
    EEG_EC = pop_epoch2continuous(EEG_EC, 'Warning', 'off');
    EEG_EC.setname = [subject '_EC']; % NAME FOR DATASET MENU

    % SAVE IN EC FOLDER
    if (save_everything)
        EEG_EC = pop_saveset(EEG_EC, 'filename',[subject '_EC.set'], ...
            'filepath', ecdir);
    end
    
    %% EYES OPEN (EO) SEGMENTS
    
    % EXTRACT EO EPOCHS
    EEG_EO = pop_epoch(EEG, {'S200'}, [0 2], ...
        'newname', [subject '_EO'], ...
        'epochinfo', 'yes');

    % CONCATENATE THE EO EPOCHS
    EEG_EO = pop_epoch2continuous(EEG_EO, 'Warning', 'off');
    EEG_EO.setname = [subject '_EO']; % NAME FOR DATASET MENU

    % SAVE IN EC FOLDER
    if (save_everything)
        EEG_EO = pop_saveset(EEG_EO, 'filename',[subject '_EO.set'], ...
            'filepath', eodir);
    end
    
    %% EPOCHING
    
    % REMOVE ALL EVENTS AND USE REGEPOCHS TO MAKE MY OWN (OVERLAPPING)
    EEG_EC = pop_editeventvals(EEG_EC,'delete', 1:length(EEG_EC.event));
    EEG_EO = pop_editeventvals(EEG_EO,'delete', 1:length(EEG_EO.event)); % EVENTS? EPOCHS?
    
    % CREATE EO AND EC EPOCHS OF 2.048 SEC, WITH 75% OVERLAP (0.512 s RECURRENCE) 
    EEG_EC = eeg_regepochs(EEG_EC, 'recurrence', 0.512, ...
        'limits', [-1.024 1.024], ...
        'rmbase', NaN); 
    EEG_EO = eeg_regepochs(EEG_EO, 'recurrence', 0.512, ...
        'limits', [-1.024 1.024], ...
        'rmbase', NaN);
    
    % REMOVE BASELINE (MEAN OF THE WHOLE EPOCH)
    EEG_EC = pop_rmbase(EEG_EC, [],[]);
    EEG_EC.setname = [subject '_EC_Epoch']; % NAME FOR DATASET MENU
    EEG_EO = pop_rmbase(EEG_EO, [],[]);
    EEG_EO.setname = [subject '_EO_Epoch']; % NAME FOR DATASET MENU
    
    % SAVE EO DATA IN EO FOLDER AND EC DATA IN EC FOLDER
    EEG_EC = pop_saveset(EEG_EC, 'filename',[subject '_EC_Epoch.set'], ...
        'filepath', ecdir);
     EEG_EO = pop_saveset(EEG_EO, 'filename',[subject '_EO_Epoch.set'], ...
        'filepath', eodir);
    
end
fprintf('\n\n\n**** LEMON SEGMENT FINISHED ****\n\n\n');
