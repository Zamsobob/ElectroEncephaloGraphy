function [powrSpec,amplSpec, hz] = fft_powerAndAmpl(EEG)
% [powrSpec,amplSpec, hz] = fft_powerAndAmpl(EEG)
% Computes the power and amplitude of an input signal
% using the Fast Fourier Transform (FFT).
%
% Power and amplitude highlight different features of the data.
% Amplitude spectrum highlights more subtle features, while power
% spectrum highlights more prominent features.
%
% For 2D data, the spectra are calculated by taking the FFT of
% the entire signal (across time). For 3D data, the spectra is
% calculated by taking the FFT of each trial (across time).
%
% INPUTS:
%
% EEG            EEG structure containing the field EEG.data, which can be
%                either 2D (channels x time-points) or
%                3D (channel x time-points x trials). 
%
% OUTPUTS:
% powrSpec       power spectrum (uV^2) with the same dimensions as the input data.
%
% amplSpec       Amplitude spectrum (uV) with the same dimensions as the input data.
%
% Hz             Vector of frequencies (linearly spaced between 0 and Nyquist frequency).     
%
% code written by <Martin Nilsson> <nilssonm49@gmail.com>


% EEG.FFT
% EEG.Welch

% Power and amplitude highlight different features of the data.
% Amplitude spectrum highlights more subtle features, while power
% spectrum highlights more prominent features.

% 2D chan x time or 3D chan x time x trials



%% Static spectral analysis

% Vector of frequencies (0 to Nyquist)
hz = linspace(0,EEG.srate/2,floor(EEG.pnts/2)+1);

%% if 3D
if length(size(EEG.data)) == 3
amplSpec              = abs(fft(EEG.data,[],2) / EEG.pnts);
amplSpec              = amplSpec(:,1:length(hz),:); % extract "positive" frequencies
amplSpec(:,2:end-1,:) = 2*amplSpec(:,2:end-1,:); % Double non-DC, non-Nyq freqs (now in uV)

% power spectrum (uV^2)
powrSpec              = amplSpec.^2; % chan x freqs x trials

% average over trials
% avgPowr               = mean(powrSpec,3); % chan x freqs

%% if 2D
elseif length(size(EEG.data)) == 2
% Fourier spectrum
fCoefs              = fft(EEG.data,[],2)/EEG.pnts; % Fourier coefficients

% ampltiude spectrum (uV)
amplSpec            = abs(fCoefs); % Compute amplitudes
amplSpec            = amplSpec(:,1:length(hz)); % extract "positive" frequencies
amplSpec(:,2:end-1) = 2*amplSpec(:,2:end-1); % Double non-DC, non-Nyq freqs (now in uV)
% phaseSpec         = angle(fCoefs);

% power spectrum (uV^2)
powrSpec            = amplSpec.^2;

else
    error('EEG.data needs to be either 2D or 3D!')
end
