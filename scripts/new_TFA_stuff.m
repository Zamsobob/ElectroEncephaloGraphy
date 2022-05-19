%% TFA functions

%% Set up

% Potential soft-coded variables
projectPath = fileparts(fileparts( which('TFA.m') )); % Main branch - one step up from mfilename
utilitiesPath = dir(fullfile(projectPath,'**','utilities'));
addpath(utilitiesPath(1).folder)
fileExt = '.set'; % file extension of the raw data

% Create a list of subjects to loop through. Also returns the paths to the raw
% data and the file names
lists = extractSubjectFiles(projectPath, fileExt);

% Initialize EEGLAB structure
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
close all;
% EEGLAB options: use double precision, keep at most one dataset in memory
pop_editoptions('option_single', 0, ...
    'option_storedisk', 1);

% Load all subjects and store in ALLEEG structure
for sub = 1:length(lists)
    %     filePath = lists.dataPath(sub);
    EEG = pop_loadset('filename',lists(sub).fileName, ...
        'filepath', lists(sub).dataPath);
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, sub);
end

EEG = ALLEEG(1); % one subject for now

% struct with parameters for cmw and for TFA separately if I make
% this another function?
%% soft-code parameters
frex      = linspace(2, 40, 42); % frequency vector
nCycles   = linspace(3,15,42); % number of cycles
wavtime   = -2:1/EEG.srate:2; % length(wavtime) is odd (and symmetric around 0) - optional arg,default

% create a family of complex Morlet Wavelets
wavefam = cmwFamily(frex, nCycles, wavtime);

%% Plot a subset of the wavelets
figure(1)
tiledlayout(6,2, 'TileSpacing', 'compact')
for i = 1:4:42
    nexttile,hold on
    plot(wavtime,squeeze(real(wavefam(i,:))),'b')
    plot(wavtime,squeeze(imag(wavefam(i,:))),'r')
    plot(wavtime,squeeze(abs(wavefam(i,:))),'k')
    ylabel('Amplitude')
    title(['Wavelet at ' num2str(frex(i)) ' Hz' ])
end
xlabel(nexttile(11),'Time (s)')
nexttile
plot(frex,nCycles,'k')
xlabel('Frequency'), ylabel('Number of Cycles')
sgtitle('A subset of the complex Morlet wavelets')
% lg=legend(nexttile(2),{'real';'imag';'abs'});
% lg.Location = 'northeastoutside';

%% Convolution
% convolution parameters
nKern   = length(wavtime);
nData   = EEG.pnts*EEG.trials; % we will do TF decomposition for all trials
nConv   = nData + nKern -1; % Need nConv as output then. Want to be able to specify nKern as input too
halfwav = (length(wavtime)-1)/2;

% compute fourier coefficients of wavelet, then (max-value) normalize
wavefamX = zeros(numfrex,nConv);
for fj = 1:numfrex
    wavefamX(fj,:) = fft(wavefam(fj,:),nConv);
    wavefamX(fj,:) = wavefamX(fj,:) ./ max(wavefamX(fj,:));
end

%% Time-frequency decomposition


















%% ----------------------------------
% One way to define Morlet wavelet
% s = nCycles / (2*pi*frex)
% t = wavtime
% exp( -(t/s).^2 / 2 )

% OR (see Cohen, 2019)
% h = % fwhm: width of the Gaussian in seconds
% exp(-4*log(2)*t.^2 / h^2)

% -4log(2) normalization parameter

% As the Gaussian gets wider in time (nCycles increases),
% each estimated time-frequency point uses more time-points,
% which means we get lower temporal precision (think about convolution
% in the time-domain)
% The time-window of non-zero energy of the wavelet is a function of
% the width of the Gaussian and the frequency. Higher frequency means that
% the same number of cycles is much narrower in time.

% It is good to have a variable number of cycles to balance the time-frequency
% trade-off. The trade-off then changes as a function of frequency. This
% means that each frequency (in TF plot) has its own number of cycles. This
% usually starts off with a low number of cycles and increases.

% How to change the best parameter? It depends on if you are focusing more
% on temporal (few cycles) or spectral (more cycles) features of the data.




% formula for moving from nCycles to fwhms?


% Use this for lecture later and then I can delete notes here

%% Create a family of complex Morlet Wavelets

% set up convolution parameters
frex    = linspace(freqrange(1),freqrange(2),numfrex);
wavtime = -2:1/EEG.srate:2; % length(wavtime) is odd (and symmetric around 0)
nData   = EEG.pnts*EEG.trials; % we will do TF decomposition for all trials, not needed for this function
nKern   = length(wavtime); % nr of points of wavelets
nConv   = nData + nKern -1;
halfwav = (length(wavtime)-1)/2;
nCycles = linspace(3,15,numfrex); % number of cycles, increases as a function of frequency
% nCycles  = logspace(log10(4),log10(15),numfrex);
% fwhms    = linspace(.5,.3,numfrex);

% Will need specify length of the waves I want here, then specify same
% length when doign TFA. Interesting
% variable for Gaussian outside loop, depending on how it was specified
% create family of wavelets (wavelets that share similar properties but
% change over frequencies)
cmwX = zeros(numfrex,nConv);
cmw  = zeros(numfrex,nKern);
for fi=1:numfrex

    % create time-domain wavelet
    s   = nCycles(fi)/(2*pi*frex(fi)); % frequency-normalized width of Gaussian
    cmw(fi,:) = exp(2*1i*pi*frex(fi).*wavtime) .* exp( (-wavtime.^2) ./ (2*s^2) );

    % compute fourier coefficients of wavelet and (max-value) normalize
    cmwX(fi,:) = fft(cmw(fi,:),nConv);
    cmwX(fi,:) = cmwX(fi,:) ./ max(cmwX(fi,:));
end
%plot(wavtime,real(cmw(1,:)),wavtime,imag(cmw(1,:)),wavtime,abs(cmw(1,:)))
        % confirm spectrum of wavelet is Gaussian
        hz        = linspace(0,EEG.srate,nKern);
        wavespect = 2*abs(fft(cmw(1,:)))/nKern;
        plot(hz,wavespect) % freq x-axis
        % or plot(abs(cmwX(1,:)))

% default wavtime but possible to specify?
% Be able to both specify fixed width of Gaussian and varying? To
% test different parameters easily.

% see "extracting the three features of the complex wavelet result" uANTS.
% I want to extract all 3 features of the signal!

% Write reshape easier so I understand my own code! Probably 2 lines
% isntead of 1!

% see also figure(16) in uANTS_timefreq, but wavelet not just Gaussian

%figure
%plot(frex,nCycles,'s-')
% xlabel('Frequency'), ylabel('Number of Cycles')


% % specify log or lin scale as input
% % select a log or linear frequency scaling
% logOrLin = 'log';
% 
% % select frequency range
% if logOrLin(2)=='o'
%     frex = logspace(log10(freqrange(1)),log10(freqrange(2)),numfrex);
% else
%     frex = linspace(freqrange(1),freqrange(2),numfrex);
% end

% I need to try with different wavtimes to see if there are differences
% (maybe in simulated data too)

% just do both ncycles and fwhm and output whatever was specified?

% cosinder plotting images of wavelets (see NTSA_timefreq_wavelets.m)
% Also a good plot there of the wavelets (legend and all).