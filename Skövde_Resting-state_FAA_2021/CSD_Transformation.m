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
final = [ eegfolder 'EEG_Preprocessed'];

% CREATE FOLDER TO SAVE FILES IN
if ~exist('EEG_TFA', 'dir')
    mkdir EEG_Preprocessed EEG_TFA;
end
tfadir = [final filesep 'EEG_TFA'];

% DEFINE THE SET OF SUBJECTS THAT WERE ETHICALLY APPROVED
subject_list = {'sub-002', 'sub-005', 'sub-006', 'sub-008', 'sub-009', ...
    'sub-011', 'sub-013', 'sub-014', 'sub-015', 'sub-019', ...
    'sub-020', 'sub-021', 'sub-022', 'sub-025', 'sub-027', ...
    'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

%% CURRENT SOURCE DENSITY (CSD) TRANSFORMATION

% LOOP THROUGH ALL SUBJECTS
for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % PATH TO THE FOLDER CONTAINING THE CURRENT SUBJECT'S DATA
    subjectfolder = [rawfolder subject '\'];
    
    % LOAD PREPROCESSED EO AND EC DATASETS
    EEG_EO = pop_loadset('filename',[subject '_EO_Preprocessed.set'],'filepath', final);
    EEG_EC = pop_loadset('filename',[subject '_EC_Preprocessed.set'],'filepath', final);
    
    % GENERATE CSD. REQUIRES MANUALLY CLICKING ON "GENERATE CSD" IN POP-UP
    % CAN IT BE MADE AUTMOATIZED?
    pop_currentsourcedensity(EEG_EO);
    pop_currentsourcedensity(EEG_EC);
    
    % ADD CSD CHANNEL LOCATIONS. CURRENTLY UNCHECKS LM AND RM
%     EEG_EO = pop_chanedit(EEG_EO, 'load',{[eegfolder 'loc_eeglab_for_CSD.ced'], ...
%         'filetype', 'autodetect'}, ...
%         'changefield', {29, 'datachan', 0}, ...
%         'changefield', {28, 'datachan', 0});
%     EEG_EC = pop_chanedit(EEG_EC, 'load', {[eegfolder 'loc_eeglab_for_CSD.ced'], ...
%         'filetype', 'autodetect'}, ...
%         'changefield', {29, 'datachan', 0}, ...
%         'changefield', {28, 'datachan', 0});
    
    % SAVE CSD TRANSFORMED DATA
    EEG_EO = pop_saveset(EEG_EO, ...
         'filename',[subject '_EO_CSD.set'], ...
         'filepath', final);
     EEG_EC = pop_saveset(EEG_EC, ...
         'filename',[subject '_EC_CSD.set'], ...
         'filepath', final);
     
end

fprintf('\n\n\n**** CSD FINISHED ****\n\n\n');