function param = echo_xcorr_profile(profile_name,varargin)
% param = echo_xcorr_profile(profile_name,varargin)
%
% Fast-time cross correlation parameter profiles.
%
% INPUTS:
%
% profile_name: string containing profile name
%
% varargin: name value pairs (even input arguments give the field to update such
% as "h_filt_offset" and odd input arguments give the value).
%
% OUTPUTS:
%
% param: parameters for the selected profile with the varargin updates
% applied
%
% Examples:
%
% See echo_xcorr.m
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

switch (profile_name)
  case {'','short_unitstep'} % RDS
    param.h_filt = fliplr([0.1*ones(1,6) 0.5*ones(1,7)]);
    param.h_filt = param.h_filt-mean(param.h_filt);
    param.h_filt_offset = -4;
  case 'long_unitstep' % RDS long
    param.h_filt = fliplr([0.1*ones(1,10) 0.5*ones(1,11)]);
    param.h_filt = param.h_filt-mean(param.h_filt);
    param.h_filt_offset = -8;
  case 'xlong_unitstep' % Accum or UWB RDS
    param.h_filt = fliplr([0.1*ones(1,20) 0.5*ones(1,21)]);
    param.h_filt = param.h_filt-mean(param.h_filt);
    param.h_filt_offset = -16;
  case 'xxlong_unitstep' % Snow
    param.h_filt = fliplr([0.1*ones(1,50) 0.5*ones(1,51)]);
    param.h_filt = param.h_filt-mean(param.h_filt);
    param.h_filt_offset = -40;
  case 'snow' % Snow layer
    param.h_filt = fliplr([0.1*ones(1,21) 4*ones(1,5) 0.5*ones(1,21)]);
    param.h_filt = param.h_filt-mean(param.h_filt);
    param.h_filt_offset = -20; %-48
  case 'peaky' % Enhance peaky as opposed to unit step responses
    param.h_filt = [0.1 0.1 0.4 0.5 0.4 0.1 0.1];
    param.h_filt = param.h_filt-mean(param.h_filt);
    param.h_filt_offset = -3;
  case 'short_unitstep+peaky' % Enhance peaky with unit step responses
    param.h_filt = fliplr([0.1*ones(1,6) 0.5*ones(1,7)]) + [0 0 0 0.1 0.1 0.4 0.5 0.4 0.1 0.1 0 0 0];
    param.h_filt = param.h_filt-mean(param.h_filt);
    param.h_filt_offset = -4;
  otherwise
    error('Profile %s does not exist.', profile_name);
end

% Assign custom name-value pairs
if nargin > 1
  for idx = 3:2:nargin
    if strcmpi(varargin{idx-2},'h_filt_len')
      % Handle special case to make generic h_filt from h_filt_len
      % parameter
      param.h_filt = fliplr([0.1*ones(1,varargin{idx-1}) 0.5*ones(1,varargin{idx-1}+1)]);
      param.h_filt = param.h_filt-mean(param.h_filt);
    else
      param.(varargin{idx-2}) = varargin{idx-1};
    end
  end
end