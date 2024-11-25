function [hdr,data] = load_data(param, param_override)
% [hdr,data] = load_data(param, param_override)
%
% Function for loading data using records structure.
% The following options are available:
%   raw, pulse compressed, fast time decimated, burst EMI removal,
%   rxs, wfs, receiver combine, presumming
%
% param = struct controlling the loading and processing
%
% .load_data = structure controlling load_data processing
%  .radar_name = name of radar string
%  .season_name = name of season string
%  .day_seg = day-segment string
%  .recs = records to load (one indexed)
%  .imgs = cell vector of images to load, each image is Nx2 array of
%     wf/adc pairs
%     NOTE: wfs/adc pairs are not indices into anything, they are the absolute
%     waveform/adc numbers. The records file will be loaded to decode
%     which index each wf/adc belongs to.
%  .debug_level = debug level (scalar integer)
%  
%  load_data fields used by load_mcords_data.m (see that function for details)
%  .pulse_comp
%  .ft_dec
%  .ft_wind
%  .ft_wind_time
%  .presums
%  .combine_rx
%  .trim_vals
%  .pulse_rfi.en
%  .pulse_rfi.inc_ave
%  .pulse_rfi.thresh_scale
%  .radar
%   .Vpp_scale = radar Vpp for full scale quanitization
%   .rxs = struct array of receiver equalization coefficients
%    .wfs = struct array for each waveform
%     .chan_equal = scalar complex double (data DIVIDED by this)
%     .td = time delay correction (applied during pulse compression)
%  
% Example: run_load_data.m
%
% Author: John Paden
%
% See also run_load_data.m, load_mcords_data.m, pulse_compress.m

%% General Setup
% =====================================================================
if nargin == 1; param_override = []; end;
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input Checks
% =====================================================================

if ~isfield(param.load_data,'bit_mask') || isempty(param.load_data.bit_mask)
  % Remove bad records (bit_mask==1), leave stationary records
  % (bit_mask==2), and remove bad records (bit_mask==4)
  param.load_data.bit_mask = 1 + 4;
end

if ~isfield(param.load_data,'combine_rx') || isempty(param.load_data.combine_rx)
  param.load_data.combine_rx = false;
end

if ~isfield(param.load_data,'imgs') || isempty(param.load_data.imgs)
  param.load_data.imgs = {[1 1]};
end

if ~isfield(param.load_data,'motion_comp') || isempty(param.load_data.motion_comp)
  param.load_data.motion_comp = false;
end

if ~isfield(param.load_data,'presums') || isempty(param.load_data.presums)
  param.load_data.presums = 1;
end

if ~isfield(param.load_data,'pulse_comp') || isempty(param.load_data.pulse_comp)
  param.load_data.pulse_comp = 1;
end

if ~isfield(param.load_data,'raw_data') || isempty(param.load_data.raw_data)
  param.load_data.raw_data = 0;
elseif param.load_data.raw_data && param.load_data.pulse_comp
  error('Pulse compression (param.load_data.pulse_comp) cannot be enabled with raw data loading (param.load_data.raw_data).');
end
if param.load_data.raw_data
  param.load_data.pulse_comp = 0;
end

if ~isfield(param.load_data,'resample') || isempty(param.load_data.resample)
  param.load_data.resample = [1 1; 1 1];
end
if numel(param.load_data.resample) == 2
  param.load_data.resample = [param.load_data.resample(1) param.load_data.resample(2); 1 1];
end

if ~isfield(param.load_data,'surf_layer') || isempty(param.load_data.surf_layer)
  param.load_data.surf_layer.name = 'surface';
  param.load_data.surf_layer.source = 'layerdata';
end
% Never check for the existence of files
param.load_data.surf_layer.existence_check = false;

if ~isfield(param.load_data,'trim') || isempty(param.load_data.trim)
  param.load_data.trim = [0 0];
end

%% Setup processing
% =========================================================================

physical_constants;

param.load.recs(1) = param.load_data.recs(1);
param.load.recs(2) = param.load_data.recs(end);
param.load.imgs = param.load_data.imgs;
param.load.bit_mask = param.load_data.bit_mask;

%% Load records file
% =====================================================================
records = records_load(param,param.load.recs);
if param.load.recs(2) == inf
  param.load.recs(2) = param.load.recs(1) + length(records.gps_time)-1;
end
old_param_records = records.param_records;

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

%% Load surface layer
% =========================================================================
frames = frames_load(param);

tmp_param = param;
% Determine which frames have the records that are needed
frms = find(param.load.recs(1) >= frames.frame_idxs,1,'last') : find(param.load.recs(2) >= frames.frame_idxs,1,'last');
tmp_param.cmd.frms = max(1,min(frms)-1) : min(length(frames.frame_idxs),max(frms)+1);
surf_layer = opsLoadLayers(tmp_param,param.load_data.surf_layer);
if isempty(surf_layer.gps_time) || all(isnan(surf_layer.gps_time))
  records.surface = zeros(size(records.gps_time));
elseif length(surf_layer.gps_time) == 1;
  records.surface = surf_layer.twtt*ones(size(records.gps_time));
else
  records.surface = interp_finite(interp1(surf_layer.gps_time,surf_layer.twtt,records.gps_time),0);
end

%% Collect waveform information into one structure
% =====================================================================
[wfs,states] = data_load_wfs(param,records);
param.radar.wfs = merge_structs(param.radar.wfs,wfs);

%% Load data
% =====================================================================
param.load.raw_data = param.load_data.raw_data;
param.load.presums = param.load_data.presums;
[hdr,data] = data_load(param,records,states);

param.load.pulse_comp = param.load_data.pulse_comp;
[hdr,data,param] = data_pulse_compress(param,hdr,data);

param.load.motion_comp = param.load_data.motion_comp;
param.load.combine_rx = param.load_data.combine_rx;
[hdr,data] = data_merge_combine(param,hdr,data);

%% Resample
% ===================================================================
[hdr,data] = data_resample(hdr,data,param.load_data.resample);

%% Trim
% ===================================================================
[hdr,data] = data_trim(hdr,data,param.load_data.trim);

%% Complete hdr (header)
% =====================================================================
hdr.param_load_data = param;

fprintf('%s done %s\n', mfilename, datestr(now));
