function [max_power,aggregate_power,aggregate_bins,neighbor_power,waveforms] = echo_stats_layer(mdata,layer,param)
% [max_power,aggregate_power,aggregate_bins,neighbor_power,waveforms] = echo_stats_layer(mdata,layer,param)
%
% Returns statistics for layer in echogram.
%
% INPUTS:
%
% data: Assumed to be log power image of size Nt by Nx
%
% layer: 1 by Nx vector of a layer. If all values are less than 1, then
% layer is assumed to be two way travel time with units of seconds. If not,
% layer is assumed to be in range bins (rows) so that layer(col) indicates
% the location of the layer for column col in the echogram.
%
% param: structure defining how the layer statistics are estimated
%  .inc_dec: scalar indicating the length of boxcar filter and decimation
%  rate of incoherent "data" before statistics are extracted (echogram
%  columns are circularly shifted to flatten the layer before averaging)
%
%  .neighbor_window: scalar numeric indicating the size of the neighborhood
%  power estimate (this window is relative to the start and end of the
%  "window" that is used to get the layer power).
%
%  .window: 2 x 1 vector of window relative to layer to obtain
%  statistics. Default is [-1; 1] (i.e. a length three window which starts
%  one bin before the layer and ends one bin after the layer). If the
%  window_units are seconds, then the default is [-dt dt] where dt is the
%  fast-time-sample spacing of the echogram. Generally this should be a
%  negative integer (starting before the layer) followed by a positive
%  integer (ending after the layer).
%
%  .window_mode: string with either 'f' (fixed) or 'a' (adaptive) in it.
%  Adaptive mode should have significant multilooking (e.g. inc_dec >> 1)
%  to work properly. Default is fixed.
%
%  .window_threshold: numeric scalar indicating the adaptive window
%  threshold relative to the neighbor_window power. The default is 2 (3 dB
%  above the neighborhood power). For example, if the neighborhood power is
%  -100 dB and window_threshold is set to 2 (3 dB), then the adaptive
%  window will end when the power drops below -97 dB. If the power never
%  drops below the threshold, then all bins are used. The adaptive window
%  grows outward from the layer, so the start bin is when the threshold is
%  passed towards negative time starting at the layer and the stop bin is
%  when the threshold is passed towards positive time again starting at the
%  layer.
%
%  .window_units: string with either 'b' (bins) or 's' (seconds) in it.
%  Default is 'b' or bins.
%
% OUTPUTS:
% 
% Nx is the new dimension of data after inc_dec operation.
%
% max_power: 1 by Nx vector of the maximum power in the window for each
% column
%
% aggregate_power: 1 by Nx vector of the sum of the power in the window. If
% fixed window_mode, then every bin in the window is used. If adaptive
% window_mode is used, then the bin
%
% aggregate_bins: 1 by Nx vector of the number of bins included in the
% aggregate_power sum. This only varies when window_mode is adaptive.
%
% neighbor_power: 2 by Nx vector of the power in the neighborhood around
% the window. The first row gives the power estimate before the window. The
% second row gives the power estimate after the window. The size of the
% neighborhood power window is set by neighbor_window and includes the bins
% preceding and succeeding the window.
%
% waveforms: Nt_window by Nx array of the extracted waveform from each
% column of the data
%
% EXAMPLE:
%
% % Example getting surface and surface multiple statistics
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_standard/20140512_01/Data_20140512_01_018.mat';
% mdata = load(fn);
% layer = layerdata.load_layers(mdata,'','surface');
% 
% param.window = [-3 11];
% param.window_units = 'b'; % bins
% param.window_mode = 'f'; % fixed
% param.inc_dec = 1;
% [max_power,~,~,neighbor_power,~] = echo_stats_layer(mdata,layer,param);
% [max_power_mult,~,~,neighbor_power_mult,~] = echo_stats_layer(mdata,layer*2,param);
% figure;
% plot(lp(max_power),'b','LineWidth',2);
% hold on;
% plot(lp(max_power_mult),'r','LineWidth',2);
% plot(lp(neighbor_power.'),'b');
% plot(lp(neighbor_power_mult.'),'r');
%
% % Example bottom statistics
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_standard/20140512_01/Data_20140512_01_018.mat';
% mdata = load(fn);
% layer = layerdata.load_layers(mdata,'','bottom');
% 
% param.window = [-1.5e-6 4e-6];
% param.window_units = 's'; % seconds
% param.window_mode = 'a'; % adaptive
% param.inc_dec = 100;
% [max_power,aggregate_power,aggregate_bins,neighbor_power,waveforms] = echo_stats_layer(mdata,layer,param);
% figure;
% plot(lp(max_power));
% hold on;
% plot(lp(aggregate_power.'));
% plot(lp(neighbor_power.'));
% legend('max','aggregate','neighbor start','neighbor stop');
% figure;
% imagesc(lp(waveforms));
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

%% Input Check

if isstruct(mdata)
  data = mdata.Data;
else
  data = mdata;
end

if ~exist('layer','var') || isempty(layer)
  if isstruct(mdata)
    layers = layerdata(echo_param(mdata));
    layer = layers.get_layer_by_gps_time(mdata.GPS_time,'surface');
  else
    error('Layer must be defined if mdata is not an echogram struct since this echogram struct is used to load the default surface layer.');
  end
end

if any(layer<1)
  % layer is two way travel time
  if isstruct(mdata)
    layer = interp1(mdata.Time,1:length(mdata.Time),layer);
  end
end

if ~exist('param','var') || isempty(param)
  param = [];
end

% inc_dec: filtering and decimation of incoherent "data" before statistics
% are extracted (echogram columns are circularly shifted to flatten the
% layer before averaging)
if ~isfield(param,'inc_dec') || isempty(param.inc_dec)
  param.inc_dec = 1;
end

% window_mode: string with either 'f' (fixed) or 'a' (adaptive) in it.
% Adaptive mode should have significant multilooking (e.g. inc_dec >> 1) to
% work properly.
if ~isfield(param,'window_mode') || isempty(param.window_mode)
  param.window_mode = 'f';
end

if ~isfield(param,'window_threshold') || isempty(param.window_threshold)
  param.window_threshold = 2; % 3 dB
end

% window_units: string with either 'b' (bins) or 's' (seconds) in it
if ~isfield(param,'window_units') || isempty(param.window_units)
  param.window_units = 'b';
end

% Convert param.window into bins
if param.window_units == 's'
  if isstruct(mdata)
    dt = mdata.Time(2) - mdata.Time(1);
    % window: two elements vector of window relative to layer to obtain
    % statistics
    if ~isfield(param,'window') || isempty(param.window)
      param.window = [-dt; dt];
    end
    bins = round(param.window / dt);
    bins = bins(1):bins(end);
    % neighbor_window: scalar numeric indicating the size of the
    % neighborhood power estimate (this window is relative to the start and
    % end of the "window" that is used to get the layer power).
    if ~isfield(param,'neighbor_window') || isempty(param.neighbor_window)
      param.neighbor_window = dt;
    end
    neighbor_bins = 1 : param.neighbor_window / dt;
  else
    error('If param.window_units is "s", mdata must be an echogram struct since this echogram struct is used to determine the window.');
  end
else
  if ~isfield(param,'window') || isempty(param.window)
    param.window = [-1; 1];
  end
  bins = param.window(1):param.window(end);
  if ~isfield(param,'neighbor_window') || isempty(param.neighbor_window)
    param.neighbor_window = 1;
  end
  neighbor_bins = 1 : param.neighbor_window;
end

% Round layer
layer = round(interp_finite(layer));

Nbins = length(bins);

%% Setup
Nt = size(data,1);
Nx = size(data,2);

%% Flatten the layer
mid_point = round(Nt/2);
max_shift = max(abs(mid_point-layer));
data = [data; nan(max_shift,Nx)];
for rline = 1:Nx
  data(:,rline) = circshift(data(:,rline), mid_point-layer(rline));
end

%% Apply along-track filtering
data = fir_dec(data, param.inc_dec);
Nx = size(data,2);

%% Estimate statistics
max_power = max(data(mid_point+bins,:),[],1);
neighbor_power(1,:) = mean(data(mid_point+bins(1)-neighbor_bins,:),1);
neighbor_power(2,:) = mean(data(mid_point+bins(end)+neighbor_bins,:),1);
waveforms = data(mid_point+bins,:);

if param.window_mode == 'f'
  aggregate_power = sum(data(mid_point+bins,:),1);
  aggregate_bins = (bins(end)-bins(1))*ones(1,Nx);
else
  aggregate_power = nan(1,Nx);
  aggregate_bins = zeros(1,Nx);
  for rline = 1:Nx
    % Get the bins for this range line
    start_bin = find(data(mid_point+ (-1:-1:bins(1)),rline) < param.window_threshold*neighbor_power(1,rline),1);
    if isempty(start_bin)
      start_bin = bins(1);
    end
    stop_bin = find(data(mid_point+ (1:bins(end)),rline) < param.window_threshold*neighbor_power(2,rline),1);
    if isempty(stop_bin)
      stop_bin = bins(end);
    end
    if 0
      %% Debug plot
      figure(1); clf;
      plot(lp(data(:,rline)));
      hold on;
      plot(mid_point-start_bin, lp(data(mid_point-start_bin,rline)),'x');
      plot(mid_point+stop_bin, lp(data(mid_point+stop_bin,rline)),'x');
      plot(mid_point + bins(1) - 1, lp(neighbor_power(1,rline)),'o');
      plot(mid_point + bins(end) - 1, lp(neighbor_power(2,rline)),'o');
      grid on;
    end
    aggregate_bins(rline) = stop_bin-start_bin;
    aggregate_power(rline) = sum(data(mid_point+(-start_bin:stop_bin),rline));
  end
end
