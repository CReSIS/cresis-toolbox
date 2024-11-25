function data = echo_mult_suppress(mdata, layer, param)
% data = echo_mult_suppress(mdata, layer, param)
%
% Suppress surface multiple using the surface layer location.
%
% INPUTS:
%
% mdata = echogram struct from qlook.m or array.m. Echogram should be
% linear power. Struct must include .Data, .Roll, and .Time fields. If layer not
% passed in, then it must include the param field (param_qlook or
% param_array) and .GPS_time. mdata.Data should be linear power.
%
% param: struct controlling how the surface multiple suppression is done
%
%  .est_value_filter: Estimated surface multiple filter. Default is:
%   param.est_value_filter = [0 1 2 2 2 2 1];
%   20 * param.est_value_filter/sum(param.est_value_filter);
%
%  .guard_dB: threshold above noise floor that signal must remain to not
%  get removed. Default is 12.
%
%  .max_filt_len: Length of max_filt1 on surface values. Default is 11.
%
%  .multiple_loss_dB: Extra loss of surface multiple relative to surface
%  multiple. Default is 52.
%
%  .noise_bins: Bins relative to surface multiple to estimate background
%  power. Default is 20.
%
%  .noise_threshold_dB: threshold above noise floor for which surface
%  multiple corrected data will be set to NaN. Default is 5.
%
%  .window_units: scalar char either "s" for seconds or "b" for bins.
%  Default is "s".
%
% OUTPUTS:
%
% data: surface multiple suppressed input (2D matrix the same size as
% mdata.Data), linear power
%
% Examples:
%
% 
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_post/CSARP_standard/20140313_08/Data_20140313_08_001.mat';
% mdata = load(fn);
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_standard/20140512_01/Data_20140512_01_018.mat';
% mdata = load(fn);
%
% imagesc(lp(echo_mult_suppress(mdata)));
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

%% Input checks

data = mdata.Data;

if ~exist('layer','var') || isempty(layer)
  if isstruct(mdata)
    layers = layerdata(echo_param(mdata));
    layer = layers.get_layer_by_gps_time(mdata.GPS_time,'surface');
  else
    error('Layer must be defined if mdata is not an echogram struct since this echogram struct is used to load the default surface layer.');
  end
end

if layer > 1
  error('Layer must have units of two way travel time (seconds). Values greater than 1 occur.');
end

surf_bins = round(interp1(mdata.Time,1:length(mdata.Time),layer));
mult_bins = round(interp1(mdata.Time,1:length(mdata.Time),layer*2));

if ~exist('param','var') || isempty(param)
  param = [];
end

%  .est_value_filter: Estimated surface multiple filter
if ~isfield(param,'est_value_filter') || isempty(param.est_value_filter)
  param.est_value_filter = [0 1 2 2 2 2 1];
  %param.est_value_filter = [linspace(0,2,3+5) 2 2 2 1 zeros(1,5)]; % Longer tail
  param.est_value_filter = 20 * param.est_value_filter/sum(param.est_value_filter);
end
est_value_filter = param.est_value_filter;

%  .guard_dB: threshold above noise floor that signal must remain to not
%  get removed
if ~isfield(param,'guard_dB') || isempty(param.guard_dB)
  param.guard_dB = 12;
end
guard_dB = param.guard_dB;

%  .max_filt_len: Length of max_filt1 on surface values
if ~isfield(param,'max_filt_len') || isempty(param.max_filt_len)
  param.max_filt_len = 11;
end
max_filt_len = param.max_filt_len;

%  .multiple_loss_dB: Extra loss of surface multiple relative to surface
%  multiple
if ~isfield(param,'multiple_loss_dB') || isempty(param.multiple_loss_dB)
  param.multiple_loss_dB = 52;
end
multiple_loss_dB = param.multiple_loss_dB;

%  .noise_bins: Bins relative to surface multiple to estimate background
%  power
if ~isfield(param,'noise_bins') || isempty(param.noise_bins)
  param.noise_bins = [20];
end
noise_bins = param.noise_bins;

%  .noise_threshold_dB: threshold above noise floor for which surface
%  multiple corrected data will be set to NaN
if ~isfield(param,'noise_threshold_dB') || isempty(param.noise_threshold_dB)
  param.noise_threshold_dB = 5;
end
noise_threshold = 10.^(param.noise_threshold_dB/10);

%  .window_units: scalar char either "s" for seconds or "b" for bins
if ~isfield(param,'window_units') || isempty(param.window_units)
  param.window_units = 's';
end

% Convert param.window into bins
if param.window_units == 's'
  dt = mdata.Time(2) - mdata.Time(1);
  % window: two elements vector of window relative to layer to obtain
  % statistics
  if ~isfield(param,'window') || isempty(param.window)
    param.window = [-5*dt; 11*dt];
  end
  bins = round(param.window / dt);
  bins = bins(1):bins(end);
else
  if ~isfield(param,'window') || isempty(param.window)
    param.window = [-5; 11];
  end
  bins = param.window(1):param.window(end);
end

% Get surface and surface multiple layer statistics
param.inc_dec = 1;
[surf_value,~,~,~,surf_wfs] = echo_stats_layer(mdata,layer,param);
[mult_value,~,~,neighbor_power_mult,mult_wfs] = echo_stats_layer(mdata,layer*2,param);
surf_value = 10*log10(surf_value);
mult_value = 10*log10(mult_value);

Nt = size(data,1);
Nx = size(data,2);

%% Spherical spreading range loss (relative dB)
surf_spherical_spreading_loss_dB = 25*log10(layer);
surf_spherical_spreading_loss_dB = surf_spherical_spreading_loss_dB - min(surf_spherical_spreading_loss_dB);

surf_value_corr = surf_value + surf_spherical_spreading_loss_dB;
mult_value_corr = mult_value + 2*surf_spherical_spreading_loss_dB;

if 0
  % Check surface and multiple tracking
  figure(1); clf;
  imagesc(10*log10(data));
  hold on;
  plot(surf_bins.','r');
  plot(mult_bins.','g');
end

%% Estimate surface roll correction
mask = isfinite(mult_value_corr);
p_roll_surf_corr=polyfit(mdata.Roll(mask)*180/pi, surf_value_corr(mask),15);
if 0
  figure(2); clf;
  plot(mdata.Roll*180/pi, surf_value_corr,'.')
  hold on
  plot(mdata.Roll*180/pi, polyval(p_roll_surf_corr,mdata.Roll*180/pi),'r.');
  xlabel('Roll (deg)');
  ylabel('Surface relative power (dB)')
  grid on;
  p_roll_surf_corr(end) = 0;
  fprintf('%.14g ',p_roll_surf_corr); fprintf('\n');
end
p_roll_surf_corr(end) = 0;
if any(~isfinite(p_roll_surf_corr))
  p_roll_surf_corr = mean(surf_value_corr(mask));
end

%% Estimate surface multiple roll correction
mask = isfinite(mult_value_corr);
p_roll_corr=polyfit(mdata.Roll(mask)*180/pi, mult_value_corr(mask),15);
if 0
  figure(3); clf;
  plot(mdata.Roll*180/pi, mult_value_corr,'.')
  hold on
  plot(mdata.Roll*180/pi, polyval(p_roll_corr,mdata.Roll*180/pi),'r.');
  xlabel('Roll (deg)');
  ylabel('Surface multiple relative power (dB)')
  grid on;
  p_roll_corr(end) = 0;
  fprintf('%.14g ',p_roll_corr); fprintf('\n');
end
p_roll_corr(end) = 0;
if any(~isfinite(p_roll_corr))
  p_roll_corr = mean(mult_value_corr(mask));
end

% p_roll_surf_corr = [2.2255958717854e-15 -1.3572630870759e-13 2.3527709210261e-12 2.124281696932e-11 -1.1228041256249e-09 6.0543207183435e-09 1.6645234883187e-07 -1.6766045475499e-06 -1.0712601140495e-05 0.0001376158654882 0.0003367560066867 -0.0042097661445678 -0.0054248806810891 -0.018969197708196 -0.23904092116243 0];
roll_surf_loss_dB = polyval(p_roll_surf_corr, mdata.Roll*180/pi);
% roll_surf_loss_dB(mdata.Roll*180/pi < -11.673888571906199) = polyval(p_roll_surf_corr, -11.673888571906199);
% roll_surf_loss_dB(mdata.Roll*180/pi > 18.274466278841704) = polyval(p_roll_surf_corr, 18.274466278841704);

% p_roll_corr = [3.2936805253613e-14 -8.0792025960357e-13 -3.1275394496497e-11 9.2958491383191e-10 6.9811704932971e-09 -3.2389776773949e-07 -2.2783931893159e-07 5.1833633310267e-05 -8.3842235360433e-05 -0.0041934948578307 0.0093679210573843 0.16172483912271 -0.30900350768736 -2.1963125631644 1.9972031515517 0];
roll_loss_dB = polyval(p_roll_corr, mdata.Roll*180/pi);
% roll_loss_dB(mdata.Roll*180/pi < -11.673888571906199) = polyval(p_roll_corr, -11.673888571906199);
% roll_loss_dB(mdata.Roll*180/pi > 18.274466278841704) = polyval(p_roll_corr, 18.274466278841704);

surf_value_corr = surf_value + surf_spherical_spreading_loss_dB ...
  - roll_surf_loss_dB;
mult_value_corr = mult_value + 2*surf_spherical_spreading_loss_dB ...
  - roll_loss_dB;

%% Estimate surface multiple power from surface power
system_dB = -51.89;
system_dB = -70.36;
surf_value_corr_filt = max_filt1(surf_value_corr,max_filt_len);
est_value = system_dB + 2*(surf_value_corr_filt - system_dB) - 2*surf_spherical_spreading_loss_dB - multiple_loss_dB + roll_loss_dB;

if 0
  % Search for the system_dB value
  figure(2); clf;
  system_dB_list = -80:0.01:-45;
  est_error = zeros(size(system_dB_list));
  for idx = 1:length(system_dB_list)
    system_dB = system_dB_list(idx);
    est_mult_value = system_dB + 2*(surf_value_corr - system_dB) - 2*surf_spherical_spreading_loss_dB - multiple_loss_dB + roll_loss_dB;
    est_error(idx) = mean(abs(mult_value - est_mult_value));
  end
  plot(system_dB_list, est_error);
  return;
end

if 0
  % Compare corrections and estimated values
  figure(2); clf;
  plot(surf_value)
  hold on
  plot(surf_value_corr)
  plot(mult_value,'.');
  plot(mult_value_corr);
  plot(est_value,'o');
  return
end

%% Adjust surface multiple in image
for rline = 1:Nx
  % Select the surface bins
  sbins = surf_bins(rline)+bins;
  % Select which bins to modify
  mbins = mult_bins(rline)+bins;
  % Remove invalid bins
  mask = find(~(~isfinite(sbins) | sbins<1 | sbins>Nt | ~isfinite(mbins) | mbins<1 | mbins>Nt));
  % Estimate the value for these bins
  est_value = system_dB + 2*(10*log10(data(sbins(mask),rline))-roll_surf_loss_dB(rline) - system_dB) - 2*surf_spherical_spreading_loss_dB(rline) - multiple_loss_dB + roll_loss_dB(rline) + guard_dB + surf_value_corr_filt(rline) - surf_value_corr(rline);
  
  roll_spread = round(abs(mdata.Roll(rline)*180/pi))*2;
  if roll_spread>0
    if 0
      Hwind = hanning(roll_spread)/(roll_spread/2+0.5)
    else
      Hwind = exp(-(1:roll_spread)/roll_spread*8);
      Hwind = Hwind / sum(Hwind);
    end
    est_value_filter_tmp = fliplr(filter(Hwind,1,fliplr([zeros(1,roll_spread) est_value_filter zeros(1,roll_spread)])));
  else
    est_value_filter_tmp = est_value_filter;
  end
  %est_value_filter_tmp = [ones(1,roll_spread) est_value_filter zeros(1,roll_spread)];
  if ~isequal(est_value_filter_tmp,1)
    est_value = 10*log10(fir_dec(10.^(est_value(:).'/10),est_value_filter_tmp,1).');
  end
  
  noise_fill = linspace(neighbor_power_mult(1,rline),neighbor_power_mult(2,rline), length(mbins)).';
  noise = min(neighbor_power_mult(:,rline)) * ones(size(mbins)).';
  
  orig_val = data(:,rline);
  if 1
    new_val = data(mbins(mask),rline);
    new_val(new_val<10.^(est_value/10)) = NaN;
    data(mbins(mask),rline) = new_val;
    data(:,rline) = 10.^(interp_finite(10*log10(data(:,rline)))/10);
  elseif 0
    new_val = data(mbins(mask),rline) - 10.^(est_value/10);
    noise_mask = new_val<noise(mask)*noise_threshold;
    new_val(noise_mask) = noise_fill(mask(noise_mask)); % If less than background noise, set to noise
    data(mbins(mask),rline) = new_val;
  else
    new_val = data(mbins(mask),rline) - 10.^(est_value/10);
    noise_mask = new_val<noise(mask)*noise_threshold;
    new_val(noise_mask) = NaN;
    data(mbins(mask),rline) = new_val;
    data(:,rline) = interp_finite(data(:,rline));
  end
  
  if 0 && rline>=2324
    figure(1); clf;
    plot(10*log10(orig_val));
    hold on;
    plot(10*log10(data(:,rline)),'r.');
    plot(sbins(mask), 10*log10(data(sbins(mask),rline)),'go');
    plot(surf_bins(rline), 10*log10(data(surf_bins(rline),rline)),'ko');
    plot(mbins(mask), est_value,'go');
    hold off;
%     xlim([350 470])
    keyboard
  end
end
