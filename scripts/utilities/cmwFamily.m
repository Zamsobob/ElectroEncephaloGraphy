function wavefam = cmwFamily(varargin)
% wavefam = cmwFamily(frex, nCycles, wavtime)
%
% Create a family of complex Morlet wavelets, defined as complex sine wave
% tapered by a Gaussian. Specify the frequencies of the wavelets and the
% width of the Gaussian, which decides the trade-off between
% precision in the time-domain and in the frequency-domain.
%
% The time-window of non-zero energy of each wavelet is a function of
% the width of the Gaussian and the frequency. Higher frequency means that
% the same number of cycles is much narrower in time.
%
% It is often a good idea to have a variable number of cycles to balance the time-frequency
% trade-off. The trade-off then changes as a function of frequency. This
% means that each frequency (in TF plot) has its own number of cycles. This
% usually starts off with a low number of cycles and increases.
%
% INPUTS:
%
% frex              a vector or scalar of wavelet frequencies.
%                   Example: linspace(2,40,42) gives wavelet frequencies
%                   ranging from 2 to 40 Hz in 42 linearly spaced steps
% nCycles           Number of cycles. Parameter to decide "the width of the
%                   Gaussian". Decides the trade-off between precision in the
%                   time-domain and in the frequency-domain.
%                   Gaussian formula: exp( (-t.^2) ./ (2*s^2) ), where
%                   t is time and s = nCycles / (2*pi*frex).
%                   Example: linspace(3,15,42) increases from 3 to 15 cycles
%                   with linearly increasing wavelet peak frequency
% wavtime           Optional input to specify the wavelet time-vector 
%                   (t in the formula above). Default: -2:1/EEG.srate:2
%
% OUTPUTS:
% wavefam           a family of complex Morlet wavelets (wavelets that
%                   share similar properties but vary over frequencies)
%
% code written by <Martin Nilsson> <nilssonm49@gmail.com>


%% Get input arguments

% createFigures

% Get input arguments
if nargin < 2
    help cmwFamily
    error('Error: Not enough input arguments.')
elseif nargin < 3
    frex      = varargin{1};
    nCycles   = varargin{2};
    wavtime   = -2:1/EEG.srate:2; % default
else
    frex    = varargin{1};
    nCycles = varargin{2};
    wavtime = varargin{3};
end

%% Create a family of complex Morlet Wavelets

% if nCycles value is constant, then create a vector with numfrex
% identical values
if length(nCycles) == 1
    nCycles = repmat(nCycles,size(frex));
end

wavefam  = zeros(length(frex),length(wavtime)); % initialize
% create time-domain wavelets
for fi=1:length(frex)
    s             = nCycles(fi)/(2*pi*frex(fi)); % frequency-normalized width of Gaussian
    wavefam(fi,:) = exp(2*1i*pi*frex(fi).*wavtime) .* exp( (-wavtime.^2) ./ (2*s^2) );
end

%plot(wavtime,real(wavefam(10,:)),wavtime,imag(wavefam(10,:)),wavtime,abs(wavefam(10,:)))
        % confirm spectrum of wavelet is Gaussian
%         hz        = linspace(0,EEG.srate,nKern);
%         wavespect = 2*abs(fft(wavefam(1,:)))/nKern;
%         plot(hz,wavespect) % freq x-axis
%         % or plot(abs(wavefam(1,:)))

% default wavtime but possible to specify?
% Be able to both specify fixed width of Gaussian and varying? To
% test different parameters easily.


