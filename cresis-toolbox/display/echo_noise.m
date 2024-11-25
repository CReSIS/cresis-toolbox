function noise = echo_noise(mdata, param)
% noise = echo_noise(mdata, param)
%
% Estimate the noise on each range line based on the parameters
%
% data: linear power echogram or an echogram struct with a field "Data"
% with a linear power echogram in it. If an echogram struct, the field
% "Time" may be required.
%
% param: structure defining how the noise is estimated
%   .method_fh: function handle to method for estimating noise in the
%   window
%
%   .valid_dB: 2 element numeric vector; specifies the valid range for the
%   noise-estimate; default is [-inf inf] which effectively disables this
%   valid noise-estimate range constraint;
%
%   .window: 2x1 or 2xN element numeric array; specifies the valid range
%   for the noise-estimate; default is [-inf; inf] which effectively
%   disables this valid noise-estimate range constraint; This parameter can
%   be specified for each range line by passing in a 2 x Nx array where
%   each column restricts the noise bins to be estimated
%
%   .window_units: string which indicates the units used for the window.
%   Default is 's' for seconds. If window is finite, then mdata must be a
%   structure with the Time variable and not just an image. '%' means
%   percentage ratio from 0 (start of fast-time) to 1 (end of fast-time).
%   'b' means range bins (rows).
%
% Example:
%
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_standard/20140512_01/Data_20140512_01_018.mat';
% mdata = load(fn);
%
% % Default [-inf inf] window, median fast-time and mean slow-time
% noise = echo_noise(mdata); plot(lp(noise));
%
% % Example using the bottom layer:
% bottom = layerdata.load_layers(mdata,'','bottom');
% noise = echo_noise(mdata, struct('window',[bottom+5e-6; inf(size(bottom))]));
% plot(lp(noise));
%
% % Example using the surface layer:
% surface = layerdata.load_layers(mdata,'','surface');
% noise = echo_noise(mdata, struct('window',[surface-100e-9; surface-75e-9]));
% plot(lp(noise));
%
% % Example using a time window:
% noise = echo_noise(mdata, struct('window',[-inf; inf])); plot(lp(noise));
%
% % Example using a percentage window 80-90%:
% noise = echo_noise(mdata, struct('window',[0.8; 0.9],'window_units','%')); plot(lp(noise));
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

%% Input checks

if isstruct(mdata)
  data = mdata.Data;
else
  data = mdata;
end

if ~exist('param','var') || isempty(param)
  param = [];
end

% method_fh: estimation method (e.g. @nanmean, @nanmedian, @mean or @median), default is @nanmedian
if ~isfield(param,'method_fh') || isempty(param.method_fh)
  param.method_fh = @nanmedian;
end

% window_units: string which indicates the units used for the window. Default is
% 's' for seconds. If window is finite, then mdata must be a structure with
% the Time variable and not just an image. '%' means percentage ratio from
% 0 (start of fast-time) to 1 (end of fast-time).
if ~isfield(param,'window_units') || isempty(param.window_units)
  param.window_units = 's';
end

% valid_dB: 2 element numeric vector; specifies the valid
% range for the noise-estimate; default is [-inf inf] which effectively
% disables this valid noise-estimate range constraint;
if ~isfield(param,'valid_dB') || isempty(param.valid_dB)
  param.valid_dB = [-inf inf];
end

% window: 2x1 or 2xN element numeric array; specifies the valid
% range for the noise-estimate; default is [-inf; inf] which effectively
% disables this valid noise-estimate range constraint; This parameter can
% be specified for each range line by passing in a 2 x Nx array where each
% column restricts the noise bins to be estimated
if ~isfield(param,'window') || isempty(param.window)
  param.window = [-inf; inf];
end
window = param.window;

Nt = size(data,1);
Nx = size(data,2);

if size(window,1) ~= 2 || (size(window,2) ~= 1 && size(window,2) ~= Nx)
  error('window must be a 2 x 1 or 2 x Nx matrix (where Nx is the number of columns in the echogram).');
end

%% Convert window to range bins
if param.window_units == '%' || isequal(window,[-inf; inf])
  window(1,:) = max(1,min(Nt,round(window(1,:)*Nt)));
  window(2,:) = max(window(1,:),min(Nt,round(window(2)*Nt)));
  
elseif param.window_units == 's'
  if ~isstruct(mdata)
    error('If param.window_units is "s", mdata must be an echogram struct since this echogram struct is used to determine the window.');
  end
  window(1,:) = min(Nt,max(1, interp1(mdata.Time,1:Nt,window(1,:),'nearest','extrap') ));
  window(2,:) = max(window(1,:),min(Nt, interp1(mdata.Time,1:Nt,window(2,:),'nearest','extrap') ));
  
elseif param.window_units == 'b'
  window = max(1,min(Nt,round(window)));
  
else
  error('param.window_units must be "s" for seconds, "b" for bins (rows), or "%" for percentage ratio 0 to 1.');
end

if size(window,2) == 1
  noise = param.method_fh(data(window(1):window(2),:));
  
else
  noise = nan(1,Nx);
  for rline = 1:Nx
    rbins = window(1,rline):window(2,rline);
    if ~isempty(rbins)
      noise(rline) = param.method_fh(data(rbins,rline));
    end
  end
end

noise = min(param.valid_dB(2), max(param.valid_dB(1), noise));
