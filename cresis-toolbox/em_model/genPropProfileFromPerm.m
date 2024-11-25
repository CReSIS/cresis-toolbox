function [TWtime,gain,depth,er] = genPropProfileFromPerm(depth,er,freq)
% [TWtime,gain] = genPropProfileFromPerm(depth,er,freq);
% depth = depth axis (m)
% e0*er = e0*(e' - j*e'') (F/m)
% freq = frequency (Hz) ... needed to compute loss when dielectric has a
%   nonzero imaginary part otherwise it has no effect.
% 
% depth must be a vector
% freq must be a row vector
% er must be a matrix (rows = length(depth), cols = length(freq))
% 
% TWtime = two-way time (sec)
% gain = two-way extinction through the ice (ratio of powers), includes
%   dielectric loss and transmissivity loss
%
% TWtime and gain will be a 2-D matrix of size = size(er)
%
% Depth Index
%     1       ---------------------------------- <-- INTERFACE IGNORED
%                           er(1)
%     2       ----------------------------------
%                           er(2)
%     3       ----------------------------------
%                           er(3)
%     4       ----------------------------------
%     .
%     .
%     .
%    n-1      ----------------------------------
%                           er(n-1)
%     n       ---------------------------------- (bedrock) <-- INTERFACE IGNORED
%                           er(n) <-- optional (not used) <-- LAYER IGNORED
%
% Antenna is assumed to be a point source on the depth index 1 interface.
% The TWtime(i) is the time after going through er(1) through er(i).
%   i.e. TWtime(1) is non-zero assuming depth(2) > depth(1)
% The gain(i) is the gain after going through er(1) through er(i).
%   i.e. gain(1) is less than one assuming depth(2) > depth(1)
%
% Example:
%   -----------------------------------------------------------------------
%   [depth,er] = summitPerm(195e6);
%   [TWtime,gain] = genPropProfileFromPerm(depth,er,195e6);
%   plot(depth(2:end),10*log10(gain))
%
%   -----------------------------------------------------------------------
%   freq = [150]*1e6;
%   depth = [1 2 3 4];
%   er = [1 1.7 1.9 2.1 2.5 3.15]';
%   [TWtime,gain] = genPropProfileFromPerm(depth,er,freq);
% 
%   -----------------------------------------------------------------------
%   freq = [120:10:160]*1e6;
%   depth = [1 2 3 4];
%   er = [1*ones(1,5)
%         1.7*ones(1,5)
%         2*ones(1,5)
%         3.15*ones(1,5)];
%   [TWtime,gain] = genPropProfileFromPerm(depth,er,freq);
% 
%   -----------------------------------------------------------------------
%   freq = 150e6;
%   [depth,er] = gisp2Perm(freq);
%   [TWtime,gain] = genPropProfileFromPerm(depth,er,freq);
%
% Author: John Paden

physical_constants;

if length(depth) == 1
  depth = [0 1];
  TWtime = [0 depth(end)/c*2*sqrt(er)];
  gain = [1 1];
  return;
end

w = 2*pi*freq;

% Preallocate memory
TWtime = zeros(length(depth)-1, size(er,2));
gain = ones(length(depth)-1, size(er,2));

% gamma is the propagation constant
gamma = j*sqrt(-j*w.*u0.*(j*w.*er(1,:)*e0));
% calculate current eta
eta_curr = (j*w.*u0./gamma);
% alpha is the attenuation constant
alpha = real(gamma);
% beta is the phase constant
beta = imag(gamma);
% velocity of propagation
lambda = 2*pi./beta;
vel = freq.*lambda;
% thickness of current layer
thick = depth(2)-depth(1);
% 2-way time and gain of current layer
TWtime(1,:) = 2*thick./vel;
gain(1,:) = exp(-4*alpha.*thick);

for n = 2:(length(depth)-1) 
  % grab previous eta
  eta_prev = eta_curr;
  % gamma is the propagation constant
  gamma = j*sqrt(-j*w.*u0.*(j*w.*er(n,:)*e0));
  % calculate current eta
  eta_curr = (j*w.*u0./gamma);
  % calculate reflection coeff
  reflection = (eta_curr - eta_prev)./(eta_curr + eta_prev);
  % calculate transmissivity
  tau = 1 - (abs(reflection).^2);
  % alpha is the attenuation constant
  alpha = real(gamma);
  % beta is the phase constant
  beta = imag(gamma);
  % velocity of propagation
  lambda = 2*pi./beta;
  vel = freq.*lambda;
  % thickness of current layer
  thick = depth(n+1)-depth(n);
  % 2-way time and gain of current layer
  TWtime(n,:) = TWtime(n-1,:) + 2*thick./vel;
  gain(n,:) = gain(n-1,:).*exp(-4*alpha.*thick).*tau;
end

TWtime = [0; TWtime];
