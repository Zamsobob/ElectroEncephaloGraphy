function pathList = createAdditionalFolders(inputDir)
% pathStruct = createAdditionalFolders(inputDir)
% Sets up additional preprocessing folder structure inside a specified
% folder.
%
% INPUTS:
% inputDir:         a string vector of the path where the additional
%                   preprocessing folders should be created
% 
%
% OUTPUTS:
% pathList:         a struct containing the names of the additional folders
%

%% Setup additional folders
cd(inputDir);
% Specify names of additional preprocessing folders
pathList(1).preprocessingStep = '1_removeDC_hpfilt_resamp';
pathList(2).preprocessingStep = '2_removeDC_hpfilt_resamp_rerefMastoids';
pathList(3).preprocessingStep = '3_removeDC_hpfilt_resamp_rerefMastoid_remLineNoise';
pathList(4).preprocessingStep = '4_removeDC_hpfilt_resamp_rerefMastoid_remLineNoise_badChansRem';
pathList(5).preprocessingStep = '5_removeDC_hpfilt_resamp_rerefMastoid_remLineNoise_badChansRem_ICA_weights_labeled';
pathList(6).preprocessingStep = '6_removeDC_hpfilt_resamp_rerefMastoid_remLineNoise_badChansRem_ICA_weights_labeled_subcomp';

% Create the folders
for i = 1:length(pathList)
    mkdir(pathList(i).preprocessingStep);
end

