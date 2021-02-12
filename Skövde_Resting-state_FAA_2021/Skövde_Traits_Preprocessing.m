% Clear memory and the command window
clear;
clc;

% Make sure EEGlab is in path
addpath('C:\Users\Mar Nil\Desktop\MATLABdirectory\eeglab2020_0')
% Working directory should be :D
cd 'D:\FAA_Study_2021\Skovde\Skovde_Traits_FAA\Skovde_EEG\EEG_RAW'


% This defines the set of subjects
% subject 24 missing. Cancelled participation?
subject_list = {'sub-001', 'sub-002', 'sub-003', 'sub-004', 'sub-005', 'sub-006', 'sub-007', 'sub-008', 'sub-009', 'sub-010', 'sub-011', 'sub-012', 'sub-013', 'sub-014', 'sub-015', 'sub-016', 'sub-017', 'sub-018', 'sub-019', 'sub-020', 'sub-021', 'sub-022', 'sub-023', 'sub-025', 'sub-026', 'sub-027', 'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032'};
numsubjects = length(subject_list);

% Path to the parent folder, which contains the data folders for all subjects
parentfolder = 'D:\FAA_Study_2021\Skovde\Skovde_Traits_FAA\Skovde_EEG\EEG_RAW\';

% Initialize the ALLERP structure and CURRENTERP
% ALLERP = buildERPstruct([]);
% CURRENTERP = 0;
% ALLEEG? [ALLEEG EEG CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

% Loop through all subjects
for s = 1:numsubjects
    
    subject = subject_list{s};
    
    % Path to the folder containing the current subject's data
    subjectfolder = [ parentfolder subject '\'];

    % Import data. FIX.
    EEG = pop_importdata('dataformat','matlab','nbchan',0,'data',[subjectfolder subject '.mat'],'srate',512,'pnts',0,'xmin',0);
    
    % Import event information (channel 18)
    % Where is the resting-state "trial" ? D? Talk to B. See Turku_Step1
    % Event 4 is resting-state? EEG.event
    % EEG = pop_chanevent(EEG, 18, 'edge', 'leading', 'edgelen', 0 );
    
    % Remove channel 1 (g.tec time channel) and 35 (empty channel).
    EEG = pop_select( EEG, 'nochannel', [1 35] );
    
    % Trim dataset?
    % EEG  = pop_eegtrim( EEG, 0, 3000 , 'post',  3000, 'pre',  0 );
    
    % Resample dataset from 512 to 256 Hz.
    EEG = pop_resample(EEG, 256);
    
    % Channel locations, filter etc.
    
    % Make new folders (preprocess, .set, etc). mkdir:
    % https://www.mathworks.com/help/matlab/ref/mkdir.html
end
     
